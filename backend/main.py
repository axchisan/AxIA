from fastapi import FastAPI, Depends, HTTPException, WebSocket, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import jwt
import os
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import asyncio
import uuid
from pydantic import BaseModel
import aiohttp
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from database import Base, get_db, init_db, engine
from models import User, UserCreate, UserResponse, UserLogin
from security import hash_password, verify_password

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment variables
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    raise RuntimeError("SECRET_KEY environment variable is required")

N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL")
if not N8N_WEBHOOK_URL:
    raise RuntimeError("N8N_WEBHOOK_URL environment variable is required")

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is required")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 43200  # 30 days

app = FastAPI(
    title="AxIA API",
    description="Backend para la app AxIA - Asistente Unificado",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for sessions and messages
sessions_db: Dict = {}
messages_db: Dict[str, List] = {}
active_connections: Dict[str, List] = {}

@app.on_event("startup")
async def startup():
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)  # ← Esto crea las tablas si no existen
        logger.info("Database tables ensured (created if not exist)")
    except Exception as e:
        logger.error(f"Database connection failed: {str(e)}")
        raise

# Models
class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int

class MessageRequest(BaseModel):
    text: Optional[str] = None
    audio_base64: Optional[str] = None
    type: str = "text"  # text, audio, command

class MessageResponse(BaseModel):
    session_id: str
    output: str
    type: str
    timestamp: str

class CalendarEvent(BaseModel):
    id: str
    title: str
    start_time: str
    end_time: str
    description: Optional[str] = None

class Task(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    completed: bool = False
    due_date: Optional[str] = None

# JWT Utility functions
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str) -> str:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid token: missing subject")
        return username
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# Security scheme
bearer_scheme = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)
) -> str:
    return verify_token(credentials.credentials)

# Routes
@app.post("/token", response_model=TokenResponse)
async def login(credentials: UserLogin, db: AsyncSession = Depends(get_db)):
    """
    Authenticate user against PostgreSQL database and return JWT token.
    """
    # Query user from database
    result = await db.execute(
        select(User).where(User.username == credentials.username)
    )
    user = result.scalar_one_or_none()
    
    # Validate user exists and password is correct
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    if not user.is_active:
        raise HTTPException(status_code=403, detail="User account is disabled")
    
    # Create JWT token
    access_token = create_access_token(data={"sub": user.username})
    expires_delta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": int(expires_delta.total_seconds())
    }

@app.post("/register", response_model=UserResponse)
async def register(user_data: UserCreate, db: AsyncSession = Depends(get_db)):
    """
    Register a new user in the system.
    """
    # Check if user already exists
    result = await db.execute(
        select(User).where(
            (User.username == user_data.username) | (User.email == user_data.email)
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Username or email already registered")
    
    # Create new user
    hashed_pwd = hash_password(user_data.password)
    new_user = User(
        username=user_data.username,
        email=user_data.email,
        full_name=user_data.full_name,
        hashed_password=hashed_pwd
    )
    
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    return new_user

@app.post("/send-message")
async def send_message(
    request: MessageRequest,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Send message to AxIA (text or audio)."""
    session_id = str(uuid.uuid4())
    
    payload = {
        "session_id": session_id,
        "user": current_user,
        "timestamp": datetime.utcnow().isoformat(),
        "type": request.type,
        "text": request.text,
        "audio_base64": request.audio_base64
    }
    
    if current_user not in messages_db:
        messages_db[current_user] = []
    
    messages_db[current_user].append({
        "session_id": session_id,
        "role": "user",
        "content": request.text or "[Audio]",
        "type": request.type,
        "timestamp": datetime.utcnow().isoformat()
    })
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(N8N_WEBHOOK_URL, json=payload) as response:
                result = await response.json()
                
                messages_db[current_user].append({
                    "session_id": session_id,
                    "role": "assistant",
                    "content": result.get("output", ""),
                    "type": result.get("type", "text"),
                    "timestamp": datetime.utcnow().isoformat()
                })
                
                return {
                    "session_id": session_id,
                    "output": result.get("output", ""),
                    "type": result.get("type", "text"),
                    "timestamp": datetime.utcnow().isoformat()
                }
    except Exception as e:
        logger.error(f"Error calling n8n: {str(e)}")
        raise HTTPException(status_code=500, detail="Error processing message")

@app.websocket("/ws/{username}")
async def websocket_endpoint(websocket: WebSocket, username: str, token: str = None):
    """WebSocket for real-time chat."""
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    
    try:
        verify_token(token)
    except HTTPException:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    
    await websocket.accept()
    
    if username not in active_connections:
        active_connections[username] = []
    active_connections[username].append(websocket)
    
    try:
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)
            session_id = str(uuid.uuid4())
            
            payload = {
                "session_id": session_id,
                "user": username,
                "timestamp": datetime.utcnow().isoformat(),
                **message_data
            }
            
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.post(N8N_WEBHOOK_URL, json=payload) as resp:
                        if resp.status == 200:
                            result = await resp.json()
                            response_msg = {
                                "session_id": session_id,
                                "output": result.get("output", ""),
                                "type": result.get("type", "text"),
                                "timestamp": datetime.utcnow().isoformat()
                            }
                            await websocket.send_json(response_msg)
                        else:
                            await websocket.send_json({"error": "n8n error", "session_id": session_id})
            except Exception as e:
                logger.error(f"WebSocket error: {e}")
                await websocket.send_json({"error": "Processing failed", "session_id": session_id})
                
    except Exception as e:
        logger.info(f"WebSocket disconnected: {e}")
    finally:
        if websocket in active_connections.get(username, []):
            active_connections[username].remove(websocket)

@app.get("/calendar/events")
async def get_calendar_events(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> List[CalendarEvent]:
    """Get user's calendar events."""
    return [
        CalendarEvent(
            id="1",
            title="Reunión con cliente",
            start_time=(datetime.utcnow() + timedelta(days=1)).isoformat(),
            end_time=(datetime.utcnow() + timedelta(days=1, hours=1)).isoformat(),
            description="Discutir propuesta"
        ),
    ]

@app.get("/tasks")
async def get_tasks(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> List[Task]:
    """Get user's tasks."""
    return [
        Task(id="1", title="Completar documentación", completed=False),
        Task(id="2", title="Revisar código", completed=True),
    ]

@app.post("/tasks")
async def create_task(
    task: Task,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Task:
    """Create a new task."""
    task.id = str(uuid.uuid4())
    return task

@app.get("/messages/{session_id}")
async def get_message_history(
    session_id: str,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get message history."""
    return messages_db.get(current_user, [])

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok", "timestamp": datetime.utcnow().isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8077)

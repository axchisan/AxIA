from fastapi import FastAPI, Depends, HTTPException, WebSocket, status
from fastapi.security import HTTPBearer, HTTPAuthCredentials
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

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment variables
SECRET_KEY = os.getenv("SECRET_KEY")
N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 43200  # 30 days

app = FastAPI(
    title="AxIA API",
    description="Backend para la app AxIA - Asistente IA personal",
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

# In-memory storage (replace with PostgreSQL for production)
users_db: Dict = {}
sessions_db: Dict = {}
messages_db: Dict[str, List] = {}
active_connections: Dict[str, List] = {}

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

# Utility functions
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return username
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

async def get_current_user(credentials: HTTPAuthCredentials = Depends(HTTPBearer())) -> str:
    return verify_token(credentials.credentials)

# Routes
@app.post("/token", response_model=TokenResponse)
async def login(username: str, password: str):
    """
    Authenticate user and return JWT token.
    STEP 1: Autenticación
    """
    # Simulate user validation (replace with real database)
    if username == "duvan" and password == "password123":
        access_token = create_access_token(data={"sub": username})
        expires_delta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
        users_db[username] = {
            "username": username,
            "created_at": datetime.utcnow().isoformat()
        }
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "expires_in": int(expires_delta.total_seconds())
        }
    
    raise HTTPException(status_code=401, detail="Invalid credentials")

@app.post("/send-message")
async def send_message(request: MessageRequest, current_user: str = Depends(get_current_user)):
    """
    Send message to AxIA (text or audio).
    STEP 2 & 3: Envío de mensajes
    """
    session_id = str(uuid.uuid4())
    
    # Prepare message for n8n
    payload = {
        "session_id": session_id,
        "user": current_user,
        "timestamp": datetime.utcnow().isoformat(),
        "type": request.type,
        "text": request.text,
        "audio_base64": request.audio_base64
    }
    
    # Store message in local DB
    if current_user not in messages_db:
        messages_db[current_user] = []
    
    messages_db[current_user].append({
        "session_id": session_id,
        "role": "user",
        "content": request.text or "[Audio]",
        "type": request.type,
        "timestamp": datetime.utcnow().isoformat()
    })
    
    # Forward to n8n webhook
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(N8N_WEBHOOK_URL, json=payload) as response:
                result = await response.json()
                
                # Store assistant response
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
async def websocket_endpoint(websocket: WebSocket, username: str, token: str):
    """
    WebSocket for real-time chat.
    STEP 2: Conexión WebSocket
    """
    # Verify token
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
            
            # Forward to n8n
            payload = {
                "session_id": session_id,
                "user": username,
                "timestamp": datetime.utcnow().isoformat(),
                **message_data
            }
            
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.post(N8N_WEBHOOK_URL, json=payload) as response:
                        if response.status == 200:
                            result = await response.json()
                            
                            # Send response back through WebSocket
                            response_msg = {
                                "session_id": session_id,
                                "output": result.get("output", ""),
                                "type": result.get("type", "text"),
                                "timestamp": datetime.utcnow().isoformat()
                            }
                            
                            await websocket.send_json(response_msg)
            except Exception as e:
                logger.error(f"Error in WebSocket: {str(e)}")
                await websocket.send_json({
                    "error": "Error processing message",
                    "session_id": session_id
                })
    
    except Exception as e:
        logger.info(f"WebSocket closed: {str(e)}")
    finally:
        active_connections[username].remove(websocket)

@app.get("/calendar/events")
async def get_calendar_events(current_user: str = Depends(get_current_user)) -> List[CalendarEvent]:
    """
    Get user's calendar events from Google Calendar via n8n.
    STEP 5: Integración con APIs
    """
    # Mock data - replace with n8n integration
    return [
        CalendarEvent(
            id="1",
            title="Reunión con cliente",
            start_time=(datetime.utcnow() + timedelta(days=1)).isoformat(),
            end_time=(datetime.utcnow() + timedelta(days=1, hours=1)).isoformat(),
            description="Discutir propuesta"
        ),
        CalendarEvent(
            id="2",
            title="Revisión de proyecto",
            start_time=(datetime.utcnow() + timedelta(days=2)).isoformat(),
            end_time=(datetime.utcnow() + timedelta(days=2, hours=2)).isoformat(),
        )
    ]

@app.get("/tasks")
async def get_tasks(current_user: str = Depends(get_current_user)) -> List[Task]:
    """
    Get user's tasks.
    STEP 5: Integración con APIs
    """
    # Mock data
    return [
        Task(
            id="1",
            title="Completar documentación",
            description="Terminar docs del proyecto",
            completed=False,
            due_date=(datetime.utcnow() + timedelta(days=1)).isoformat()
        ),
        Task(
            id="2",
            title="Revisar código",
            description="PR review",
            completed=True,
            due_date=(datetime.utcnow()).isoformat()
        )
    ]

@app.post("/tasks")
async def create_task(task: Task, current_user: str = Depends(get_current_user)) -> Task:
    """Create a new task."""
    task.id = str(uuid.uuid4())
    return task

@app.get("/messages/{session_id}")
async def get_message_history(session_id: str, current_user: str = Depends(get_current_user)):
    """Get message history for a session."""
    if current_user in messages_db:
        return messages_db[current_user]
    return []

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok", "timestamp": datetime.utcnow().isoformat()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8077)

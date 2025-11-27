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
from models import User, UserCreate, UserResponse, UserLogin, Routine, Note, MyActivity, RoutineCreate, RoutineUpdate, RoutineResponse, NoteCreate, NoteUpdate, NoteResponse, PresenceUpdate, PresenceResponse
from google_services import google_calendar, google_tasks
from security import hash_password, verify_password

# Configure logging
logging.basicConfig(level=logging.WARNING)
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

# === NUEVAS VARIABLES CONFIGURABLES ===
WHATSAPP_REMOTE_JID = os.getenv("WHATSAPP_REMOTE_JID_TEMPLATE")  # Ej: 573183038190:24@s.whatsapp.net
if not WHATSAPP_REMOTE_JID:
    raise RuntimeError("WHATSAPP_REMOTE_JID_TEMPLATE environment variable is required")

WHATSAPP_SENDER_JID = os.getenv("WHATSAPP_SENDER_JID")  # Ej: 573173012598@s.whatsapp.net
if not WHATSAPP_SENDER_JID:
    raise RuntimeError("WHATSAPP_SENDER_JID environment variable is required")

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
            await conn.run_sync(Base.metadata.create_all)
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
    type: str = "text"

class MessageResponse(BaseModel):
    session_id: str
    output: str
    type: str
    timestamp: str
    debe_ser_audio: Optional[bool] = False
    audio_url: Optional[str] = None

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

class CalendarEventCreate(BaseModel):
    summary: str
    start_time: str
    end_time: str
    description: Optional[str] = None
    location: Optional[str] = None

class GoogleTaskCreate(BaseModel):
    title: str
    notes: Optional[str] = None
    due: Optional[str] = None

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
    result = await db.execute(
        select(User).where(User.username == credentials.username)
    )
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    if not user.is_active:
        raise HTTPException(status_code=403, detail="User account is disabled")
    
    access_token = create_access_token(data={"sub": user.username})
    expires_delta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": int(expires_delta.total_seconds())
    }

@app.post("/register", response_model=UserResponse)
async def register(user_data: UserCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(
            (User.username == user_data.username) | (User.email == user_data.email)
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Username or email already registered")
    
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
    session_id = str(uuid.uuid4())
    
    payload = {
        "event": "messages.upsert",
        "instance": "AxIAPersonal",
        "channel": "app",
        "data": {
            "key": {
                "remoteJid": WHATSAPP_REMOTE_JID,  # Ahora configurable
                "fromMe": False,
                "id": session_id
            },
            "pushName": current_user,
            "message": {
                "conversation": request.text if request.type == "text" else None,
                "base64": request.audio_base64 if request.type == "audio" else None
            },
            "messageType": request.type if request.type == "audio" else "conversation",
            "messageTimestamp": int(datetime.utcnow().timestamp())
        },
        "destination": N8N_WEBHOOK_URL,
        "date_time": datetime.utcnow().isoformat(),
        "sender": WHATSAPP_SENDER_JID  # Ahora configurable
    }
    
    if payload["data"]["message"].get("conversation") is None:
        del payload["data"]["message"]["conversation"]
    if payload["data"]["message"].get("base64") is None:
        del payload["data"]["message"]["base64"]
    
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
                if response.status == 200:
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
                        "debe_ser_audio": result.get("debe_ser_audio", False),
                        "audio_url": result.get("audio_url"),
                        "timestamp": datetime.utcnow().isoformat()
                    }
                else:
                    logger.error(f"n8n returned status: {response.status}")
                    raise HTTPException(status_code=500, detail="Error from n8n workflow")
    except Exception as e:
        logger.error(f"Error calling n8n: {str(e)}")
        raise HTTPException(status_code=500, detail="Error processing message")

@app.websocket("/ws/{username}")
async def websocket_endpoint(websocket: WebSocket, username: str, token: str = None):
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
            
            event = message_data.get('event', 'messages.upsert')
            data_payload = message_data.get('data', {})
            
            key_info = data_payload.get('key', {})
            session_id = key_info.get('id', str(uuid.uuid4()))
            message_content = data_payload.get('message', {})
            message_type = data_payload.get('messageType', 'conversation')
            
            if message_type == 'conversation':
                final_message = message_content.get('conversation', '')
                msg_type = 'text'
                audio_base64 = None
            elif message_type == 'audioMessage':
                final_message = '[Audio Message]'
                msg_type = 'audio'
                audio_base64 = message_content.get('base64', '')
            else:
                final_message = str(message_content)
                msg_type = 'text'
                audio_base64 = None
            
            n8n_payload = {
                "event": event,
                "instance": message_data.get('instance', 'AxIAPersonal'),
                "channel": "app",
                "data": {
                    "key": {
                        "remoteJid": WHATSAPP_REMOTE_JID,
                        "fromMe": False,
                        "id": session_id
                    },
                    "pushName": username,
                    "message": {
                        "conversation": final_message if msg_type == 'text' else None,
                        "base64": audio_base64 if msg_type == 'audio' else None
                    },
                    "messageType": message_type,
                    "messageTimestamp": int(datetime.utcnow().timestamp()),
                    "instanceId": message_data.get('instanceId', str(uuid.uuid4())),
                    "source": "flutter_app"
                },
                "destination": N8N_WEBHOOK_URL,
                "date_time": datetime.utcnow().isoformat(),
                "sender": WHATSAPP_SENDER_JID
            }
            
            if n8n_payload["data"]["message"].get("conversation") is None:
                del n8n_payload["data"]["message"]["conversation"]
            if n8n_payload["data"]["message"].get("base64") is None:
                del n8n_payload["data"]["message"]["base64"]
            
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.post(N8N_WEBHOOK_URL, json=n8n_payload) as resp:
                        if resp.status == 200:
                            try:
                                result = await resp.json()
                                
                                output_text = result.get('output', result.get('text', ''))
                                response_type = result.get('type', 'text')
                                debe_ser_audio = result.get('debe_ser_audio', False)
                                audio_url = result.get('audio_url', None)
                                
                                response_msg = {
                                    "session_id": session_id,
                                    "output": output_text,
                                    "type": 'audio' if debe_ser_audio else response_type,
                                    "debe_ser_audio": debe_ser_audio,
                                    "audio_url": audio_url,
                                    "timestamp": datetime.utcnow().isoformat()
                                }
                                
                                await websocket.send_json(response_msg)
                            except Exception:
                                text_resp = await resp.text()
                                await websocket.send_json({
                                    "session_id": session_id,
                                    "output": text_resp,
                                    "type": "text",
                                    "timestamp": datetime.utcnow().isoformat()
                                })
                        else:
                            await websocket.send_json({
                                "error": "n8n error", 
                                "session_id": session_id,
                                "status": resp.status
                            })
            except Exception as e:
                await websocket.send_json({
                    "error": "Processing failed", 
                    "session_id": session_id,
                    "details": str(e)
                })
                
    except Exception:
        pass
    finally:
        if websocket in active_connections.get(username, []):
            active_connections[username].remove(websocket)

@app.get("/calendar/events")
async def get_calendar_events(
    time_min: Optional[str] = None,
    time_max: Optional[str] = None,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get events from Google Calendar"""
    try:
        time_min_dt = datetime.fromisoformat(time_min) if time_min else None
        time_max_dt = datetime.fromisoformat(time_max) if time_max else None
        
        events = await google_calendar.get_events(time_min_dt, time_max_dt)
        return events
    except Exception as e:
        logger.error(f"Error fetching calendar events: {e}")
        raise HTTPException(status_code=500, detail="Error fetching calendar events")

@app.post("/calendar/events")
async def create_calendar_event(
    event: CalendarEventCreate,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new event in Google Calendar"""
    try:
        start_dt = datetime.fromisoformat(event.start_time.replace('Z', '+00:00'))
        end_dt = datetime.fromisoformat(event.end_time.replace('Z', '+00:00'))
        
        created_event = await google_calendar.create_event(
            summary=event.summary,
            start=start_dt,
            end=end_dt,
            description=event.description,
            location=event.location
        )
        
        if not created_event:
            raise HTTPException(status_code=500, detail="Failed to create event")
        
        return created_event
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid datetime format: {e}")
    except Exception as e:
        logger.error(f"Error creating calendar event: {e}")
        raise HTTPException(status_code=500, detail=f"Error creating event: {str(e)}")

@app.patch("/calendar/events/{event_id}")
async def update_calendar_event(
    event_id: str,
    updates: Dict,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update a calendar event"""
    try:
        event = await google_calendar.update_event(event_id, updates)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found or update failed")
        return event
    except Exception as e:
        logger.error(f"Error updating calendar event: {e}")
        raise HTTPException(status_code=500, detail="Error updating calendar event")

@app.delete("/calendar/events/{event_id}")
async def delete_calendar_event(
    event_id: str,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a calendar event"""
    try:
        success = await google_calendar.delete_event(event_id)
        if not success:
            raise HTTPException(status_code=404, detail="Event not found or delete failed")
        return {"status": "success", "message": "Event deleted"}
    except Exception as e:
        logger.error(f"Error deleting calendar event: {e}")
        raise HTTPException(status_code=500, detail="Error deleting calendar event")

@app.get("/google/tasks")
async def get_google_tasks(
    show_completed: bool = True,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get tasks from Google Tasks"""
    try:
        tasks = await google_tasks.get_tasks(show_completed)
        return tasks
    except Exception as e:
        logger.error(f"Error fetching Google tasks: {e}")
        raise HTTPException(status_code=500, detail="Error fetching tasks")

@app.post("/google/tasks")
async def create_google_task(
    task: GoogleTaskCreate,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new task in Google Tasks"""
    try:
        due_dt = None
        if task.due:
            due_dt = datetime.fromisoformat(task.due.replace('Z', '+00:00'))
        
        created_task = await google_tasks.create_task(
            title=task.title,
            notes=task.notes,
            due=due_dt
        )
        
        if not created_task:
            raise HTTPException(status_code=500, detail="Failed to create task")
        
        return created_task
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid datetime format: {e}")
    except Exception as e:
        logger.error(f"Error creating Google task: {e}")
        raise HTTPException(status_code=500, detail=f"Error creating task: {str(e)}")

@app.patch("/google/tasks/{task_id}")
async def update_google_task(
    task_id: str,
    updates: Dict,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update a Google task"""
    try:
        task = await google_tasks.update_task(task_id, updates)
        if not task:
            raise HTTPException(status_code=404, detail="Task not found or update failed")
        return task
    except Exception as e:
        logger.error(f"Error updating Google task: {e}")
        raise HTTPException(status_code=500, detail="Error updating task")

@app.post("/google/tasks/{task_id}/complete")
async def complete_google_task(
    task_id: str,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Mark a Google task as completed"""
    try:
        task = await google_tasks.complete_task(task_id)
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
        return task
    except Exception as e:
        logger.error(f"Error completing Google task: {e}")
        raise HTTPException(status_code=500, detail="Error completing task")

@app.delete("/google/tasks/{task_id}")
async def delete_google_task(
    task_id: str,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete a Google task"""
    try:
        success = await google_tasks.delete_task(task_id)
        if not success:
            raise HTTPException(status_code=404, detail="Task not found or delete failed")
        return {"status": "success", "message": "Task deleted"}
    except Exception as e:
        logger.error(f"Error deleting Google task: {e}")
        raise HTTPException(status_code=500, detail="Error deleting task")

@app.get("/routines", response_model=List[RoutineResponse])
async def get_routines(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    result = await db.execute(
        select(Routine).where(Routine.user_id == user.id)
    )
    routines = result.scalars().all()
    return routines

@app.post("/routines", response_model=RoutineResponse)
async def create_routine(
    routine_data: RoutineCreate,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    new_routine = Routine(
        user_id=user.id,
        name=routine_data.name,
        description=routine_data.description,
        icon=routine_data.icon,
        duration_minutes=routine_data.duration_minutes,
        category=routine_data.category,
        scheduled_days=routine_data.scheduled_days
    )
    
    db.add(new_routine)
    await db.commit()
    await db.refresh(new_routine)
    
    return new_routine

@app.patch("/routines/{routine_id}", response_model=RoutineResponse)
async def update_routine(
    routine_id: int,
    routine_data: RoutineUpdate,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    result = await db.execute(
        select(Routine).where(
            Routine.id == routine_id,
            Routine.user_id == user.id
        )
    )
    routine = result.scalar_one_or_none()
    if not routine:
        raise HTTPException(status_code=404, detail="Routine not found")
    
    for field, value in routine_data.dict(exclude_unset=True).items():
        setattr(routine, field, value)
    
    await db.commit()
    await db.refresh(routine)
    
    return routine

@app.delete("/routines/{routine_id}")
async def delete_routine(
    routine_id: int,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    result = await db.execute(
        select(Routine).where(
            Routine.id == routine_id,
            Routine.user_id == user.id
        )
    )
    routine = result.scalar_one_or_none()
    if not routine:
        raise HTTPException(status_code=404, detail="Routine not found")
    
    await db.delete(routine)
    await db.commit()
    
    return {"status": "deleted", "id": routine_id}

@app.get("/notes", response_model=List[NoteResponse])
async def get_notes(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    result = await db.execute(
        select(Note).where(Note.user_id == user.id).order_by(Note.updated_at.desc())
    )
    notes = result.scalars().all()
    return notes

@app.post("/notes", response_model=NoteResponse)
async def create_note(
    note_data: NoteCreate,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    new_note = Note(
        user_id=user.id,
        title=note_data.title,
        content=note_data.content,
        tags=note_data.tags,
        is_pinned=note_data.is_pinned,
        color=note_data.color
    )
    
    db.add(new_note)
    await db.commit()
    await db.refresh(new_note)
    
    return new_note

@app.patch("/notes/{note_id}", response_model=NoteResponse)
async def update_note(
    note_id: int,
    note_data: NoteUpdate,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    result = await db.execute(
        select(Note).where(
            Note.id == note_id,
            Note.user_id == user.id
        )
    )
    note = result.scalar_one_or_none()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    
    for field, value in note_data.dict(exclude_unset=True).items():
        setattr(note, field, value)
    
    note.updated_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(note)
    
    return note

@app.delete("/notes/{note_id}")
async def delete_note(
    note_id: int,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    result = await db.execute(
        select(Note).where(
            Note.id == note_id,
            Note.user_id == user.id
        )
    )
    note = result.scalar_one_or_none()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    
    await db.delete(note)
    await db.commit()
    
    return {"status": "deleted", "id": note_id}

@app.get("/presence", response_model=PresenceResponse)
async def get_presence(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get current presence/activity status"""
    try:
        result = await db.execute(
            select(MyActivity).order_by(MyActivity.id.desc()).limit(1)
        )
        activity = result.scalar_one_or_none()
        
        if not activity:
            # Create default activity
            activity = MyActivity(
                is_online=False,
                last_active=datetime.utcnow()
            )
            db.add(activity)
            await db.commit()
            await db.refresh(activity)
        
        # Calculate inactive minutes
        inactive_minutes = 0
        if activity.last_active:
            now = datetime.utcnow()
            delta = now - activity.last_active
            inactive_minutes = int(delta.total_seconds() / 60)
        
        return PresenceResponse(
            is_online=activity.is_online,
            last_active=activity.last_active,
            inactive_minutes=inactive_minutes
        )
    except Exception as e:
        logger.error(f"Error fetching presence: {e}")
        raise HTTPException(status_code=500, detail=f"Error fetching presence: {str(e)}")

@app.post("/presence/update")
async def update_presence(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update presence/activity status"""
    try:
        result = await db.execute(
            select(MyActivity).order_by(MyActivity.id.desc()).limit(1)
        )
        activity = result.scalar_one_or_none()
        
        if not activity:
            activity = MyActivity()
            db.add(activity)
        
        # Update only existing fields
        activity.last_active = datetime.utcnow()
        activity.is_online = True
        
        await db.commit()
        await db.refresh(activity)
        
        return {"status": "success", "message": "Presence updated"}
    except Exception as e:
        logger.error(f"Error updating presence: {e}")
        raise HTTPException(status_code=500, detail=f"Error updating presence: {str(e)}")

@app.post("/presence/heartbeat")
async def presence_heartbeat(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Send presence heartbeat to indicate online status"""
    try:
        result = await db.execute(
            select(MyActivity).order_by(MyActivity.id.desc()).limit(1)
        )
        activity = result.scalar_one_or_none()
        
        if not activity:
            activity = MyActivity(
                is_online=True,
                last_active=datetime.utcnow()
            )
            db.add(activity)
        else:
            activity.last_active = datetime.utcnow()
            activity.is_online = True
        
        await db.commit()
        
        return {"status": "success"}
    except Exception as e:
        logger.error(f"Error sending heartbeat: {e}")
        raise HTTPException(status_code=500, detail=f"Error sending heartbeat: {str(e)}")

@app.get("/health")
async def health_check():
    return {"status": "ok", "timestamp": datetime.utcnow().isoformat()}

@app.post("/app-message")
async def receive_app_message(request: Request):
    try:
        data = await request.json()
        
        username = data.get('username')
        if not username:
            raise HTTPException(status_code=400, detail="username is required")
        
        user_connections = active_connections.get(username, [])
        
        if not user_connections:
            return {"status": "no_active_connections", "username": username}
        
        response_msg = {
            "session_id": data.get('session_id', str(uuid.uuid4())),
            "output": data.get('output', ''),
            "type": data.get('type', 'text'),
            "debe_ser_audio": data.get('debe_ser_audio', False),
            "audio_url": data.get('audio_url'),
            "audio_base64": data.get('audio_base64'),
            "timestamp": datetime.utcnow().isoformat()
        }
        
        disconnected = []
        for ws in user_connections:
            try:
                await ws.send_json(response_msg)
            except Exception:
                disconnected.append(ws)
        
        for ws in disconnected:
            user_connections.remove(ws)
        
        return {
            "status": "success",
            "username": username,
            "connections_notified": len(user_connections)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8077)

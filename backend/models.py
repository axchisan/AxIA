from sqlalchemy import Column, String, DateTime, Boolean, Integer, Text, TIMESTAMP, ARRAY
from sqlalchemy.sql import func
from database import Base
from datetime import datetime
from pydantic import BaseModel, EmailStr
from typing import Optional, List

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    def __repr__(self):
        return f"<User(id={self.id}, username={self.username}, email={self.email})>"

class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    full_name: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    full_name: Optional[str]
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    username: str
    password: str

class Routine(Base):
    __tablename__ = "routines"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    icon = Column(String(50))
    duration_minutes = Column(Integer, default=60)
    category = Column(String(100))
    streak = Column(Integer, default=0)
    is_completed = Column(Boolean, default=False)
    scheduled_days = Column(ARRAY(Text))
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

class Note(Base):
    __tablename__ = "notes"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    tags = Column(ARRAY(Text), default=[])
    is_pinned = Column(Boolean, default=False)
    color = Column(String(50), default='default')
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

class MyActivity(Base):
    __tablename__ = "my_activity"
    
    id = Column(Integer, primary_key=True)
    last_active = Column(TIMESTAMP, default=func.now())
    is_online = Column(Boolean, default=False)
    status = Column(String(50), default='available')
    custom_message = Column(Text)
    inactive_minutes = Column(Integer, default=0)

class RoutineCreate(BaseModel):
    name: str
    description: Optional[str] = None
    icon: Optional[str] = None
    duration_minutes: int = 60
    category: Optional[str] = None
    scheduled_days: List[str] = []

class RoutineUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    is_completed: Optional[bool] = None
    streak: Optional[int] = None

class RoutineResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    icon: Optional[str]
    duration_minutes: int
    category: Optional[str]
    streak: int
    is_completed: bool
    scheduled_days: List[str]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class NoteCreate(BaseModel):
    title: str
    content: str
    tags: List[str] = []
    is_pinned: bool = False
    color: str = 'default'

class NoteUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None
    is_pinned: Optional[bool] = None
    color: Optional[str] = None

class NoteResponse(BaseModel):
    id: int
    title: str
    content: str
    tags: List[str]
    is_pinned: bool
    color: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class PresenceUpdate(BaseModel):
    status: str  # 'available', 'focus', 'away', 'busy'
    custom_message: Optional[str] = None

class PresenceResponse(BaseModel):
    is_online: bool
    status: str
    custom_message: Optional[str]
    last_active: datetime
    inactive_minutes: int
    
    class Config:
        from_attributes = True

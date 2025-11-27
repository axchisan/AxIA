import os
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from datetime import datetime, timedelta
from typing import List, Dict, Optional


class GoogleCalendarService:
    """Service to interact with Google Calendar API"""
    
    def __init__(self, credentials_json: Dict):
        self.creds = Credentials.from_authorized_user_info(credentials_json)
        self.service = build('calendar', 'v3', credentials=self.creds)
    
    async def get_events(self, time_min: Optional[datetime] = None, 
                        time_max: Optional[datetime] = None,
                        max_results: int = 100) -> List[Dict]:
        """Get calendar events within a time range"""
        try:
            if not time_min:
                time_min = datetime.utcnow()
            if not time_max:
                time_max = time_min + timedelta(days=7)
            
            events_result = self.service.events().list(
                calendarId='primary',
                timeMin=time_min.isoformat() + 'Z',
                timeMax=time_max.isoformat() + 'Z',
                maxResults=max_results,
                singleEvents=True,
                orderBy='startTime'
            ).execute()
            
            events = events_result.get('items', [])
            return events
        except HttpError as error:
            return []
    
    async def create_event(self, summary: str, start: datetime, 
                          end: datetime, description: str = None,
                          location: str = None) -> Optional[Dict]:
        """Create a new calendar event"""
        try:
            event = {
                'summary': summary,
                'start': {
                    'dateTime': start.isoformat(),
                    'timeZone': 'America/Bogota',
                },
                'end': {
                    'dateTime': end.isoformat(),
                    'timeZone': 'America/Bogota',
                },
            }
            
            if description:
                event['description'] = description
            if location:
                event['location'] = location
            
            event = self.service.events().insert(
                calendarId='primary',
                body=event
            ).execute()
            
            return event
        except HttpError as error:
            return None
    
    async def update_event(self, event_id: str, updates: Dict) -> Optional[Dict]:
        """Update an existing calendar event"""
        try:
            event = self.service.events().get(
                calendarId='primary',
                eventId=event_id
            ).execute()
            
            event.update(updates)
            
            updated_event = self.service.events().update(
                calendarId='primary',
                eventId=event_id,
                body=event
            ).execute()
            
            return updated_event
        except HttpError as error:
            return None
    
    async def delete_event(self, event_id: str) -> bool:
        """Delete a calendar event"""
        try:
            self.service.events().delete(
                calendarId='primary',
                eventId=event_id
            ).execute()
            return True
        except HttpError as error:
            return False


class GoogleTasksService:
    """Service to interact with Google Tasks API"""
    
    def __init__(self, credentials_json: Dict):
        self.creds = Credentials.from_authorized_user_info(credentials_json)
        self.service = build('tasks', 'v1', credentials=self.creds)
    
    async def get_task_lists(self) -> List[Dict]:
        """Get all task lists"""
        try:
            results = self.service.tasklists().list().execute()
            return results.get('items', [])
        except HttpError as error:
            return []
    
    async def get_tasks(self, tasklist_id: str = '@default') -> List[Dict]:
        """Get tasks from a specific task list"""
        try:
            results = self.service.tasks().list(
                tasklist=tasklist_id,
                showCompleted=True,
                showHidden=True
            ).execute()
            return results.get('items', [])
        except HttpError as error:
            return []
    
    async def create_task(self, title: str, notes: str = None,
                         due: datetime = None,
                         tasklist_id: str = '@default') -> Optional[Dict]:
        """Create a new task"""
        try:
            task = {'title': title}
            
            if notes:
                task['notes'] = notes
            if due:
                task['due'] = due.isoformat() + 'Z'
            
            result = self.service.tasks().insert(
                tasklist=tasklist_id,
                body=task
            ).execute()
            
            return result
        except HttpError as error:
            return None
    
    async def update_task(self, task_id: str, updates: Dict,
                         tasklist_id: str = '@default') -> Optional[Dict]:
        """Update an existing task"""
        try:
            task = self.service.tasks().get(
                tasklist=tasklist_id,
                task=task_id
            ).execute()
            
            task.update(updates)
            
            result = self.service.tasks().update(
                tasklist=tasklist_id,
                task=task_id,
                body=task
            ).execute()
            
            return result
        except HttpError as error:
            return None
    
    async def complete_task(self, task_id: str,
                          tasklist_id: str = '@default') -> Optional[Dict]:
        """Mark a task as completed"""
        return await self.update_task(
            task_id,
            {'status': 'completed'},
            tasklist_id
        )
    
    async def delete_task(self, task_id: str,
                         tasklist_id: str = '@default') -> bool:
        """Delete a task"""
        try:
            self.service.tasks().delete(
                tasklist=tasklist_id,
                task=task_id
            ).execute()
            return True
        except HttpError as error:
            return False

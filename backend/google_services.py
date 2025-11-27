import os
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

class GoogleServicesManager:
    """Unified manager for all Google services"""
    
    def __init__(self):
        self.credentials = self._get_credentials()
        self.calendar_service = None
        self.tasks_service = None
        self.gmail_service = None
        
        if self.credentials:
            self._initialize_services()
    
    def _get_credentials(self) -> Optional[Credentials]:
        """Get Google credentials from environment variables"""
        try:
            client_id = os.getenv('GOOGLE_CLIENT_ID')
            client_secret = os.getenv('GOOGLE_CLIENT_SECRET')
            refresh_token = os.getenv('GOOGLE_REFRESH_TOKEN')
            
            if not all([client_id, client_secret, refresh_token]):
                logger.warning("Google credentials not configured in environment")
                return None
            
            creds = Credentials(
                token=None,
                refresh_token=refresh_token,
                token_uri='https://oauth2.googleapis.com/token',
                client_id=client_id,
                client_secret=client_secret,
                scopes=[
                    'https://www.googleapis.com/auth/calendar',
                    'https://www.googleapis.com/auth/tasks',
                ]
            )
            
            # Refresh the token if needed
            if creds.expired or not creds.valid:
                creds.refresh(Request())
            
            return creds
        except Exception as e:
            logger.error(f"Error getting Google credentials: {e}")
            return None
    
    def _initialize_services(self):
        """Initialize Google API services"""
        try:
            self.calendar_service = build('calendar', 'v3', credentials=self.credentials)
            self.tasks_service = build('tasks', 'v1', credentials=self.credentials)
            # Gmail opcional
            # self.gmail_service = build('gmail', 'v1', credentials=self.credentials)
            logger.info("Google services initialized successfully")
        except Exception as e:
            logger.error(f"Error initializing Google services: {e}")


class GoogleCalendarService:
    """Service to interact with Google Calendar API"""
    
    def __init__(self, manager: GoogleServicesManager):
        self.service = manager.calendar_service
        self.calendar_id = os.getenv('GOOGLE_CALENDAR_ID', 'primary')
    
    async def get_events(
        self, 
        time_min: Optional[datetime] = None, 
        time_max: Optional[datetime] = None,
        max_results: int = 100
    ) -> List[Dict]:
        """Get calendar events within a time range"""
        if not self.service:
            return []
        
        try:
            if not time_min:
                time_min = datetime.utcnow()
            if not time_max:
                time_max = time_min + timedelta(days=30)
            
            events_result = self.service.events().list(
                calendarId=self.calendar_id,
                timeMin=time_min.isoformat() + 'Z',
                timeMax=time_max.isoformat() + 'Z',
                maxResults=max_results,
                singleEvents=True,
                orderBy='startTime'
            ).execute()
            
            events = events_result.get('items', [])
            
            # Transform to simpler format
            simplified_events = []
            for event in events:
                start = event['start'].get('dateTime', event['start'].get('date'))
                end = event['end'].get('dateTime', event['end'].get('date'))
                
                simplified_events.append({
                    'id': event['id'],
                    'title': event.get('summary', 'Sin título'),
                    'description': event.get('description', ''),
                    'start_time': start,
                    'end_time': end,
                    'location': event.get('location', ''),
                    'status': event.get('status', 'confirmed'),
                    'html_link': event.get('htmlLink', ''),
                })
            
            return simplified_events
        except HttpError as error:
            logger.error(f"Error fetching calendar events: {error}")
            return []
    
    async def create_event(
        self, 
        summary: str, 
        start: datetime, 
        end: datetime, 
        description: str = None,
        location: str = None,
        timezone: str = 'America/Bogota'
    ) -> Optional[Dict]:
        """Create a new calendar event"""
        if not self.service:
            return None
        
        try:
            event = {
                'summary': summary,
                'start': {
                    'dateTime': start.isoformat(),
                    'timeZone': timezone,
                },
                'end': {
                    'dateTime': end.isoformat(),
                    'timeZone': timezone,
                },
            }
            
            if description:
                event['description'] = description
            if location:
                event['location'] = location
            
            created_event = self.service.events().insert(
                calendarId=self.calendar_id,
                body=event
            ).execute()
            
            return {
                'id': created_event['id'],
                'title': created_event.get('summary', ''),
                'start_time': created_event['start'].get('dateTime'),
                'end_time': created_event['end'].get('dateTime'),
                'html_link': created_event.get('htmlLink', ''),
            }
        except HttpError as error:
            logger.error(f"Error creating calendar event: {error}")
            return None
    
    async def update_event(self, event_id: str, updates: Dict) -> Optional[Dict]:
        """Update an existing calendar event"""
        if not self.service:
            return None
        
        try:
            event = self.service.events().get(
                calendarId=self.calendar_id,
                eventId=event_id
            ).execute()
            
            # Apply updates
            if 'summary' in updates:
                event['summary'] = updates['summary']
            if 'description' in updates:
                event['description'] = updates['description']
            if 'start_time' in updates:
                event['start'] = {'dateTime': updates['start_time'], 'timeZone': 'America/Bogota'}
            if 'end_time' in updates:
                event['end'] = {'dateTime': updates['end_time'], 'timeZone': 'America/Bogota'}
            if 'location' in updates:
                event['location'] = updates['location']
            
            updated_event = self.service.events().update(
                calendarId=self.calendar_id,
                eventId=event_id,
                body=event
            ).execute()
            
            return {
                'id': updated_event['id'],
                'title': updated_event.get('summary', ''),
                'start_time': updated_event['start'].get('dateTime'),
                'end_time': updated_event['end'].get('dateTime'),
            }
        except HttpError as error:
            logger.error(f"Error updating calendar event: {error}")
            return None
    
    async def delete_event(self, event_id: str) -> bool:
        """Delete a calendar event"""
        if not self.service:
            return False
        
        try:
            self.service.events().delete(
                calendarId=self.calendar_id,
                eventId=event_id
            ).execute()
            return True
        except HttpError as error:
            logger.error(f"Error deleting calendar event: {error}")
            return False


class GoogleTasksService:
    """Service to interact with Google Tasks API"""
    
    def __init__(self, manager: GoogleServicesManager):
        self.service = manager.tasks_service
        self.tasklist_id = os.getenv('GOOGLE_TASKS_LIST_ID', '@default')
    
    async def get_task_lists(self) -> List[Dict]:
        """Get all task lists"""
        if not self.service:
            return []
        
        try:
            results = self.service.tasklists().list().execute()
            return results.get('items', [])
        except HttpError as error:
            logger.error(f"Error fetching task lists: {error}")
            return []
    
    async def get_tasks(self, show_completed: bool = True) -> List[Dict]:
        """Get tasks from the default task list"""
        if not self.service:
            return []
        
        try:
            results = self.service.tasks().list(
                tasklist=self.tasklist_id,
                showCompleted=show_completed,
                showHidden=True
            ).execute()
            
            tasks = results.get('items', [])
            
            # Simplify format
            simplified_tasks = []
            for task in tasks:
                simplified_tasks.append({
                    'id': task['id'],
                    'title': task.get('title', 'Sin título'),
                    'notes': task.get('notes', ''),
                    'status': task.get('status', 'needsAction'),
                    'completed': task.get('status') == 'completed',
                    'due': task.get('due'),
                    'updated': task.get('updated'),
                })
            
            return simplified_tasks
        except HttpError as error:
            logger.error(f"Error fetching tasks: {error}")
            return []
    
    async def create_task(
        self, 
        title: str, 
        notes: str = None,
        due: datetime = None
    ) -> Optional[Dict]:
        """Create a new task"""
        if not self.service:
            return None
        
        try:
            task = {'title': title}
            
            if notes:
                task['notes'] = notes
            if due:
                task['due'] = due.isoformat() + 'Z'
            
            result = self.service.tasks().insert(
                tasklist=self.tasklist_id,
                body=task
            ).execute()
            
            return {
                'id': result['id'],
                'title': result.get('title', ''),
                'notes': result.get('notes', ''),
                'status': result.get('status', 'needsAction'),
                'completed': False,
                'due': result.get('due'),
            }
        except HttpError as error:
            logger.error(f"Error creating task: {error}")
            return None
    
    async def update_task(self, task_id: str, updates: Dict) -> Optional[Dict]:
        """Update an existing task"""
        if not self.service:
            return None
        
        try:
            task = self.service.tasks().get(
                tasklist=self.tasklist_id,
                task=task_id
            ).execute()
            
            # Apply updates
            if 'title' in updates:
                task['title'] = updates['title']
            if 'notes' in updates:
                task['notes'] = updates['notes']
            if 'status' in updates:
                task['status'] = updates['status']
            if 'due' in updates:
                task['due'] = updates['due']
            if 'completed' in updates:
                task['status'] = 'completed' if updates['completed'] else 'needsAction'
            
            result = self.service.tasks().update(
                tasklist=self.tasklist_id,
                task=task_id,
                body=task
            ).execute()
            
            return {
                'id': result['id'],
                'title': result.get('title', ''),
                'status': result.get('status', 'needsAction'),
                'completed': result.get('status') == 'completed',
            }
        except HttpError as error:
            logger.error(f"Error updating task: {error}")
            return None
    
    async def complete_task(self, task_id: str) -> Optional[Dict]:
        """Mark a task as completed"""
        return await self.update_task(task_id, {'status': 'completed'})
    
    async def delete_task(self, task_id: str) -> bool:
        """Delete a task"""
        if not self.service:
            return False
        
        try:
            self.service.tasks().delete(
                tasklist=self.tasklist_id,
                task=task_id
            ).execute()
            return True
        except HttpError as error:
            logger.error(f"Error deleting task: {error}")
            return False


# Initialize global manager
google_manager = GoogleServicesManager()
google_calendar = GoogleCalendarService(google_manager)
google_tasks = GoogleTasksService(google_manager)

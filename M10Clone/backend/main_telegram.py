#!/usr/bin/env python3
"""
Simplified M10 Backend - Telegram Integration
Messages from iOS app are forwarded to Telegram bot
"""

import os
import logging
from datetime import datetime
from typing import Dict, List, Optional
import uuid
import asyncio

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Telegram configuration
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA")
TELEGRAM_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"

# Get admin chat ID from environment or use yours after running /start
ADMIN_CHAT_ID = os.getenv("ADMIN_CHAT_ID")  # Set this after getting your chat ID

# In-memory storage
sessions_db: Dict[str, Dict] = {}

# Pydantic Models
class DeviceInfo(BaseModel):
    model: str
    os_version: str
    app_version: str

class ChatRequest(BaseModel):
    session_id: str
    message: str
    timestamp: datetime
    platform: str = "ios"
    device_info: DeviceInfo

class SourceInfo(BaseModel):
    title: str
    url: str
    excerpt: str

class ResponseMetadata(BaseModel):
    tokens_used: Optional[int] = None
    model: Optional[str] = None
    confidence: Optional[float] = None

class ChatResponse(BaseModel):
    session_id: str
    message_id: str
    answer: str
    language: str
    sources: List[SourceInfo]
    timestamp: datetime
    metadata: ResponseMetadata

class SessionResponse(BaseModel):
    session_id: str

# Initialize FastAPI
app = FastAPI(
    title="M10 Support API - Telegram Bridge",
    description="Forwards iOS app messages to Telegram bot",
    version="1.0.0"
)

# Add CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Telegram integration
async def send_to_telegram(session_id: str, message: str, device_info: dict = None):
    """Send message to Telegram bot"""
    try:
        if not ADMIN_CHAT_ID:
            logger.warning("ADMIN_CHAT_ID not set. Please run /start in Telegram bot first!")
            return False
        
        # Format device info
        device_text = ""
        if device_info:
            device_text = f"\n📱 {device_info.get('model', 'Unknown')} - iOS {device_info.get('os_version', '?')}"
        
        # Format message for Telegram
        text = (
            f"💬 *Yeni mesaj iOS tətbiqdən:*\n\n"
            f"{message}\n"
            f"\n➖➖➖➖➖➖➖➖➖\n"
            f"Session: `{session_id}`"
            f"{device_text}\n"
            f"🕐 {datetime.now().strftime('%H:%M:%S')}"
        )
        
        # Send to Telegram
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{TELEGRAM_API_URL}/sendMessage",
                json={
                    "chat_id": ADMIN_CHAT_ID,
                    "text": text,
                    "parse_mode": "Markdown"
                }
            )
            
            if response.status_code == 200:
                logger.info(f"Message sent to Telegram for session {session_id}")
                return True
            else:
                logger.error(f"Telegram API error: {response.text}")
                return False
                
    except Exception as e:
        logger.error(f"Error sending to Telegram: {e}")
        return False

async def check_telegram_response(session_id: str) -> Optional[str]:
    """Check if there's a response from Telegram for this session"""
    session = sessions_db.get(session_id)
    if session and session.get('responses'):
        # Get the latest unread response
        for response in reversed(session['responses']):
            if not response.get('read', False):
                response['read'] = True
                return response['text']
    return None

# API Endpoints
@app.get("/")
async def root():
    """Health check"""
    return {
        "status": "ok",
        "service": "M10 Support API - Telegram Bridge",
        "telegram_configured": bool(ADMIN_CHAT_ID),
        "instruction": "Run /start in Telegram bot to get your chat ID" if not ADMIN_CHAT_ID else "Ready"
    }

@app.post("/api/v1/chat/ios/session")
async def create_session() -> SessionResponse:
    """Create new chat session"""
    session_id = str(uuid.uuid4())
    sessions_db[session_id] = {
        "created_at": datetime.utcnow().isoformat(),
        "messages": [],
        "responses": []
    }
    logger.info(f"Created session: {session_id}")
    return SessionResponse(session_id=session_id)

@app.post("/api/v1/chat/ios/message")
async def send_message(request: ChatRequest, background_tasks: BackgroundTasks) -> ChatResponse:
    """Process message from iOS app"""
    # Check session
    if request.session_id not in sessions_db:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Store message
    message_id = str(uuid.uuid4())
    sessions_db[request.session_id]["messages"].append({
        "id": message_id,
        "text": request.message,
        "timestamp": request.timestamp.isoformat(),
        "device_info": request.device_info.dict()
    })
    
    # Send to Telegram in background
    background_tasks.add_task(
        send_to_telegram,
        request.session_id,
        request.message,
        request.device_info.dict()
    )
    
    # Check for Telegram response or generate auto-response
    telegram_response = await check_telegram_response(request.session_id)
    
    if telegram_response:
        answer = telegram_response
    else:
        # Auto-response while waiting for Telegram
        answer = generate_auto_response(request.message)
    
    return ChatResponse(
        session_id=request.session_id,
        message_id=message_id,
        answer=answer,
        language="az",
        sources=[],
        timestamp=datetime.utcnow(),
        metadata=ResponseMetadata(
            confidence=0.95 if telegram_response else 0.5
        )
    )

@app.get("/api/v1/chat/ios/history/{session_id}")
async def get_history(session_id: str, limit: int = 50):
    """Get chat history"""
    if session_id not in sessions_db:
        raise HTTPException(status_code=404, detail="Session not found")
    
    messages = sessions_db[session_id]["messages"][-limit:]
    return {"messages": messages}

@app.post("/webhook/telegram/{session_id}")
async def telegram_webhook(session_id: str, response_text: str):
    """Webhook for receiving responses from Telegram (optional)"""
    if session_id in sessions_db:
        sessions_db[session_id]["responses"].append({
            "text": response_text,
            "timestamp": datetime.utcnow().isoformat(),
            "read": False
        })
        return {"status": "ok"}
    else:
        raise HTTPException(status_code=404, detail="Session not found")

def generate_auto_response(message: str) -> str:
    """Generate automatic response while waiting for Telegram"""
    return (
        "Sizin mesajınız qəbul edildi və dəstək komandamıza göndərildi. "
        "Tezliklə sizinlə əlaqə saxlanılacaq. "
        "Bu arada, əsas suallar üçün /help yazın."
    )

@app.get("/config/telegram")
async def get_telegram_config():
    """Get Telegram bot configuration info"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{TELEGRAM_API_URL}/getMe")
            if response.status_code == 200:
                bot_info = response.json()["result"]
                return {
                    "bot_username": bot_info["username"],
                    "bot_name": bot_info["first_name"],
                    "admin_chat_id_set": bool(ADMIN_CHAT_ID),
                    "telegram_link": f"https://t.me/{bot_info['username']}"
                }
    except Exception as e:
        logger.error(f"Error getting bot info: {e}")
    
    return {"error": "Could not get bot info"}

if __name__ == "__main__":
    import uvicorn
    
    print("\n" + "="*50)
    print("🚀 M10 Support API - Telegram Bridge")
    print("="*50)
    print("\n📱 Telegram Bot Setup:")
    print(f"1. Open Telegram and search for your bot")
    print(f"2. Send /start to get your chat ID")
    print(f"3. Set ADMIN_CHAT_ID in .env file")
    print(f"4. Restart the server")
    print("\n" + "="*50 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8000)

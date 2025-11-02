#!/usr/bin/env python3
"""
M10 Support Backend API
AI-powered support system with Kimi integration
"""

import os
import logging
from datetime import datetime
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv
import httpx
import uuid
import json

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global variables
app_state = {}

# Configuration
class Config:
    # API Keys
    KIMI_API_KEY = os.getenv("KIMI_API_KEY")
    KIMI_BASE_URL = os.getenv("KIMI_BASE_URL", "https://api.moonshot.cn/v1/chat/completions")
    KIMI_MODEL = os.getenv("KIMI_MODEL", "kimi-k2-turbo-preview")
    
    # MongoDB
    MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
    MONGODB_DB_NAME = os.getenv("MONGODB_DB_NAME", "m10_support")
    
    # Server
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 8000))
    
    # CORS
    CORS_ORIGINS = json.loads(os.getenv("CORS_ORIGINS", '["*"]'))

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

class MessageDTO(BaseModel):
    id: str
    text: str
    sender: str
    timestamp: datetime
    sources: Optional[List[SourceInfo]] = None

class HistoryResponse(BaseModel):
    messages: List[MessageDTO]

# Database setup
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    try:
        client = AsyncIOMotorClient(Config.MONGODB_URL)
        app_state["mongodb_client"] = client
        app_state["mongodb"] = client[Config.MONGODB_DB_NAME]
        logger.info("Connected to MongoDB")
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise
    
    yield
    
    # Shutdown
    if "mongodb_client" in app_state:
        app_state["mongodb_client"].close()
        logger.info("Disconnected from MongoDB")

# Initialize FastAPI app
app = FastAPI(
    title="M10 Support API",
    description="AI-powered support system for M10 mobile app",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=Config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependencies
def get_db():
    return app_state.get("mongodb")

# AI Service
class AIService:
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=30.0)
        self.system_prompt = """Sən m10 mobil tətbiqinin dəstək agentisən. Adın Aydın. 
Azərbaycan dilində danış və müştərilərə kömək et. 
m10 xidmətləri haqqında məlumat ver:
- BakıKART balans artırma
- Pul köçürmələri
- Kommunal ödənişlər
- Kredit xidmətləri
- Digər ödənişlər

Həmişə dost canlı və peşəkar ol."""

    async def generate_response(self, message: str, session_id: str) -> tuple[str, List[SourceInfo]]:
        """Generate AI response using Kimi API"""
        try:
            headers = {
                "Authorization": f"Bearer {Config.KIMI_API_KEY}",
                "Content-Type": "application/json"
            }
            
            data = {
                "model": Config.KIMI_MODEL,
                "messages": [
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": message}
                ],
                "temperature": 0.7,
                "max_tokens": 500
            }
            
            response = await self.client.post(
                Config.KIMI_BASE_URL,
                headers=headers,
                json=data
            )
            
            if response.status_code != 200:
                logger.error(f"Kimi API error: {response.status_code} - {response.text}")
                raise HTTPException(status_code=500, detail="AI service error")
            
            result = response.json()
            answer = result["choices"][0]["message"]["content"]
            
            # Mock sources for now
            sources = [
                SourceInfo(
                    title="m10 Dəstək Mərkəzi",
                    url="https://m10.az/support",
                    excerpt="m10 xidmətləri haqqında ətraflı məlumat"
                )
            ]
            
            return answer, sources
            
        except Exception as e:
            logger.error(f"AI generation error: {e}")
            # Fallback response
            return self._get_fallback_response(message), []
    
    def _get_fallback_response(self, message: str) -> str:
        """Generate fallback response when AI is unavailable"""
        message_lower = message.lower()
        
        if "bakıkart" in message_lower or "бакыкарт" in message_lower:
            return "BakıKART balansını artırmaq üçün:\n1. Xidmətlər bölməsinə keçin\n2. BakıKART seçin\n3. Kart nömrəsini daxil edin\n4. Məbləği seçin\n5. Ödə düyməsinə toxunun"
        elif "balans" in message_lower or "баланс" in message_lower:
            return "Balansınızı əsas ekranda görə bilərsiniz. Balansı gizlətmək və ya göstərmək üçün göz işarəsinə toxunun."
        elif "köçürmə" in message_lower or "перевод" in message_lower:
            return "Pul köçürmələri pulsuz və anidir. Telefon nömrəsi və ya kart nömrəsi ilə köçürmə edə bilərsiniz."
        else:
            return "Mən sizə m10 xidmətləri ilə bağlı kömək edə bilərəm. Xahiş edirəm sualınızı daha dəqiq ifadə edin."

ai_service = AIService()

# API Endpoints
@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "ok", "service": "M10 Support API"}

@app.post("/api/v1/chat/ios/session", response_model=SessionResponse)
async def create_session(db = Depends(get_db)):
    """Create new chat session"""
    session_id = str(uuid.uuid4())
    
    # Store session in database
    session_doc = {
        "_id": session_id,
        "created_at": datetime.utcnow(),
        "platform": "ios",
        "messages": []
    }
    
    try:
        await db.sessions.insert_one(session_doc)
        logger.info(f"Created session: {session_id}")
    except Exception as e:
        logger.error(f"Failed to create session: {e}")
        raise HTTPException(status_code=500, detail="Failed to create session")
    
    return SessionResponse(session_id=session_id)

@app.post("/api/v1/chat/ios/message", response_model=ChatResponse)
async def send_message(request: ChatRequest, db = Depends(get_db)):
    """Process chat message and return AI response"""
    try:
        # Generate AI response
        answer, sources = await ai_service.generate_response(
            request.message, 
            request.session_id
        )
        
        message_id = str(uuid.uuid4())
        
        # Store user message
        user_message = {
            "id": str(uuid.uuid4()),
            "text": request.message,
            "sender": "user",
            "timestamp": request.timestamp,
            "device_info": request.device_info.dict()
        }
        
        # Store assistant response
        assistant_message = {
            "id": message_id,
            "text": answer,
            "sender": "assistant",
            "timestamp": datetime.utcnow(),
            "sources": [s.dict() for s in sources]
        }
        
        # Update session
        await db.sessions.update_one(
            {"_id": request.session_id},
            {
                "$push": {
                    "messages": {
                        "$each": [user_message, assistant_message]
                    }
                },
                "$set": {
                    "last_activity": datetime.utcnow()
                }
            }
        )
        
        # Detect language (simplified)
        language = "az"  # Azerbaijani by default
        
        return ChatResponse(
            session_id=request.session_id,
            message_id=message_id,
            answer=answer,
            language=language,
            sources=sources,
            timestamp=datetime.utcnow(),
            metadata=ResponseMetadata(
                model=Config.KIMI_MODEL,
                confidence=0.95
            )
        )
        
    except Exception as e:
        logger.error(f"Message processing error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/chat/ios/history/{session_id}", response_model=HistoryResponse)
async def get_chat_history(session_id: str, limit: int = 50, db = Depends(get_db)):
    """Get chat history for a session"""
    try:
        session = await db.sessions.find_one({"_id": session_id})
        
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        messages = session.get("messages", [])[-limit:]
        
        # Convert to DTOs
        message_dtos = []
        for msg in messages:
            sources = None
            if msg.get("sources"):
                sources = [SourceInfo(**s) for s in msg["sources"]]
            
            message_dtos.append(MessageDTO(
                id=msg["id"],
                text=msg["text"],
                sender=msg["sender"],
                timestamp=msg["timestamp"],
                sources=sources
            ))
        
        return HistoryResponse(messages=message_dtos)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"History retrieval error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Run the server
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=Config.HOST,
        port=Config.PORT,
        reload=True,
        log_level="info"
    )

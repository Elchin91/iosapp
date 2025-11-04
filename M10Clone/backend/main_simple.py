#!/usr/bin/env python3
"""
Simplified M10 Support Backend - Quick Start Version
No database required, runs with minimal dependencies
"""

import os
import logging
from datetime import datetime
from typing import List, Dict, Optional
import uuid
import json

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import httpx
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# In-memory storage (for testing)
sessions_db: Dict[str, Dict] = {}

# Configuration
KIMI_API_KEY = os.getenv("KIMI_API_KEY", "sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG")
KIMI_BASE_URL = "https://api.moonshot.cn/v1/chat/completions"
KIMI_MODEL = "kimi-k2-turbo-preview"

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
app = FastAPI(title="M10 Support API", version="1.0.0")

# Add CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# AI Client
http_client = httpx.AsyncClient(timeout=30.0)

async def generate_ai_response(message: str) -> tuple[str, List[SourceInfo]]:
    """Generate response using Kimi API"""
    try:
        headers = {
            "Authorization": f"Bearer {KIMI_API_KEY}",
            "Content-Type": "application/json"
        }
        
        system_prompt = """Sən m10 mobil tətbiqinin dəstək agentisən. Adın Aydın. 
Azərbaycan dilində danış və müştərilərə kömək et. 
m10 xidmətləri: BakıKART, pul köçürmələri, kommunal ödənişlər, kredit.
Həmişə dost canlı və peşəkar ol."""
        
        data = {
            "model": KIMI_MODEL,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": message}
            ],
            "temperature": 0.7,
            "max_tokens": 500
        }
        
        response = await http_client.post(KIMI_BASE_URL, headers=headers, json=data)
        
        if response.status_code == 200:
            result = response.json()
            answer = result["choices"][0]["message"]["content"]
        else:
            logger.error(f"Kimi API error: {response.status_code}")
            answer = get_fallback_response(message)
        
        sources = [
            SourceInfo(
                title="m10 Dəstək",
                url="https://m10.az/support",
                excerpt="m10 xidmətləri haqqında məlumat"
            )
        ]
        
        return answer, sources
        
    except Exception as e:
        logger.error(f"AI error: {e}")
        return get_fallback_response(message), []

def get_fallback_response(message: str) -> str:
    """Fallback responses when AI is unavailable"""
    msg_lower = message.lower()
    
    if "bakıkart" in msg_lower:
        return "BakıKART balansını artırmaq üçün:\n1. Xidmətlər bölməsinə keçin\n2. BakıKART seçin\n3. Kart nömrəsini daxil edin\n4. Məbləği seçin (1-100 AZN)\n5. Ödə düyməsinə toxunun"
    elif "balans" in msg_lower:
        return "Balansınızı əsas ekranda görə bilərsiniz. Göz işarəsinə toxunaraq balansı gizlədə bilərsiniz."
    elif "köçürmə" in msg_lower or "transfer" in msg_lower:
        return "Pul köçürmələri pulsuz və anidir. Telefon və ya kart nömrəsi ilə köçürmə edə bilərsiniz."
    elif "kredit" in msg_lower:
        return "m10 kredit xidməti:\n• Maksimum: 25,000 AZN\n• Müddət: 3-36 ay\n• Onlayn müraciət\n• Sürətli cavab"
    else:
        return "Mən sizə m10 xidmətləri ilə bağlı kömək edə bilərəm. Sualınızı daha dəqiq ifadə edin."

# API Endpoints
@app.get("/")
async def root():
    return {"status": "ok", "service": "M10 Support API", "version": "1.0.0"}

@app.post("/api/v1/chat/ios/session")
async def create_session() -> SessionResponse:
    """Create new chat session"""
    session_id = str(uuid.uuid4())
    sessions_db[session_id] = {
        "created_at": datetime.utcnow().isoformat(),
        "messages": []
    }
    logger.info(f"Created session: {session_id}")
    return SessionResponse(session_id=session_id)

@app.post("/api/v1/chat/ios/message")
async def send_message(request: ChatRequest) -> ChatResponse:
    """Process message and return AI response"""
    # Check session
    if request.session_id not in sessions_db:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Generate response
    answer, sources = await generate_ai_response(request.message)
    message_id = str(uuid.uuid4())
    
    # Store messages
    sessions_db[request.session_id]["messages"].extend([
        {
            "id": str(uuid.uuid4()),
            "text": request.message,
            "sender": "user",
            "timestamp": request.timestamp.isoformat()
        },
        {
            "id": message_id,
            "text": answer,
            "sender": "assistant",
            "timestamp": datetime.utcnow().isoformat(),
            "sources": [s.dict() for s in sources]
        }
    ])
    
    return ChatResponse(
        session_id=request.session_id,
        message_id=message_id,
        answer=answer,
        language="az",
        sources=sources,
        timestamp=datetime.utcnow(),
        metadata=ResponseMetadata(
            model=KIMI_MODEL,
            confidence=0.95
        )
    )

@app.get("/api/v1/chat/ios/history/{session_id}")
async def get_history(session_id: str, limit: int = 50):
    """Get chat history"""
    if session_id not in sessions_db:
        raise HTTPException(status_code=404, detail="Session not found")
    
    messages = sessions_db[session_id]["messages"][-limit:]
    return {"messages": messages}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

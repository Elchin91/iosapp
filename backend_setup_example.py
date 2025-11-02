#
# backend_setup_example.py
# Пример настройки Backend API с реальными данными
# Для использования в FastAPI backend приложении
#

import os
from typing import List, Dict, Optional
from datetime import datetime
import httpx
import base64
import uuid
from pydantic import BaseModel

# ============================================================================
# КОНФИГУРАЦИЯ (из .env файла)
# ============================================================================

# Kimi K2 API
KIMI_API_KEY = "sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG"
KIMI_BASE_URL = "https://api.moonshot.cn/v1/chat/completions"
KIMI_MODEL = "kimi-k2-turbo-preview"

# Confluence API (замените на ваши данные)
CONFLUENCE_BASE_URL = "https://your-domain.atlassian.net"  # Замените!
CONFLUENCE_EMAIL = "your-email@m10.az"  # Замените!
CONFLUENCE_API_TOKEN = "your_confluence_token"  # Замените!
CONFLUENCE_SPACE_KEY = "M10SUPPORT"

# Telegram Bot (опционально)
TELEGRAM_BOT_TOKEN = "8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA"

# ============================================================================
# ПРИМЕР: Запрос к Kimi K2 API
# ============================================================================

async def call_kimi_api(
    system_prompt: str,
    user_prompt: str,
    temperature: float = 0.7,
    max_tokens: int = 1000
) -> Dict:
    """
    Вызов Kimi K2 API для генерации ответа
    
    Args:
        system_prompt: Системный промпт (роль ассистента)
        user_prompt: Пользовательский промпт (вопрос + контекст)
        temperature: Температура генерации (0.0-1.0)
        max_tokens: Максимальное количество токенов
    
    Returns:
        Dict с ответом от API
    """
    url = KIMI_BASE_URL
    
    headers = {
        "Authorization": f"Bearer {KIMI_API_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": KIMI_MODEL,
        "messages": [
            {
                "role": "system",
                "content": system_prompt
            },
            {
                "role": "user",
                "content": user_prompt
            }
        ],
        "temperature": temperature,
        "max_tokens": max_tokens
    }
    
    async with httpx.AsyncClient(timeout=60.0) as client:
        try:
            response = await client.post(url, json=payload, headers=headers)
            response.raise_for_status()
            data = response.json()
            
            return {
                "answer": data["choices"][0]["message"]["content"],
                "model": KIMI_MODEL,
                "tokens_used": data["usage"]["total_tokens"],
                "confidence": 0.9  # Можно рассчитать на основе других факторов
            }
        except httpx.HTTPError as e:
            print(f"❌ Kimi API Error: {e}")
            raise


# ============================================================================
# ПРИМЕР: Поиск в Confluence API
# ============================================================================

async def search_confluence(
    query: str,
    space_key: str = CONFLUENCE_SPACE_KEY,
    limit: int = 10
) -> List[Dict]:
    """
    Поиск в Confluence через REST API v2
    
    Args:
        query: Поисковый запрос
        space_key: Ключ пространства Confluence
        limit: Максимальное количество результатов
    
    Returns:
        Список найденных страниц
    """
    # Формируем CQL запрос
    cql = f'space = "{space_key}" AND text ~ "{query}"'
    
    url = f"{CONFLUENCE_BASE_URL}/rest/api/content/search"
    
    # Basic Authentication
    credentials = f"{CONFLUENCE_EMAIL}:{CONFLUENCE_API_TOKEN}"
    encoded_credentials = base64.b64encode(credentials.encode()).decode()
    
    headers = {
        "Authorization": f"Basic {encoded_credentials}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    
    params = {
        "cql": cql,
        "limit": limit,
        "expand": "body.storage,version,space"
    }
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            response = await client.get(url, params=params, headers=headers)
            response.raise_for_status()
            data = response.json()
            
            results = []
            for item in data.get("results", []):
                # Извлекаем текст из HTML
                body_storage = item.get("body", {}).get("storage", {}).get("value", "")
                text_content = extract_text_from_html(body_storage)
                
                results.append({
                    "id": item["id"],
                    "title": item["title"],
                    "text": text_content,
                    "url": f"{CONFLUENCE_BASE_URL}{item['_links']['webui']}",
                    "space": item.get("space", {}).get("key", space_key),
                    "version": item.get("version", {}).get("number", 1)
                })
            
            return results
        except httpx.HTTPError as e:
            print(f"❌ Confluence API Error: {e}")
            return []


def extract_text_from_html(html_content: str) -> str:
    """
    Извлекает текст из Confluence HTML
    В production используйте BeautifulSoup или другой парсер
    """
    # Простое извлечение текста (в production нужен парсер)
    import re
    # Удаляем HTML теги
    text = re.sub(r'<[^>]+>', '', html_content)
    # Очищаем пробелы
    text = ' '.join(text.split())
    return text[:500]  # Ограничиваем длину


# ============================================================================
# ПРИМЕР: FastAPI Endpoint для iOS
# ============================================================================

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()


class ChatRequest(BaseModel):
    session_id: str
    message: str
    timestamp: datetime
    platform: str = "ios"
    device_info: Dict


class ChatResponse(BaseModel):
    session_id: str
    message_id: str
    answer: str
    language: str
    sources: List[Dict]
    timestamp: datetime
    metadata: Dict


@app.post("/api/v1/chat/ios/message", response_model=ChatResponse)
async def handle_ios_message(request: ChatRequest):
    """
    Обработка сообщения от iOS клиента
    
    Логика:
    1. Определение языка
    2. Поиск в Confluence
    3. Генерация ответа через Kimi
    4. Возврат ответа iOS
    """
    try:
        # 1. Определяем язык (упрощенная версия)
        language = detect_language(request.message)
        
        # 2. Ищем в Confluence
        confluence_results = await search_confluence(request.message)
        
        # 3. Формируем контекст для AI
        context_text = "\n\n".join([
            f"📄 {r['title']}\n{r['text']}"
            for r in confluence_results[:3]  # Топ-3 результата
        ])
        
        # 4. Создаем промпты
        system_prompt = get_system_prompt(language)
        user_prompt = f"""
BAZA (Confluence dokumentasiyası):
{context_text}

MÜŞTƏRİNİN SUALI: {request.message}

VACIB:
- Yuxarıdakı məlumatdan istifadə edərək dəqiq və faydalı cavab ver
- Real insan kimi danış, texniki terminlər işlətmə
- Əgər məlumat kifayət deyilsə, açıq de
- Addım-addım təlimat ver

CAVAB:
"""
        
        # 5. Генерируем ответ через Kimi
        ai_response = await call_kimi_api(system_prompt, user_prompt)
        
        # 6. Формируем источники
        sources = [
            {
                "title": r["title"],
                "url": r["url"],
                "excerpt": r["text"][:200]
            }
            for r in confluence_results[:3]
        ]
        
        # 7. Возвращаем ответ
        return ChatResponse(
            session_id=request.session_id,
            message_id=str(uuid.uuid4()),
            answer=ai_response["answer"],
            language=language,
            sources=sources,
            timestamp=datetime.utcnow(),
            metadata={
                "tokens_used": ai_response["tokens_used"],
                "model": ai_response["model"],
                "confidence": ai_response["confidence"]
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def detect_language(text: str) -> str:
    """Определяет язык текста"""
    az_chars = ['ə', 'ı', 'ö', 'ü', 'ğ', 'ç', 'ş']
    ru_chars = ['а', 'б', 'в', 'ж', 'з', 'ы', 'э', 'ю', 'я']
    
    text_lower = text.lower()
    
    if any(char in text_lower for char in az_chars):
        return "az"
    elif any(char in text_lower for char in ru_chars):
        return "ru"
    else:
        return "en"


def get_system_prompt(language: str) -> str:
    """Возвращает системный промпт в зависимости от языка"""
    if language == "az":
        return """Sən m10 dəstək xidmətində işləyən real əməkdaşsan. Adın Aydın.

QAYDALAR:
- Real insan kimi danış, robot deyilsən
- Mehriban və peşəkar ol
- Sadə dildə izah et
- Kontekstdəki məlumatı tam istifadə et
- Əgər məlumat yoxdursa, səmimi de

m10 XİDMƏTLƏRİ:
- Mobil pul köçürmələri
- Kart əməliyyatları
- Kommunal ödənişlər (işıq, qaz, su, internet)
- BakıKART balans artırma
- Keşbek sistemi
- Cash loan (kredit)"""
    elif language == "ru":
        return """Ты работаешь в службе поддержки m10. Твое имя Айдын.

ПРАВИЛА:
- Общайся как живой человек, а не робот
- Будь дружелюбным и профессиональным
- Объясняй простым языком
- Используй всю информацию из контекста
- Если информации нет, честно скажи

СЕРВИСЫ m10:
- Мобильные переводы
- Операции с картами
- Коммунальные платежи (свет, газ, вода, интернет)
- Пополнение баланса BakıKART
- Система кешбека
- Кредит"""
    else:
        return """You are a real employee working at m10 support service. Your name is Aydin.

RULES:
- Speak like a real person, not a robot
- Be friendly and professional
- Explain in simple language
- Use all information from context
- If information is missing, be honest

m10 SERVICES:
- Mobile money transfers
- Card operations
- Utility payments (electricity, gas, water, internet)
- BakıKART balance top-up
- Cashback system
- Cash loan"""


# ============================================================================
# ПРИМЕР: Endpoint для создания сессии
# ============================================================================

@app.post("/api/v1/chat/ios/session")
async def create_session():
    """Создает новую сессию чата для iOS клиента"""
    session_id = str(uuid.uuid4())
    
    # Здесь можно сохранить сессию в MongoDB
    # await save_session_to_db(session_id)
    
    return {"session_id": session_id}


# ============================================================================
# ЗАПУСК СЕРВЕРА
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


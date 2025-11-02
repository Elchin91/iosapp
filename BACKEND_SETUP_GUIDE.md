# Backend Setup Guide
## Инструкции по настройке Backend API с реальными данными

> **Важно:** iOS приложение НЕ обращается напрямую к Kimi API или Confluence API. 
> Все запросы идут через Backend API, который вы должны настроить.

---

## 📋 Быстрый старт

### 1. Установка зависимостей

```bash
pip install fastapi uvicorn httpx python-dotenv beanie motor
```

### 2. Создание .env файла

Создайте файл `backend/.env`:

```env
# Kimi K2 API
KIMI_API_KEY=sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG
KIMI_BASE_URL=https://api.moonshot.cn/v1/chat/completions
KIMI_MODEL=kimi-k2-turbo-preview

# Confluence API
CONFLUENCE_BASE_URL=https://your-domain.atlassian.net
CONFLUENCE_EMAIL=your-email@m10.az
CONFLUENCE_API_TOKEN=your_confluence_api_token
CONFLUENCE_SPACE_KEY=M10SUPPORT

# Telegram Bot (опционально)
TELEGRAM_BOT_TOKEN=8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA

# MongoDB
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB=m10_support

# API Settings
API_PREFIX=/api/v1
CORS_ORIGINS=*
```

### 3. Получение Confluence API Token

1. Перейдите на https://id.atlassian.com/manage-profile/security/api-tokens
2. Нажмите "Create API token"
3. Скопируйте токен и добавьте в `.env` файл
4. Используйте ваш email и токен для Basic Authentication

### 4. Запуск сервера

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## 🔧 Интеграция с Kimi K2 API

### Пример запроса

```python
import httpx

async def call_kimi_api(prompt: str, context: str):
    url = "https://api.moonshot.cn/v1/chat/completions"
    
    headers = {
        "Authorization": f"Bearer sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": "kimi-k2-turbo-preview",
        "messages": [
            {
                "role": "system",
                "content": "Sən m10 dəstək xidmətində işləyən real əməkdaşsan..."
            },
            {
                "role": "user",
                "content": f"{context}\n\nMÜŞTƏRİNİN SUALI: {prompt}"
            }
        ],
        "temperature": 0.7,
        "max_tokens": 1000
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=payload, headers=headers)
        return response.json()["choices"][0]["message"]["content"]
```

---

## 🔍 Интеграция с Confluence API

### Документация
- [Confluence Cloud REST API v2](https://developer.atlassian.com/cloud/confluence/rest/v2/intro/#about)
- [CQL Guide](https://developer.atlassian.com/cloud/confluence/advanced-searching-using-cql/)

### Пример поиска

```python
import httpx
import base64

async def search_confluence(query: str):
    url = "https://your-domain.atlassian.net/rest/api/content/search"
    
    # Basic Auth
    credentials = f"{CONFLUENCE_EMAIL}:{CONFLUENCE_API_TOKEN}"
    encoded = base64.b64encode(credentials.encode()).decode()
    
    headers = {
        "Authorization": f"Basic {encoded}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    
    # CQL запрос
    cql = f'space = "M10SUPPORT" AND text ~ "{query}"'
    
    params = {
        "cql": cql,
        "limit": 10,
        "expand": "body.storage,version,space"
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params, headers=headers)
        return response.json()["results"]
```

### Важные endpoints Confluence API

```
GET /rest/api/content/search - Поиск страниц
GET /rest/api/content/{id} - Получить страницу по ID
GET /rest/api/content/{id}?expand=body.storage - Получить содержимое страницы
```

---

## 📱 iOS Endpoints (что должен реализовать Backend)

### POST /api/v1/chat/ios/session
Создает новую сессию.

**Response:**
```json
{
  "session_id": "uuid-123-456"
}
```

### POST /api/v1/chat/ios/message
Обрабатывает сообщение от iOS.

**Request:**
```json
{
  "session_id": "uuid-123-456",
  "message": "BakıKART-a necə pul yükləyə bilərəm?",
  "timestamp": "2025-01-15T10:30:00Z",
  "platform": "ios",
  "device_info": {
    "model": "iPhone 14 Pro",
    "os_version": "17.2",
    "app_version": "1.0"
  }
}
```

**Response:**
```json
{
  "session_id": "uuid-123-456",
  "message_id": "msg-789-012",
  "answer": "Salam! BakıKART-a pul yükləmək çox asandır...",
  "language": "az",
  "sources": [
    {
      "title": "BakıKART pul yükləmə təlimatı",
      "url": "https://confluence.m10.az/spaces/M10SUPPORT/pages/12345",
      "excerpt": "m10 tətbiqində BakıKART balansını artırmaq..."
    }
  ],
  "timestamp": "2025-01-15T10:30:15Z",
  "metadata": {
    "tokens_used": 450,
    "model": "kimi-k2-turbo-preview",
    "confidence": 0.92
  }
}
```

### GET /api/v1/chat/ios/history/{session_id}?limit=50
Получает историю чата.

---

## 🚀 Полный пример backend кода

См. файл `backend_setup_example.py` в корне проекта M10Clone.

---

## ⚙️ Настройка iOS приложения

В iOS приложении URL backend настраивается в `APIConfig.swift`:

```swift
#if DEBUG
static let baseURL = "http://localhost:8000/api/v1"  // Для локальной разработки
#else
static let baseURL = "https://api.m10support.com/api/v1"  // Production
#endif
```

---

## 🧪 Тестирование

### Тест Kimi API

```python
import asyncio
from backend_setup_example import call_kimi_api

async def test_kimi():
    response = await call_kimi_api(
        system_prompt="You are a helpful assistant.",
        user_prompt="Say hello in Azerbaijani"
    )
    print(response["answer"])

asyncio.run(test_kimi())
```

### Тест Confluence API

```python
import asyncio
from backend_setup_example import search_confluence

async def test_confluence():
    results = await search_confluence("BakıKART")
    for r in results:
        print(f"{r['title']}: {r['url']}")

asyncio.run(test_confluence())
```

---

## 📝 Важные замечания

1. **Безопасность**: Никогда не храните API ключи в коде iOS приложения
2. **Backend только**: iOS приложение общается только с Backend API
3. **Обработка ошибок**: Всегда обрабатывайте ошибки от внешних API
4. **Rate Limits**: Учитывайте ограничения на запросы к Kimi и Confluence
5. **Кеширование**: Рассмотрите кеширование часто запрашиваемых данных

---

## 🔗 Полезные ссылки

- [Kimi K2 API Documentation](https://platform.moonshot.cn/docs)
- [Confluence REST API v2](https://developer.atlassian.com/cloud/confluence/rest/v2/)
- [CQL Search Guide](https://developer.atlassian.com/cloud/confluence/advanced-searching-using-cql/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)


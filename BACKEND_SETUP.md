//
//  BackendSetup.md
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//  Инструкции для настройки Backend API
//

# Backend API Setup Instructions

## Обзор

iOS приложение общается с Backend API, который обрабатывает запросы и интегрируется с:
- **Kimi K2 API** - для генерации AI ответов
- **Confluence Cloud API** - для поиска в документации
- **Telegram Bot API** - для интеграции с Telegram (опционально)

## Конфигурация Backend

### 1. Kimi K2 API

```python
# backend/.env
KIMI_API_KEY=sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG
KIMI_BASE_URL=https://api.moonshot.cn/v1/chat/completions
KIMI_MODEL=kimi-k2-turbo-preview
```

### 2. Confluence API

```python
# backend/.env
CONFLUENCE_BASE_URL=https://your-domain.atlassian.net
CONFLUENCE_EMAIL=your-email@m10.az
CONFLUENCE_API_TOKEN=your_confluence_token
CONFLUENCE_SPACE_KEY=M10SUPPORT
```

**Как получить Confluence API Token:**
1. Перейдите в https://id.atlassian.com/manage-profile/security/api-tokens
2. Создайте новый API token
3. Используйте email и токен для Basic Auth

### 3. Telegram Bot (опционально)

```python
# backend/.env
TELEGRAM_BOT_TOKEN=8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA
```

## Backend Endpoints

iOS приложение ожидает следующие endpoints:

### POST /api/v1/chat/ios/session
Создает новую сессию чата.

**Response:**
```json
{
  "session_id": "uuid-123-456"
}
```

### POST /api/v1/chat/ios/message
Отправляет сообщение пользователя.

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

**Response:**
```json
{
  "messages": [
    {
      "id": "uuid-1",
      "text": "BakıKART-a necə pul yükləyə bilərəm?",
      "sender": "user",
      "timestamp": "2025-01-15T10:30:00Z",
      "sources": null
    },
    {
      "id": "uuid-2",
      "text": "Salam! BakıKART-a pul yükləmək çox asandır...",
      "sender": "assistant",
      "timestamp": "2025-01-15T10:30:15Z",
      "sources": [...]
    }
  ]
}
```

## Логика работы Backend

1. **Получение запроса от iOS**
2. **Определение языка** (az/ru/en)
3. **Извлечение сущностей** (NER)
4. **Расширение запроса** (Query Expansion)
5. **Поиск в Confluence** через CQL:
   ```
   space = "M10SUPPORT" AND text ~ "BakıKART pul yükləmə"
   ```
6. **Ранжирование результатов**
7. **Генерация ответа через Kimi K2 API**
8. **Сохранение в MongoDB**
9. **Отправка ответа iOS клиенту**

## Пример запроса к Kimi API (для Backend)

```python
import httpx

async def call_kimi_api(prompt: str, context: str):
    url = "https://api.moonshot.cn/v1/chat/completions"
    
    headers = {
        "Authorization": f"Bearer {KIMI_API_KEY}",
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

## Пример запроса к Confluence API (для Backend)

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
        "Content-Type": "application/json"
    }
    
    params = {
        "cql": f'space = "M10SUPPORT" AND text ~ "{query}"',
        "limit": 10,
        "expand": "body.storage,version,space"
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params, headers=headers)
        return response.json()["results"]
```

## Тестирование

Для тестирования без backend можно использовать mock responses в iOS приложении.

См. `APIService.swift` - там есть комментарии о том, как добавить mock режим.


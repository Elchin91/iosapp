# M10Clone - Full Integration Guide
## iOS App + Backend (Confluence + Kimi AI + Telegram + NER)

> **Полноценная интеграция iOS приложения с мощным AI backend**

---

## 🎯 Что вы получаете

### **iOS Приложение:**
- ✅ AI чат с доступом к Confluence документации
- ✅ Умный поиск по FAQ
- ✅ NER - распознавание сущностей (BakıKART, суммы, даты)
- ✅ Query Expansion - улучшенная обработка запросов
- ✅ Поддержка 3 языков (азербайджанский, русский, английский)
- ✅ Telegram интеграция
- ✅ История всех диалогов в MongoDB

### **Backend возможности:**
- 🔍 **Confluence Search** - поиск в документации в реальном времени
- 🤖 **Kimi K2 AI** - генерация умных ответов
- 📊 **Vector Search (ChromaDB)** - семантический поиск
- 🏷️ **NER Service** - извлечение сущностей из текста
- 📱 **Telegram Bot** - двусторонняя синхронизация
- 💾 **MongoDB** - хранение всей истории
- 🔄 **Hybrid Search** - комбинация векторного и текстового поиска

---

## 📋 Требования

### Software:
- **Python 3.10+** (для backend)
- **MongoDB** (локальный или Atlas)
- **Xcode 15+** (для iOS)
- **Git**

### API Keys (уже настроены):
- ✅ Kimi AI API: `sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG`
- ✅ Telegram Bot: `8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA`
- ✅ Confluence API: настроен в backend

---

## 🚀 Быстрый старт

### Шаг 1: Установить MongoDB

#### Windows:
```powershell
# Скачайте и установите MongoDB Community Server
# https://www.mongodb.com/try/download/community

# Создайте директорию для данных
mkdir C:\data\db

# Запустите MongoDB
mongod --dbpath C:\data\db
```

#### Альтернатива - MongoDB Atlas (бесплатный облачный):
1. Зарегистрируйтесь на https://www.mongodb.com/cloud/atlas
2. Создайте бесплатный кластер
3. Получите connection string
4. Обновите `.env` файл с вашим connection string

---

### Шаг 2: Запустить Backend

```powershell
# Перейдите в папку backend
cd C:\Users\elchi\Desktop\chatnew\backend

# Создайте виртуальное окружение
python -m venv .venv

# Активируйте окружение
.venv\Scripts\activate

# Установите зависимости
pip install -r requirements.txt

# Инициализируйте базу данных
python -m app.db.init_db

# Синхронизируйте Confluence (опционально, но рекомендуется)
# Это загрузит всю документацию из Confluence в vector store
python -c "
import asyncio
from app.services.confluence_service import ConfluenceIngestionService
from app.db.mongodb import connect_to_mongo, close_mongo_connection

async def sync():
    await connect_to_mongo()
    service = ConfluenceIngestionService()
    docs = await service.ingest_space('CARE', force_resync=False)
    print(f'✅ Synced {len(docs)} documents from Confluence')
    await close_mongo_connection()

asyncio.run(sync())
"

# Запустите backend сервер
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend будет доступен на: `http://localhost:8000`

API документация (Swagger): `http://localhost:8000/docs`

---

### Шаг 3: Запустить Telegram Bot (опционально)

В новом терминале:

```powershell
cd C:\Users\elchi\Desktop\chatnew\backend
.venv\Scripts\activate
python start_telegram_bot.py
```

---

### Шаг 4: Собрать и установить iOS приложение

#### Вариант A: Через Xcode (локальная разработка)

```bash
# Перейдите в папку iOS проекта
cd "C:\Users\elchi\Desktop\IOS app\M10Clone"

# Сгенерируйте Xcode проект
xcodegen generate

# Откройте в Xcode
open M10Clone.xcodeproj

# В Xcode:
# 1. Выберите симулятор или устройство
# 2. Нажмите Run (Cmd+R)
```

**ВАЖНО для работы с локальным backend:**
- Если используете симулятор iOS: backend на `localhost:8000` будет работать
- Если используете реальное устройство: замените в `APIConfig.swift`:
  ```swift
  static let baseURL = "http://YOUR_COMPUTER_IP:8000/api/v1"
  ```
  (Узнать IP: `ipconfig` в Windows → IPv4 Address)

#### Вариант B: Через GitHub Actions (для TrollStore)

```powershell
# Закоммитьте изменения
cd "C:\Users\elchi\Desktop\IOS app\M10Clone"
git add .
git commit -m "Integrate with full backend (Confluence + Kimi + NER)"
git push

# Подождите 3-5 минут для сборки
# Скачайте IPA из: https://github.com/Elchin91/iosapp/actions
# Установите через TrollStore
```

---

## 🧪 Тестирование интеграции

### 1. Проверьте backend:

```bash
# Health check
curl http://localhost:8000/api/v1/chat/ios/health

# Ожидаемый ответ:
{
  "status": "healthy",
  "service": "iOS API",
  "features": {
    "confluence": true,
    "kimi_ai": true,
    "ner": true,
    "telegram": true,
    "vector_search": true
  }
}
```

### 2. Проверьте создание сессии:

```bash
curl -X POST http://localhost:8000/api/v1/chat/ios/session

# Ожидаемый ответ:
{
  "sessionId": "..."
}
```

### 3. Отправьте тестовое сообщение:

```bash
curl -X POST http://localhost:8000/api/v1/chat/ios/message \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "YOUR_SESSION_ID",
    "message": "BakıKART haqqında məlumat ver",
    "timestamp": "2025-01-02T10:00:00Z",
    "deviceInfo": {
      "model": "iPhone",
      "osVersion": "16.0",
      "appVersion": "1.0"
    }
  }'
```

### 4. Проверьте iOS приложение:

1. Откройте приложение
2. Перейдите на вкладку "AI Dəstək"
3. Отправьте сообщение: "BakıKART nədir?"
4. Вы должны получить ответ с информацией из Confluence
5. В ответе будут источники (Sources) из документации

---

## 🔄 Как это работает

### Полный поток обработки сообщения:

```
📱 iOS App
   ↓
   Отправляет сообщение на backend
   ↓
🖥️ Backend API (/api/v1/chat/ios/message)
   ↓
   ┌─────────────────────────────────────┐
   │ 1. Определение языка (az/ru/en)    │
   │ 2. NER - извлечение сущностей       │
   │    (BakıKART номера, суммы и т.д.)  │
   │ 3. Query Expansion                  │
   │    (создание вариантов запроса)     │
   └─────────────────────────────────────┘
   ↓
🔍 Hybrid Vector Search
   ┌─────────────────────────────────────┐
   │ • Поиск в Confluence документации   │
   │ • Векторный поиск (семантика)       │
   │ • Текстовый поиск (keywords)        │
   │ • Ранжирование результатов          │
   └─────────────────────────────────────┘
   ↓
🤖 Kimi K2 AI
   ┌─────────────────────────────────────┐
   │ • Получает контекст из Confluence   │
   │ • Генерирует ответ на языке запроса │
   │ • Добавляет источники               │
   └─────────────────────────────────────┘
   ↓
💾 MongoDB
   ┌─────────────────────────────────────┐
   │ • Сохраняет сообщение пользователя  │
   │ • Сохраняет ответ AI                │
   │ • Обновляет историю сессии          │
   └─────────────────────────────────────┘
   ↓
📱 iOS App
   Отображает ответ с источниками
   ↓
📨 Telegram Bot (опционально)
   Дублирует сообщения в Telegram
```

---

## 📊 API Endpoints

### iOS App Endpoints:

#### 1. Create Session
```
POST /api/v1/chat/ios/session
Response: { "sessionId": "..." }
```

#### 2. Send Message
```
POST /api/v1/chat/ios/message
Body: {
  "sessionId": "...",
  "message": "...",
  "timestamp": "...",
  "deviceInfo": {...}
}
Response: {
  "sessionId": "...",
  "messageId": "...",
  "answer": "...",
  "language": "az",
  "sources": [...],
  "timestamp": "...",
  "metadata": {...}
}
```

#### 3. Get History
```
GET /api/v1/chat/ios/history/{sessionId}?limit=50
Response: [
  {
    "id": "...",
    "text": "...",
    "isUser": true/false,
    "timestamp": "...",
    "sources": [...]
  }
]
```

#### 4. Health Check
```
GET /api/v1/chat/ios/health
Response: {
  "status": "healthy",
  "features": {...}
}
```

---

## 🔧 Конфигурация

### Backend (.env файл):

```env
# MongoDB
SUPPORT_AI_MONGODB_URL=mongodb://localhost:27017
SUPPORT_AI_MONGODB_DB_NAME=support_ai

# Confluence
SUPPORT_AI_CONFLUENCE_EMAIL=elchin.abbaszada@pashapay.az
SUPPORT_AI_CONFLUENCE_API_TOKEN=ATATT3xFfGF0fhL0GhqQ55Y4wnUmyEILZJSPVOPkHWvsphe1JZafVc-e9NR_EowUWED7UHlvVbAjt9BtPf1lkzdP-R1bIWxmIDBIw259bi85OFZDhieU6xUWhqy8aDFm08FfFkD85aU8Jm5QaCioEKcP4dmBLYlDkr2xEqlTS47_vpDaCDG3YdU=F6CAF433

# Kimi AI
SUPPORT_AI_KIMI_API_KEY=sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG
SUPPORT_AI_KIMI_BASE_URL=https://api.moonshot.cn/v1/chat/completions
SUPPORT_AI_KIMI_MODEL=kimi-k2-turbo-preview

# Telegram
SUPPORT_AI_TELEGRAM_BOT_TOKEN=8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA
```

### iOS (APIConfig.swift):

```swift
// Debug (локальная разработка)
static let baseURL = "http://localhost:8000/api/v1"

// Production (после деплоя)
static let baseURL = "https://your-backend.railway.app/api/v1"
```

---

## 🐛 Troubleshooting

### Backend не запускается:

**Проблема:** `ModuleNotFoundError: No module named 'app'`
**Решение:** Убедитесь что вы в папке `backend` и активировали venv

**Проблема:** `Connection refused to MongoDB`
**Решение:** Убедитесь что MongoDB запущен (`mongod --dbpath C:\data\db`)

### iOS приложение не подключается:

**Проблема:** "Нет активной сессии"
**Решение:**
1. Проверьте что backend запущен: `curl http://localhost:8000/api/v1/chat/ios/health`
2. Если на реальном устройстве - укажите IP компьютера в APIConfig.swift

**Проблема:** "Network error"
**Решение:**
1. Проверьте firewall (разрешите порт 8000)
2. Убедитесь что устройство и компьютер в одной сети

### Telegram бот не отвечает:

**Проблема:** Бот не реагирует
**Решение:**
1. Проверьте что `start_telegram_bot.py` запущен
2. Проверьте логи на ошибки
3. Убедитесь что токен правильный

---

## 📈 Мониторинг

### Логи backend:

```bash
# В терминале где запущен uvicorn вы увидите:
INFO: 📱 iOS message received - Session: ...
INFO: 📝 Message: BakıKART nədir?
INFO: 🌐 Detected language: az
INFO: 📌 Found entities: [...]
INFO: 🔍 Expanded query into 3 variations
INFO: ✅ Response generated - Language: az
INFO: 📚 Sources found: 2
```

### MongoDB (просмотр данных):

```bash
# Подключитесь к MongoDB
mongosh

# Используйте базу support_ai
use support_ai

# Посмотрите сессии
db.chat_sessions.find().pretty()

# Посмотрите сообщения
db.chat_messages.find().pretty()

# Посмотрите документы из Confluence
db.documents.find().pretty()
```

---

## 🎉 Готово!

Теперь у вас есть полноценное AI-powered iOS приложение с:
- ✅ Confluence документацией
- ✅ Умным AI (Kimi K2)
- ✅ NER и Query Expansion
- ✅ Telegram интеграцией
- ✅ Полной историей в MongoDB

**Наслаждайтесь! 🚀**

---

## 📞 Support

- **Email**: elchin.abbaszada@pashapay.az
- **Confluence**: https://m10payments.atlassian.net/wiki/spaces/CARE
- **GitHub**: https://github.com/Elchin91/iosapp

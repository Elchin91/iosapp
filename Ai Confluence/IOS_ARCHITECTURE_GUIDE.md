# iOS Integration Architecture Guide
## AI-Powered Support System with Direct Confluence Access

> **Документация**: Пошаговое описание логики подключения ИИ, Confluence и системы поддержки для iOS приложения

---

## Оглавление

1. [Общий обзор архитектуры](#общий-обзор-архитектуры)
2. [Ключевые отличия от текущей системы](#ключевые-отличия-от-текущей-системы)
3. [Компоненты системы](#компоненты-системы)
4. [Пошаговая логика работы](#пошаговая-логика-работы)
5. [Детальная реализация для iOS](#детальная-реализация-для-ios)
6. [API интеграции](#api-интеграции)
7. [Схемы данных](#схемы-данных)

---

## Общий обзор архитектуры

### Текущая архитектура (Desktop/Backend)
```
┌─────────────────┐
│  Telegram Bot   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   Backend (FastAPI)                 │
│   ┌──────────────────────────────┐  │
│   │ ConversationService          │  │
│   └───────────┬──────────────────┘  │
│               ▼                     │
│   ┌──────────────────────────────┐  │
│   │ ChatService                  │  │
│   │  - Query Expansion           │  │
│   │  - NER (Entity Recognition)  │  │
│   └───────────┬──────────────────┘  │
│               ▼                     │
│   ┌──────────────────────────────┐  │
│   │ HybridVectorStore            │  │
│   │  - BM25 (Keyword Search)     │  │
│   │  - Semantic Search (Vector)  │  │
│   │  - RRF Fusion                │  │
│   └───────────┬──────────────────┘  │
│               ▼                     │
│   ┌──────────────────────────────┐  │
│   │ Local ChromaDB               │  │
│   │  (Pre-downloaded docs)       │  │
│   └──────────────────────────────┘  │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Kimi AI API    │ (LLM для генерации ответа)
└─────────────────┘

Confluence (синхронизация 1 раз)
```

### Новая архитектура для iOS
```
┌─────────────────┐
│  iOS App        │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│   Backend API (FastAPI)                 │
│   ┌──────────────────────────────────┐  │
│   │ iOS Conversation Endpoint        │  │
│   └───────────┬──────────────────────┘  │
│               ▼                         │
│   ┌──────────────────────────────────┐  │
│   │ Query Processing Service         │  │
│   │  - Language Detection            │  │
│   │  - Query Expansion               │  │
│   │  - NER (Entity Extraction)       │  │
│   └───────────┬──────────────────────┘  │
│               ▼                         │
│   ┌──────────────────────────────────┐  │
│   │ Confluence Search Service        │  │
│   │  - Direct API Search (CQL)       │  │
│   │  - Content Extraction            │  │
│   │  - Relevance Ranking             │  │
│   └───────────┬──────────────────────┘  │
└───────────────┼──────────────────────────┘
                │
     ┌──────────┴──────────┐
     ▼                     ▼
┌─────────────┐    ┌─────────────────┐
│ Confluence  │    │  Kimi AI API    │
│ Cloud API   │    │  (LLM)          │
└─────────────┘    └─────────────────┘
```

---

## Ключевые отличия от текущей системы

### Текущая система (Desktop)
- ✅ **Предзагрузка**: Документы скачиваются заранее в ChromaDB
- ✅ **Локальный поиск**: BM25 + Vector Search по локальной БД
- ❌ **Требует место**: ChromaDB + BM25 индекс на диске
- ❌ **Синхронизация**: Нужно периодически обновлять базу

### iOS система (Новая)
- ✅ **Реал-тайм**: Прямые запросы к Confluence API
- ✅ **Без хранилища**: Не нужна локальная БД на устройстве
- ✅ **Актуальность**: Всегда свежие данные
- ✅ **Легковесность**: Минимальное потребление памяти
- ⚠️ **Требует интернет**: Без подключения не работает

---

## Компоненты системы

### 1. iOS Client (Swift)
```swift
// Основные компоненты
- SupportChatView (UI)
- ConversationViewModel (Business Logic)
- APIService (Network Layer)
- MessageModel (Data Models)
```

### 2. Backend API (Python FastAPI)
```python
# Эндпоинты
POST /api/v1/chat/ios/message
GET  /api/v1/chat/ios/history/{session_id}
POST /api/v1/chat/ios/session

# Сервисы
- iOSConversationService
- ConfluenceRealtimeSearch
- QueryExpander
- AzerbaijaniNER
```

### 3. External Services
- **Confluence Cloud API v2**: Поиск документации
- **Kimi AI API**: Генерация ответов
- **MongoDB**: Хранение истории чатов

---

## Пошаговая логика работы

### Шаг 1: Пользователь отправляет вопрос

**iOS App → Backend**

```swift
// iOS: Отправка сообщения
func sendMessage(_ text: String) async throws {
    let request = ChatRequest(
        sessionId: currentSessionId,
        message: text,
        timestamp: Date()
    )

    let response = try await apiService.sendMessage(request)
    messages.append(response.aiMessage)
}
```

**Backend получает:**
```json
{
  "session_id": "uuid-123-456",
  "message": "BakıKART-a necə pul yükləyə bilərəm?",
  "timestamp": "2025-01-15T10:30:00Z",
  "platform": "ios",
  "device_info": {
    "model": "iPhone 14 Pro",
    "os_version": "17.2"
  }
}
```

---

### Шаг 2: Обработка запроса в Backend

#### 2.1 Определение языка

```python
# backend/app/services/language_detector.py

def detect_language(text: str) -> str:
    """Определяет язык текста"""

    # Азербайджанские специфичные символы
    az_chars = ['ə', 'ı', 'ö', 'ü', 'ğ', 'ç', 'ş']
    az_words = ['necə', 'nədir', 'haqqında', 'hansı']

    # Русские символы
    ru_chars = ['а', 'б', 'в', 'ж', 'з', 'ы', 'э', 'ю', 'я']

    text_lower = text.lower()

    if any(char in text_lower for char in az_chars):
        return "az"
    elif any(char in text_lower for char in ru_chars):
        return "ru"
    else:
        return "en"

# Результат: "az"
```

#### 2.2 Извлечение сущностей (NER)

```python
# backend/app/services/azerbaijani_ner.py

class AzerbaijaniNER:
    async def extract_entities(self, text: str) -> List[Entity]:
        """Извлекает именованные сущности"""

        entities = []

        # Телефонные номера
        phone_pattern = r'\+994\d{9}|\d{2}-\d{3}-\d{2}-\d{2}'
        # Номера карт (маскированные)
        card_pattern = r'\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}'
        # Даты
        date_pattern = r'\d{1,2}[./]\d{1,2}[./]\d{2,4}'

        # Находим BakıKART как ключевое слово
        if 'bakıkart' in text.lower():
            entities.append({
                'type': 'PRODUCT',
                'value': 'BakıKART',
                'confidence': 0.95
            })

        return entities

# Результат:
# [{'type': 'PRODUCT', 'value': 'BakıKART', 'confidence': 0.95}]
```

#### 2.3 Расширение запроса (Query Expansion)

```python
# backend/app/services/query_expander.py

class QueryExpander:
    def expand_with_context(
        self,
        query: str,
        language: str,
        entities: List[Entity]
    ) -> List[str]:
        """Создаёт варианты запроса для лучшего поиска"""

        queries = [query]  # Оригинальный запрос

        # Синонимы и альтернативные формулировки
        if language == "az":
            if 'bakıkart' in query.lower():
                queries.extend([
                    "BakıKART balans artırma",
                    "BakıKART pul yükləmə",
                    "nəqliyyat kartı balans",
                    "avtobus kartı yükləmə"
                ])

            if 'necə' in query.lower():
                # Заменяем "necə" на "как"
                queries.append(query.replace('necə', 'qaydası'))

        elif language == "ru":
            if 'bakıкарт' in query.lower() or 'бакыкарт' in query.lower():
                queries.extend([
                    "пополнение BakıKART",
                    "баланс транспортной карты",
                    "как пополнить BakıKART"
                ])

        return queries

# Результат:
# [
#   "BakıKART-a necə pul yükləyə bilərəm?",
#   "BakıKART balans artırma",
#   "BakıKART pul yükləmə",
#   "nəqliyyat kartı balans",
#   "avtobus kartı yükləmə"
# ]
```

---

### Шаг 3: Поиск в Confluence (ПРЯМОЙ API)

#### 3.1 Формирование CQL запроса

```python
# backend/app/services/confluence_realtime_search.py

class ConfluenceRealtimeSearch:

    async def search_multiple_queries(
        self,
        queries: List[str],
        space_key: str = "M10SUPPORT"
    ) -> List[SearchResult]:
        """Выполняет поиск по всем вариантам запроса"""

        all_results = []
        seen_page_ids = set()

        for query in queries:
            # CQL - Confluence Query Language
            cql = f'space = "{space_key}" AND text ~ "{query}"'

            results = await self._search_confluence(cql)

            for result in results:
                page_id = result['content']['id']
                if page_id not in seen_page_ids:
                    seen_page_ids.add(page_id)
                    all_results.append(result)

        return all_results

    async def _search_confluence(self, cql: str) -> List[Dict]:
        """Прямой запрос к Confluence API"""

        url = f"{CONFLUENCE_BASE_URL}/rest/api/content/search"

        params = {
            "cql": cql,
            "limit": 10,
            "expand": "body.storage,version,space"
        }

        headers = {
            "Authorization": f"Basic {base64_credentials}",
            "Content-Type": "application/json"
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, headers=headers)
            data = response.json()
            return data.get('results', [])

# API Response от Confluence:
# {
#   "results": [
#     {
#       "id": "12345",
#       "type": "page",
#       "title": "BakıKART pul yükləmə təlimatı",
#       "body": {
#         "storage": {
#           "value": "<ac:structured-macro>...</ac:structured-macro>",
#           "representation": "storage"
#         }
#       },
#       "space": {"key": "M10SUPPORT", "name": "M10 Support"},
#       "_links": {
#         "webui": "/spaces/M10SUPPORT/pages/12345"
#       }
#     }
#   ]
# }
```

#### 3.2 Извлечение текста из Confluence HTML

```python
# backend/app/services/confluence_realtime_search.py

async def extract_text_from_page(self, page: Dict) -> str:
    """Извлекает текст из Confluence страницы"""

    body_storage = page.get('body', {}).get('storage', {}).get('value', '')

    if not body_storage:
        return ""

    # Используем BeautifulSoup для парсинга HTML
    soup = BeautifulSoup(body_storage, 'html.parser')

    # Обрабатываем таблицы (важно для тарифов)
    tables = soup.find_all('table')
    text_parts = []

    for table in tables:
        table_data = self._parse_table(table)
        text_parts.append(table_data)

    # Остальной текст
    text_parts.append(soup.get_text(separator='\n', strip=True))

    return '\n\n'.join(text_parts)

def _parse_table(self, table) -> str:
    """Парсит таблицу в структурированный текст"""

    rows = []
    for tr in table.find_all('tr'):
        cells = [td.get_text(strip=True) for td in tr.find_all(['td', 'th'])]
        rows.append(cells)

    # Форматируем для понимания AI
    formatted = []
    for row in rows:
        if len(row) >= 2:
            # Предполагаем: первая колонка = цена, остальные = номера автобусов
            price = row[0]
            buses = ', '.join(row[1:])
            formatted.append(f"Цена: {price} | Автобусы: {buses}")

    return '\n'.join(formatted)

# Результат:
# """
# BakıKART BALANS YÜKLƏMƏ
#
# m10 tətbiqində BakıKART balansını artırmaq çox asandır:
#
# 1. m10 tətbiqini açın
# 2. "Xidmətlər" bölməsinə keçin
# 3. "BakıKART" seçin
# 4. Kart nömrəsini daxil edin
# 5. Məbləği seçin
# 6. "Ödə" düyməsinə toxunun
#
# Minimum məbləğ: 1 AZN
# Maksimum məbləğ: 100 AZN
#
# Цена: 0.30 AZN | Автобусы: 1, 5, 88, 125
# Цена: 0.40 AZN | Автобусы: M8, Q1, 116
# """
```

#### 3.3 Ранжирование результатов

```python
# backend/app/services/confluence_realtime_search.py

async def rank_results(
    self,
    results: List[SearchResult],
    original_query: str,
    entities: List[Entity]
) -> List[RankedResult]:
    """Сортирует результаты по релевантности"""

    scored_results = []

    for result in results:
        score = 0.0
        text = result['extracted_text'].lower()
        title = result['title'].lower()

        # 1. Совпадение в заголовке (высокий вес)
        for word in original_query.lower().split():
            if word in title:
                score += 3.0
            if word in text:
                score += 1.0

        # 2. Совпадение сущностей (средний вес)
        for entity in entities:
            entity_value = entity['value'].lower()
            if entity_value in title:
                score += 5.0
            if entity_value in text:
                score += 2.0

        # 3. Freshness - новые страницы важнее
        version = result.get('version', {}).get('number', 1)
        score += version * 0.1

        scored_results.append({
            'result': result,
            'score': score
        })

    # Сортируем по score
    scored_results.sort(key=lambda x: x['score'], reverse=True)

    return [item['result'] for item in scored_results[:5]]

# Топ-5 релевантных результатов
```

---

### Шаг 4: Генерация ответа через AI

#### 4.1 Построение промпта

```python
# backend/app/services/ai_response_generator.py

class AIResponseGenerator:

    async def generate_answer(
        self,
        question: str,
        context_pages: List[ConfluencePage],
        language: str,
        entities: List[Entity]
    ) -> AIResponse:
        """Генерирует ответ на основе контекста"""

        # Формируем контекст из найденных страниц
        context_parts = []
        for idx, page in enumerate(context_pages[:3]):  # Топ-3
            context_parts.append(
                f"📄 Источник {idx+1}: {page['title']}\n"
                f"{page['text']}\n"
            )

        context_text = '\n\n'.join(context_parts)

        # Создаём промпт в зависимости от языка
        if language == "az":
            system_prompt = self._get_azerbaijani_system_prompt()
            user_prompt = f"""
BAZA (Confluence dokumentasiyası):
{context_text}

MÜŞTƏRİNİN SUALI: {question}

VACIB:
- Yuxarıdakı məlumatdan istifadə edərək dəqiq və faydalı cavab ver
- Real insan kimi danış, texniki terminlər işlətmə
- Əgər məlumat kifayət deyilsə, açıq de
- Addım-addım təlimat ver

CAVAB:
"""
        elif language == "ru":
            system_prompt = self._get_russian_system_prompt()
            user_prompt = f"""
БАЗА ЗНАНИЙ (Документация Confluence):
{context_text}

ВОПРОС КЛИЕНТА: {question}

ВАЖНО:
- Используй информацию выше для точного и полезного ответа
- Общайся как живой человек, без технических терминов
- Если информации недостаточно, скажи честно
- Давай пошаговые инструкции

ОТВЕТ:
"""

        # Вызываем Kimi AI
        response = await self._call_kimi_api(system_prompt, user_prompt)

        return response

    def _get_azerbaijani_system_prompt(self) -> str:
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

    async def _call_kimi_api(
        self,
        system_prompt: str,
        user_prompt: str
    ) -> Dict:
        """Вызов Kimi AI API"""

        url = "https://api.moonshot.cn/v1/chat/completions"

        payload = {
            "model": "moonshot-v1-8k",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        }

        headers = {
            "Authorization": f"Bearer {KIMI_API_KEY}",
            "Content-Type": "application/json"
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload, headers=headers)
            data = response.json()

            answer = data['choices'][0]['message']['content']

            return {
                "answer": answer,
                "model": "moonshot-v1-8k",
                "tokens_used": data['usage']['total_tokens']
            }
```

#### 4.2 Ответ от AI

```text
Salam! BakıKART-a pul yükləmək çox asandır m10 tətbiqində.

İzaham:

1️⃣ m10 tətbiqini açın
2️⃣ Alt menyuda "Xidmətlər" bölməsinə keçin
3️⃣ "BakıKART" xidmətini seçin
4️⃣ Kartınızın 16 rəqəmli nömrəsini daxil edin
5️⃣ Yükləmək istədiyiniz məbləği seçin (minimum 1 AZN, maksimum 100 AZN)
6️⃣ "Ödə" düyməsinə toxunun
7️⃣ Əməliyyat təsdiqlənəcək və pul dərhal kartınıza keçəcək

💡 Faydalı məlumat: Əgər avtobusda 0.30 AZN ödəyirsinizsə, bu 1, 5, 88, 125 nömrəli avtobuslar üçündür. Ekspres marşrutlar (M8, Q1, 116) üçün gediş haqqı 0.40 AZN-dir.

Başqa sualınız varmı? 😊
```

---

### Шаг 5: Сохранение в историю и отправка на iOS

#### 5.1 Сохранение в MongoDB

```python
# backend/app/services/ios_conversation_service.py

async def save_conversation(
    self,
    session_id: str,
    user_message: str,
    ai_response: str,
    context_pages: List[Dict],
    metadata: Dict
) -> ChatMessage:
    """Сохраняет сообщение в MongoDB"""

    message = ChatMessage(
        session_id=session_id,
        user_message=user_message,
        ai_response=ai_response,
        language=metadata['language'],
        entities=metadata['entities'],
        sources=[
            {
                'title': page['title'],
                'url': page['url'],
                'space': page['space']
            }
            for page in context_pages
        ],
        timestamp=datetime.utcnow(),
        platform="ios",
        device_info=metadata.get('device_info')
    )

    await message.insert()
    return message
```

#### 5.2 Формирование ответа для iOS

```python
# backend/app/api/endpoints/ios_chat.py

@router.post("/message")
async def send_message(request: ChatRequest) -> ChatResponse:
    """Обработка сообщения от iOS клиента"""

    # 1. Определяем язык
    language = detect_language(request.message)

    # 2. Извлекаем сущности
    entities = await ner_service.extract_entities(request.message)

    # 3. Расширяем запрос
    queries = query_expander.expand_with_context(
        request.message,
        language,
        entities
    )

    # 4. Ищем в Confluence
    search_results = await confluence_search.search_multiple_queries(
        queries,
        space_key="M10SUPPORT"
    )

    # 5. Ранжируем
    ranked_results = await confluence_search.rank_results(
        search_results,
        request.message,
        entities
    )

    # 6. Генерируем ответ через AI
    ai_response = await ai_generator.generate_answer(
        question=request.message,
        context_pages=ranked_results,
        language=language,
        entities=entities
    )

    # 7. Сохраняем в историю
    await conversation_service.save_conversation(
        session_id=request.session_id,
        user_message=request.message,
        ai_response=ai_response['answer'],
        context_pages=ranked_results,
        metadata={
            'language': language,
            'entities': entities,
            'device_info': request.device_info
        }
    )

    # 8. Формируем ответ
    return ChatResponse(
        session_id=request.session_id,
        message_id=str(uuid.uuid4()),
        answer=ai_response['answer'],
        language=language,
        sources=[
            {
                'title': page['title'],
                'url': page['url'],
                'excerpt': page['text'][:200]
            }
            for page in ranked_results
        ],
        timestamp=datetime.utcnow(),
        metadata={
            'tokens_used': ai_response.get('tokens_used'),
            'model': ai_response.get('model'),
            'confidence': calculate_confidence(ranked_results)
        }
    )
```

#### 5.3 JSON ответ для iOS

```json
{
  "session_id": "uuid-123-456",
  "message_id": "msg-789-012",
  "answer": "Salam! BakıKART-a pul yükləmək çox asandır m10 tətbiqində...",
  "language": "az",
  "sources": [
    {
      "title": "BakıKART pul yükləmə təlimatı",
      "url": "https://confluence.m10.az/spaces/M10SUPPORT/pages/12345",
      "excerpt": "m10 tətbiqində BakıKART balansını artırmaq çox asandır..."
    }
  ],
  "timestamp": "2025-01-15T10:30:15Z",
  "metadata": {
    "tokens_used": 450,
    "model": "moonshot-v1-8k",
    "confidence": 0.92
  }
}
```

---

### Шаг 6: Отображение в iOS приложении

```swift
// iOS: Обработка ответа
func handleResponse(_ response: ChatResponse) {
    // Добавляем сообщение пользователя
    messages.append(Message(
        id: UUID(),
        text: currentUserMessage,
        sender: .user,
        timestamp: Date()
    ))

    // Добавляем ответ AI
    messages.append(Message(
        id: UUID(uuidString: response.messageId) ?? UUID(),
        text: response.answer,
        sender: .assistant,
        timestamp: response.timestamp,
        sources: response.sources.map { source in
            MessageSource(
                title: source.title,
                url: URL(string: source.url),
                excerpt: source.excerpt
            )
        }
    ))

    // Обновляем UI
    scrollToBottom()
}
```

---

## Детальная реализация для iOS

### Структура проекта

```
M10SupportApp/
├── App/
│   ├── M10SupportApp.swift
│   └── AppDelegate.swift
├── Models/
│   ├── Message.swift
│   ├── ChatSession.swift
│   ├── ChatRequest.swift
│   └── ChatResponse.swift
├── ViewModels/
│   └── ConversationViewModel.swift
├── Views/
│   ├── ChatView.swift
│   ├── MessageRow.swift
│   └── SourcesListView.swift
├── Services/
│   ├── APIService.swift
│   ├── NetworkManager.swift
│   └── KeychainManager.swift
└── Utilities/
    ├── Extensions.swift
    └── Constants.swift
```

### Models (Data Models)

```swift
// Models/Message.swift

import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let text: String
    let sender: MessageSender
    let timestamp: Date
    var sources: [MessageSource]?

    enum MessageSender: String, Codable {
        case user
        case assistant
    }
}

struct MessageSource: Identifiable, Codable {
    let id = UUID()
    let title: String
    let url: URL?
    let excerpt: String?
}

// Models/ChatRequest.swift

struct ChatRequest: Codable {
    let sessionId: String
    let message: String
    let timestamp: Date
    let platform: String = "ios"
    let deviceInfo: DeviceInfo

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case message
        case timestamp
        case platform
        case deviceInfo = "device_info"
    }
}

struct DeviceInfo: Codable {
    let model: String
    let osVersion: String
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case model
        case osVersion = "os_version"
        case appVersion = "app_version"
    }
}

// Models/ChatResponse.swift

struct ChatResponse: Codable {
    let sessionId: String
    let messageId: String
    let answer: String
    let language: String
    let sources: [SourceInfo]
    let timestamp: Date
    let metadata: ResponseMetadata

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case messageId = "message_id"
        case answer
        case language
        case sources
        case timestamp
        case metadata
    }
}

struct SourceInfo: Codable {
    let title: String
    let url: String
    let excerpt: String
}

struct ResponseMetadata: Codable {
    let tokensUsed: Int?
    let model: String?
    let confidence: Double?

    enum CodingKeys: String, CodingKey {
        case tokensUsed = "tokens_used"
        case model
        case confidence
    }
}
```

### API Service

```swift
// Services/APIService.swift

import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(Int, String)
}

class APIService {
    static let shared = APIService()

    private let baseURL = "https://api.m10support.com/api/v1"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Chat Methods

    func sendMessage(_ request: ChatRequest) async throws -> ChatResponse {
        let url = try buildURL(endpoint: "/chat/ios/message")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Добавляем авторизацию если нужно
        if let token = KeychainManager.shared.getAuthToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Кодируем request
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(request)

        // Выполняем запрос
        let (data, response) = try await session.data(for: urlRequest)

        // Проверяем ответ
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, errorMessage)
        }

        // Декодируем ответ
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(ChatResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func createSession() async throws -> String {
        let url = try buildURL(endpoint: "/chat/ios/session")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        struct SessionResponse: Codable {
            let sessionId: String

            enum CodingKeys: String, CodingKey {
                case sessionId = "session_id"
            }
        }

        let sessionResponse = try JSONDecoder().decode(SessionResponse.self, from: data)
        return sessionResponse.sessionId
    }

    func getChatHistory(sessionId: String) async throws -> [Message] {
        let url = try buildURL(endpoint: "/chat/ios/history/\(sessionId)")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        struct HistoryResponse: Codable {
            let messages: [Message]
        }

        let historyResponse = try JSONDecoder().decode(HistoryResponse.self, from: data)
        return historyResponse.messages
    }

    // MARK: - Helper Methods

    private func buildURL(endpoint: String) throws -> URL {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        return url
    }
}
```

### ViewModel (Business Logic)

```swift
// ViewModels/ConversationViewModel.swift

import Foundation
import Combine

@MainActor
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sessionId: String?

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        Task {
            await createNewSession()
        }
    }

    // MARK: - Public Methods

    func createNewSession() async {
        do {
            let newSessionId = try await apiService.createSession()
            self.sessionId = newSessionId
            print("✅ New session created: \(newSessionId)")
        } catch {
            self.errorMessage = "Failed to create session: \(error.localizedDescription)"
            print("❌ Session creation error: \(error)")
        }
    }

    func sendMessage(_ text: String) async {
        guard let sessionId = sessionId else {
            errorMessage = "No active session"
            return
        }

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Добавляем сообщение пользователя
        let userMessage = Message(
            id: UUID(),
            text: text,
            sender: .user,
            timestamp: Date()
        )
        messages.append(userMessage)

        isLoading = true
        errorMessage = nil

        do {
            // Создаём запрос
            let request = ChatRequest(
                sessionId: sessionId,
                message: text,
                timestamp: Date(),
                deviceInfo: getDeviceInfo()
            )

            // Отправляем на сервер
            let response = try await apiService.sendMessage(request)

            // Создаём сообщение от ассистента
            let assistantMessage = Message(
                id: UUID(uuidString: response.messageId) ?? UUID(),
                text: response.answer,
                sender: .assistant,
                timestamp: response.timestamp,
                sources: response.sources.map { source in
                    MessageSource(
                        title: source.title,
                        url: URL(string: source.url),
                        excerpt: source.excerpt
                    )
                }
            )

            messages.append(assistantMessage)

        } catch let error as APIError {
            handleAPIError(error)
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadHistory() async {
        guard let sessionId = sessionId else { return }

        do {
            let history = try await apiService.getChatHistory(sessionId: sessionId)
            self.messages = history
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    // MARK: - Private Methods

    private func getDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current

        return DeviceInfo(
            model: device.model,
            osVersion: device.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }

    private func handleAPIError(_ error: APIError) {
        switch error {
        case .invalidURL:
            errorMessage = "Invalid API URL"
        case .networkError(let error):
            errorMessage = "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            errorMessage = "Invalid server response"
        case .decodingError(let error):
            errorMessage = "Failed to parse response: \(error.localizedDescription)"
        case .serverError(let code, let message):
            errorMessage = "Server error (\(code)): \(message)"
        }
    }
}
```

### Views (UI Components)

```swift
// Views/ChatView.swift

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ConversationViewModel()
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageRow(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isLoading {
                                LoadingMessageView()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                // Input Field
                MessageInputView(
                    text: $messageText,
                    isFocused: $isTextFieldFocused,
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.sendMessage(messageText)
                        messageText = ""
                    }
                }
            }
            .navigationTitle("m10 Dəstək")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Views/MessageRow.swift

struct MessageRow: View {
    let message: Message

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }

            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(message.sender == .user ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.sender == .user ? .white : .primary)
                    .cornerRadius(16)

                if let sources = message.sources, !sources.isEmpty {
                    SourcesView(sources: sources)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.sender == .user ? .trailing : .leading)

            if message.sender == .assistant {
                Spacer()
            }
        }
    }
}

struct SourcesView: View {
    let sources: [MessageSource]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Источники:")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(sources) { source in
                if let url = source.url {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            Text(source.title)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MessageInputView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Sualınızı yazın...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused(isFocused)
                .disabled(isLoading)

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(text.isEmpty || isLoading ? Color.gray : Color.blue)
                    .clipShape(Circle())
            }
            .disabled(text.isEmpty || isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct LoadingMessageView: View {
    var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Cavab hazırlanır...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
    }
}
```

---

## API интеграции

### Backend Endpoints для iOS

```python
# backend/app/api/endpoints/ios_chat.py

from fastapi import APIRouter, HTTPException, Depends
from typing import List
from datetime import datetime
import uuid

from app.schemas.ios_chat import (
    ChatRequest,
    ChatResponse,
    SessionCreateResponse,
    HistoryResponse
)
from app.services.ios_conversation_service import iOSConversationService
from app.core.auth import get_current_user  # Если нужна аутентификация

router = APIRouter(prefix="/chat/ios", tags=["iOS Chat"])

@router.post("/session", response_model=SessionCreateResponse)
async def create_session(
    user_id: str | None = Depends(get_current_user)
):
    """Создать новую сессию чата для iOS клиента"""

    session_id = str(uuid.uuid4())

    # Сохраняем сессию в MongoDB
    from app.models.chat import ChatSession
    session = ChatSession(
        id=session_id,
        channel="ios",
        external_chat_id=session_id,
        customer_id=user_id,
        created_at=datetime.utcnow()
    )
    await session.insert()

    return SessionCreateResponse(session_id=session_id)


@router.post("/message", response_model=ChatResponse)
async def send_message(
    request: ChatRequest,
    user_id: str | None = Depends(get_current_user)
):
    """Обработать сообщение от iOS клиента"""

    service = iOSConversationService()

    try:
        response = await service.process_message(
            session_id=request.session_id,
            message=request.message,
            device_info=request.device_info,
            user_id=user_id
        )

        return response

    except Exception as e:
        logger.exception(f"Error processing message: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/history/{session_id}", response_model=HistoryResponse)
async def get_chat_history(
    session_id: str,
    limit: int = 50,
    user_id: str | None = Depends(get_current_user)
):
    """Получить историю чата"""

    from app.models.chat import ChatMessage

    messages = await ChatMessage.find(
        ChatMessage.session_id == session_id
    ).sort(-ChatMessage.created_at).limit(limit).to_list()

    # Преобразуем в нужный формат
    formatted_messages = [
        {
            "id": str(msg.id),
            "text": msg.content,
            "sender": "user" if msg.sender == "CLIENT" else "assistant",
            "timestamp": msg.created_at,
            "sources": msg.extra.get("sources", []) if msg.extra else []
        }
        for msg in reversed(messages)
    ]

    return HistoryResponse(messages=formatted_messages)
```

### Schemas (Pydantic Models)

```python
# backend/app/schemas/ios_chat.py

from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

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

class SessionCreateResponse(BaseModel):
    session_id: str

class MessageHistory(BaseModel):
    id: str
    text: str
    sender: str  # "user" or "assistant"
    timestamp: datetime
    sources: Optional[List[SourceInfo]] = None

class HistoryResponse(BaseModel):
    messages: List[MessageHistory]
```

---

## Схемы данных

### MongoDB Collections

```javascript
// Collection: chat_sessions
{
  "_id": ObjectId("..."),
  "id": "uuid-123-456",
  "channel": "ios",
  "external_chat_id": "uuid-123-456",
  "customer_id": "user-789",
  "customer_name": "Elchin Huseynov",
  "created_at": ISODate("2025-01-15T10:00:00Z"),
  "updated_at": ISODate("2025-01-15T10:30:00Z"),
  "status": "active",  // active | closed
  "platform_info": {
    "platform": "ios",
    "device_model": "iPhone 14 Pro",
    "os_version": "17.2",
    "app_version": "1.0.0"
  }
}

// Collection: chat_messages
{
  "_id": ObjectId("..."),
  "session_id": "uuid-123-456",
  "message_id": "msg-789-012",
  "sender": "CLIENT",  // CLIENT | ASSISTANT
  "content": "BakıKART-a necə pul yükləyə bilərəm?",
  "language": "az",
  "entities": [
    {
      "type": "PRODUCT",
      "value": "BakıKART",
      "confidence": 0.95
    }
  ],
  "extra": {
    "sources": [
      {
        "title": "BakıKART pul yükləmə təlimatı",
        "url": "https://confluence.m10.az/...",
        "space": "M10SUPPORT"
      }
    ],
    "context_pages": [...],
    "ai_metadata": {
      "model": "moonshot-v1-8k",
      "tokens_used": 450,
      "confidence": 0.92
    }
  },
  "created_at": ISODate("2025-01-15T10:30:00Z")
}
```

---

## Диаграмма последовательности (Sequence Diagram)

```
┌─────┐          ┌─────────┐          ┌──────────┐          ┌───────────┐          ┌─────────┐
│ iOS │          │ Backend │          │Confluence│          │  Kimi AI  │          │ MongoDB │
│ App │          │   API   │          │   API    │          │    API    │          │   DB    │
└──┬──┘          └────┬────┘          └────┬─────┘          └─────┬─────┘          └────┬────┘
   │                  │                     │                      │                     │
   │ 1. POST /message │                     │                      │                     │
   │─────────────────>│                     │                      │                     │
   │                  │                     │                      │                     │
   │                  │ 2. Language Detect  │                      │                     │
   │                  │     + NER Extract   │                      │                     │
   │                  │────────┐            │                      │                     │
   │                  │        │            │                      │                     │
   │                  │<───────┘            │                      │                     │
   │                  │                     │                      │                     │
   │                  │ 3. Query Expansion  │                      │                     │
   │                  │────────┐            │                      │                     │
   │                  │        │            │                      │                     │
   │                  │<───────┘            │                      │                     │
   │                  │                     │                      │                     │
   │                  │ 4. Search (CQL)     │                      │                     │
   │                  │────────────────────>│                      │                     │
   │                  │                     │                      │                     │
   │                  │ 5. Search Results   │                      │                     │
   │                  │<────────────────────│                      │                     │
   │                  │                     │                      │                     │
   │                  │ 6. Extract & Rank   │                      │                     │
   │                  │────────┐            │                      │                     │
   │                  │        │            │                      │                     │
   │                  │<───────┘            │                      │                     │
   │                  │                     │                      │                     │
   │                  │ 7. Generate Answer  │                      │                     │
   │                  │───────────────────────────────────────────>│                     │
   │                  │                     │                      │                     │
   │                  │ 8. AI Response      │                      │                     │
   │                  │<───────────────────────────────────────────│                     │
   │                  │                     │                      │                     │
   │                  │ 9. Save to DB       │                      │                     │
   │                  │────────────────────────────────────────────────────────────────>│
   │                  │                     │                      │                     │
   │                  │ 10. Saved           │                      │                     │
   │                  │<────────────────────────────────────────────────────────────────│
   │                  │                     │                      │                     │
   │ 11. ChatResponse │                     │                      │                     │
   │<─────────────────│                     │                      │                     │
   │                  │                     │                      │                     │
```

---

## Конфигурация и переменные окружения

### Backend (.env)

```bash
# Confluence API
CONFLUENCE_BASE_URL=https://your-domain.atlassian.net
CONFLUENCE_EMAIL=support@m10.az
CONFLUENCE_API_TOKEN=your_confluence_token_here
CONFLUENCE_SPACE_KEY=M10SUPPORT

# Kimi AI API
KIMI_API_KEY=your_kimi_api_key_here
KIMI_BASE_URL=https://api.moonshot.cn/v1/chat/completions
KIMI_MODEL=moonshot-v1-8k

# MongoDB
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB=m10_support

# API Settings
API_PREFIX=/api/v1
CORS_ORIGINS=*  # В продакшене указать конкретные домены

# iOS Specific
IOS_MIN_VERSION=1.0.0
IOS_MAX_SESSIONS_PER_USER=5
```

### iOS (Config.swift)

```swift
// Config.swift

struct AppConfig {
    static let apiBaseURL = "https://api.m10support.com/api/v1"

    #if DEBUG
    static let isDebugMode = true
    static let logLevel = "verbose"
    #else
    static let isDebugMode = false
    static let logLevel = "error"
    #endif

    // Timeouts
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60

    // Chat Settings
    static let maxMessageLength = 500
    static let maxHistoryMessages = 100
}
```

---

## Заключение

Эта архитектура обеспечивает:

1. **Прямой доступ к Confluence**: Нет необходимости в локальном хранилище
2. **Актуальные данные**: Всегда свежая информация из документации
3. **Легковесность**: Минимальное потребление ресурсов iOS устройства
4. **Масштабируемость**: Backend обрабатывает всю тяжёлую работу
5. **Безопасность**: Все API ключи на сервере
6. **Многоязычность**: Поддержка азербайджанского, русского и английского

### Следующие шаги для внедрения:

1. ✅ Изучить текущий backend код
2. ⏳ Создать новые endpoints для iOS
3. ⏳ Реализовать Confluence realtime search service
4. ⏳ Настроить iOS проект с network layer
5. ⏳ Протестировать интеграцию
6. ⏳ Оптимизировать производительность
7. ⏳ Deploy на production

Успехов в разработке! 🚀

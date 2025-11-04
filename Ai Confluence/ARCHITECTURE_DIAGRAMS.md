# Architecture Diagrams
## Визуальные схемы системы AI Support

---

## 1. Общая архитектура системы

```mermaid
graph TB
    subgraph "Client Layer"
        iOS[iOS App<br/>Swift/SwiftUI]
        Web[Web App<br/>React]
        TG[Telegram Bot]
    end

    subgraph "API Gateway"
        FastAPI[FastAPI Backend<br/>Python]
    end

    subgraph "Business Logic"
        ConvService[Conversation Service]
        QueryExp[Query Expander]
        NER[NER Service<br/>Entity Recognition]
        ConfSearch[Confluence Search<br/>Realtime API]
    end

    subgraph "External Services"
        ConfAPI[Confluence Cloud API<br/>Documentation]
        KimiAI[Kimi AI API<br/>LLM]
    end

    subgraph "Data Storage"
        MongoDB[(MongoDB<br/>Chat History)]
    end

    iOS --> FastAPI
    Web --> FastAPI
    TG --> FastAPI

    FastAPI --> ConvService
    ConvService --> QueryExp
    ConvService --> NER
    ConvService --> ConfSearch

    ConfSearch --> ConfAPI
    ConvService --> KimiAI
    ConvService --> MongoDB

    style iOS fill:#007AFF
    style FastAPI fill:#009688
    style ConfAPI fill:#0052CC
    style KimiAI fill:#8B5CF6
    style MongoDB fill:#47A248
```

---

## 2. Поток обработки сообщения

```mermaid
sequenceDiagram
    participant U as iOS User
    participant A as iOS App
    participant API as Backend API
    participant Q as Query Processor
    participant C as Confluence API
    participant AI as Kimi AI
    participant DB as MongoDB

    U->>A: Вводит вопрос
    A->>API: POST /chat/ios/message

    API->>Q: Обработать запрос

    Note over Q: 1. Language Detection<br/>2. NER Extraction<br/>3. Query Expansion

    Q->>Q: Определяет язык (az/ru/en)
    Q->>Q: Извлекает сущности (NER)
    Q->>Q: Создаёт варианты запроса

    loop Для каждого варианта
        Q->>C: CQL Search Query
        C-->>Q: Search Results
    end

    Q->>Q: Ранжирует результаты
    Q->>AI: Generate Answer + Context
    AI-->>Q: AI Response

    Q->>DB: Сохранить в историю
    DB-->>Q: Saved

    Q-->>API: ChatResponse
    API-->>A: JSON Response
    A->>U: Отображает ответ + источники
```

---

## 3. Архитектура iOS приложения

```mermaid
graph LR
    subgraph "Views"
        CV[ChatView]
        MB[MessageBubble]
        IB[InputBar]
        SV[SourcesView]
    end

    subgraph "ViewModels"
        CVM[ChatViewModel<br/>@StateObject]
    end

    subgraph "Services"
        API[APIService<br/>Singleton]
        NM[NetworkManager]
    end

    subgraph "Models"
        MSG[Message]
        SRC[MessageSource]
        REQ[ChatRequest]
        RES[ChatResponse]
    end

    CV --> CVM
    MB --> MSG
    IB --> CVM
    SV --> SRC

    CVM --> API
    API --> NM
    API --> REQ
    API --> RES

    CVM --> MSG

    style CV fill:#007AFF
    style CVM fill:#FF9500
    style API fill:#34C759
    style MSG fill:#AF52DE
```

---

## 4. Компоненты Backend для iOS

```mermaid
graph TD
    subgraph "iOS Endpoints"
        ES[POST /chat/ios/session<br/>Создать сессию]
        EM[POST /chat/ios/message<br/>Отправить сообщение]
        EH[GET /chat/ios/history<br/>История чата]
    end

    subgraph "iOS Service Layer"
        ICS[iOSConversationService]
    end

    subgraph "Core Services"
        LD[LanguageDetector]
        NE[NERService]
        QE[QueryExpander]
        CS[ConfluenceSearch]
        AG[AIGenerator]
    end

    ES --> ICS
    EM --> ICS
    EH --> ICS

    ICS --> LD
    ICS --> NE
    ICS --> QE
    ICS --> CS
    ICS --> AG

    style ES fill:#5856D6
    style EM fill:#5856D6
    style EH fill:#5856D6
    style ICS fill:#FF9500
```

---

## 5. Процесс работы с Confluence API

```mermaid
graph TB
    Q[User Query:<br/>"BakıKART-a necə pul yükləyə bilərəm?"]

    subgraph "Query Processing"
        LD[Language Detection<br/>→ az]
        NER[NER Extraction<br/>→ BakıKART]
        EXP[Query Expansion]
    end

    subgraph "Expanded Queries"
        Q1["BakıKART-a necə pul yükləyə bilərəm?"]
        Q2["BakıKART balans artırma"]
        Q3["BakıKART pul yükləmə"]
        Q4["nəqliyyat kartı balans"]
    end

    subgraph "Confluence Search"
        CQL1[CQL: space = M10SUPPORT AND text ~ query1]
        CQL2[CQL: space = M10SUPPORT AND text ~ query2]
        CQL3[CQL: space = M10SUPPORT AND text ~ query3]
        CQL4[CQL: space = M10SUPPORT AND text ~ query4]
    end

    subgraph "Results Processing"
        R[Confluence Results]
        EXT[Extract Text from HTML]
        RANK[Rank by Relevance]
        TOP[Top 5 Results]
    end

    Q --> LD
    LD --> NER
    NER --> EXP

    EXP --> Q1
    EXP --> Q2
    EXP --> Q3
    EXP --> Q4

    Q1 --> CQL1
    Q2 --> CQL2
    Q3 --> CQL3
    Q4 --> CQL4

    CQL1 --> R
    CQL2 --> R
    CQL3 --> R
    CQL4 --> R

    R --> EXT
    EXT --> RANK
    RANK --> TOP

    style Q fill:#007AFF
    style TOP fill:#34C759
```

---

## 6. AI Response Generation Flow

```mermaid
graph LR
    subgraph "Input"
        UQ[User Question]
        CTX[Context from Confluence<br/>Top 5 Pages]
        ENT[Extracted Entities]
        LANG[Language: az/ru/en]
    end

    subgraph "Prompt Building"
        SYS[System Prompt<br/>Role: Support Agent]
        USR[User Prompt<br/>Question + Context]
    end

    subgraph "AI API"
        KIMI[Kimi AI<br/>moonshot-v1-8k]
    end

    subgraph "Response"
        ANS[AI Answer]
        META[Metadata<br/>tokens, confidence]
    end

    UQ --> USR
    CTX --> USR
    ENT --> USR
    LANG --> SYS

    SYS --> KIMI
    USR --> KIMI

    KIMI --> ANS
    KIMI --> META

    style KIMI fill:#8B5CF6
    style ANS fill:#34C759
```

---

## 7. Data Models (iOS)

```mermaid
classDiagram
    class Message {
        +UUID id
        +String text
        +MessageSender sender
        +Date timestamp
        +[MessageSource]? sources
    }

    class MessageSender {
        <<enumeration>>
        user
        assistant
    }

    class MessageSource {
        +UUID id
        +String title
        +URL? url
        +String? excerpt
    }

    class ChatRequest {
        +String sessionId
        +String message
        +Date timestamp
        +String platform
        +DeviceInfo deviceInfo
    }

    class ChatResponse {
        +String sessionId
        +String messageId
        +String answer
        +String language
        +[SourceInfo] sources
        +Date timestamp
        +ResponseMetadata metadata
    }

    class DeviceInfo {
        +String model
        +String osVersion
        +String appVersion
        +current() DeviceInfo
    }

    Message --> MessageSender
    Message --> MessageSource
    ChatRequest --> DeviceInfo
    ChatResponse --> SourceInfo
    ChatResponse --> ResponseMetadata
```

---

## 8. State Management (iOS)

```mermaid
stateDiagram-v2
    [*] --> Initializing: App Launch

    Initializing --> CreatingSession: Create Session
    CreatingSession --> Ready: Session Created
    CreatingSession --> Error: Session Failed

    Ready --> SendingMessage: User Sends Message
    SendingMessage --> WaitingResponse: Message Sent
    WaitingResponse --> Ready: Response Received
    WaitingResponse --> Error: API Error

    Error --> Ready: Retry Success
    Error --> [*]: User Closes App

    Ready --> [*]: User Closes App
```

---

## 9. Error Handling Flow

```mermaid
graph TD
    API[API Call]

    API --> S{Success?}

    S -->|Yes| DECODE{Decode OK?}
    S -->|No| CHECK{Status Code?}

    CHECK -->|400-499| CLIENT[Client Error]
    CHECK -->|500-599| SERVER[Server Error]
    CHECK -->|Network| NETWORK[Network Error]

    DECODE -->|Yes| SUCCESS[✅ Success]
    DECODE -->|No| PARSE[Parse Error]

    CLIENT --> RETRY{Retryable?}
    SERVER --> RETRY
    NETWORK --> RETRY
    PARSE --> RETRY

    RETRY -->|Yes| SHOW_RETRY[Show Retry Button]
    RETRY -->|No| SHOW_ERROR[Show Error Message]

    SHOW_RETRY --> USER_RETRY{User Retries?}
    USER_RETRY -->|Yes| API
    USER_RETRY -->|No| END[End]

    SHOW_ERROR --> END
    SUCCESS --> END

    style SUCCESS fill:#34C759
    style CLIENT fill:#FF9500
    style SERVER fill:#FF3B30
    style NETWORK fill:#FF9500
```

---

## 10. MongoDB Collections Schema

```mermaid
erDiagram
    CHAT_SESSION ||--o{ CHAT_MESSAGE : contains

    CHAT_SESSION {
        ObjectId _id PK
        String id "UUID"
        String channel "ios|telegram|web"
        String external_chat_id
        String customer_id
        String customer_name
        DateTime created_at
        DateTime updated_at
        String status "active|closed"
        Object platform_info
    }

    CHAT_MESSAGE {
        ObjectId _id PK
        String session_id FK
        String message_id "UUID"
        String sender "CLIENT|ASSISTANT"
        String content
        String language "az|ru|en"
        Array entities
        Object extra
        DateTime created_at
    }

    MESSAGE_EXTRA {
        Array sources
        Array context_pages
        Object ai_metadata
    }

    CHAT_MESSAGE ||--|| MESSAGE_EXTRA : has
```

---

## 11. Confluence API Integration

```mermaid
graph TB
    subgraph "Search Request"
        CQL[CQL Query<br/>space = M10SUPPORT AND text ~ BakıKART]
    end

    subgraph "Confluence API"
        API[GET /rest/api/content/search]
        PARAMS[params:<br/>- cql<br/>- limit: 10<br/>- expand: body.storage]
    end

    subgraph "Response Processing"
        RES[JSON Response]
        PAGES[Page Results]
        EXTRACT[Extract HTML Body]
        PARSE[Parse HTML<br/>BeautifulSoup]
        TEXT[Plain Text]
    end

    subgraph "Special Handling"
        TABLES[Table Detection]
        IMAGES[Image Detection]
        FORMAT[Format for AI]
    end

    CQL --> API
    PARAMS --> API

    API --> RES
    RES --> PAGES
    PAGES --> EXTRACT
    EXTRACT --> PARSE

    PARSE --> TABLES
    PARSE --> IMAGES
    PARSE --> TEXT

    TABLES --> FORMAT
    IMAGES --> FORMAT
    TEXT --> FORMAT

    style API fill:#0052CC
    style FORMAT fill:#34C759
```

---

## 12. Deployment Architecture

```mermaid
graph TB
    subgraph "Production Environment"
        subgraph "Client Apps"
            IOS[iOS App<br/>App Store]
            WEB[Web App<br/>Vercel/Netlify]
            TG[Telegram Bot<br/>Telegram API]
        end

        subgraph "Backend Services"
            LB[Load Balancer<br/>Nginx]
            API1[FastAPI Instance 1]
            API2[FastAPI Instance 2]
            API3[FastAPI Instance 3]
        end

        subgraph "Databases"
            MONGO_PRIMARY[(MongoDB Primary)]
            MONGO_REPLICA[(MongoDB Replica)]
        end

        subgraph "External APIs"
            CONFLUENCE[Confluence Cloud]
            KIMI[Kimi AI]
        end

        subgraph "Monitoring"
            LOGS[Logging<br/>ELK Stack]
            METRICS[Metrics<br/>Prometheus]
            ALERTS[Alerts<br/>PagerDuty]
        end
    end

    IOS --> LB
    WEB --> LB
    TG --> LB

    LB --> API1
    LB --> API2
    LB --> API3

    API1 --> MONGO_PRIMARY
    API2 --> MONGO_PRIMARY
    API3 --> MONGO_PRIMARY

    MONGO_PRIMARY --> MONGO_REPLICA

    API1 --> CONFLUENCE
    API1 --> KIMI
    API2 --> CONFLUENCE
    API2 --> KIMI
    API3 --> CONFLUENCE
    API3 --> KIMI

    API1 --> LOGS
    API2 --> LOGS
    API3 --> LOGS

    LOGS --> METRICS
    METRICS --> ALERTS

    style LB fill:#FF9500
    style MONGO_PRIMARY fill:#47A248
    style CONFLUENCE fill:#0052CC
    style KIMI fill:#8B5CF6
```

---

## Пояснения к диаграммам

### Диаграмма 1: Общая архитектура
Показывает все компоненты системы и их взаимодействие на высоком уровне.

### Диаграмма 2: Sequence Diagram
Демонстрирует пошаговый поток обработки одного сообщения от пользователя до получения ответа.

### Диаграмма 3: iOS Architecture
Детализирует структуру iOS приложения по паттерну MVVM.

### Диаграмма 4: Backend Components
Показывает специфичные для iOS эндпоинты и сервисы.

### Диаграмма 5: Confluence Processing
Объясняет как работает расширение запроса и поиск в Confluence.

### Диаграмма 6: AI Flow
Показывает процесс генерации ответа через Kimi AI.

### Диаграмма 7: Data Models
UML диаграмма классов для iOS моделей данных.

### Диаграмма 8: State Management
Диаграмма состояний приложения.

### Диаграмма 9: Error Handling
Логика обработки ошибок и retry механизм.

### Диаграмма 10: Database Schema
ER диаграмма MongoDB коллекций.

### Диаграмма 11: Confluence Integration
Детали работы с Confluence API.

### Диаграмма 12: Production Deployment
Архитектура продакшн окружения с масштабированием.

---

## Использование диаграмм

Эти диаграммы можно:
- Просматривать в GitHub (автоматический рендеринг Mermaid)
- Экспортировать в изображения через [Mermaid Live Editor](https://mermaid.live/)
- Вставлять в презентации
- Использовать для документации API
- Показывать новым разработчикам для быстрого onboarding

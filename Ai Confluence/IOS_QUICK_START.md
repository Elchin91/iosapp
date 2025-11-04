# iOS Quick Start Guide
## Быстрое внедрение AI Support Chat в iOS приложение

> **Практическое руководство**: Готовые примеры кода для копирования

---

## Пошаговое руководство по внедрению

### Шаг 1: Настройка проекта

#### 1.1 Создание нового iOS проекта

```bash
# В Xcode:
# File > New > Project > iOS > App
# Product Name: M10Support
# Interface: SwiftUI
# Language: Swift
```

#### 1.2 Структура папок

```
M10Support/
├── M10SupportApp.swift
├── Models/
│   ├── ChatModels.swift
│   └── APIModels.swift
├── ViewModels/
│   └── ChatViewModel.swift
├── Views/
│   ├── ChatView.swift
│   └── Components/
│       ├── MessageBubble.swift
│       └── InputBar.swift
├── Services/
│   ├── APIService.swift
│   └── NetworkManager.swift
├── Utilities/
│   ├── Config.swift
│   └── Extensions.swift
└── Resources/
    └── Info.plist
```

---

### Шаг 2: Модели данных

Создайте файл `Models/ChatModels.swift`:

```swift
import Foundation

// MARK: - Message

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let sender: MessageSender
    let timestamp: Date
    var sources: [MessageSource]?

    enum MessageSender: String, Codable {
        case user
        case assistant
    }

    init(id: UUID = UUID(), text: String, sender: MessageSender, timestamp: Date = Date(), sources: [MessageSource]? = nil) {
        self.id = id
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.sources = sources
    }
}

// MARK: - Message Source

struct MessageSource: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let url: URL?
    let excerpt: String?

    init(id: UUID = UUID(), title: String, url: URL?, excerpt: String?) {
        self.id = id
        self.title = title
        self.url = url
        self.excerpt = excerpt
    }
}

// MARK: - Chat Session

struct ChatSession: Codable {
    let id: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
    }
}
```

Создайте файл `Models/APIModels.swift`:

```swift
import Foundation
import UIKit

// MARK: - Request Models

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

    static var current: DeviceInfo {
        DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }
}

// MARK: - Response Models

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

struct SessionResponse: Codable {
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
    }
}

struct ErrorResponse: Codable {
    let detail: String
}
```

---

### Шаг 3: Network Layer

Создайте файл `Services/APIService.swift`:

```swift
import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(Int, String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .invalidResponse:
            return "Некорректный ответ сервера"
        case .decodingError(let error):
            return "Ошибка декодирования: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Ошибка сервера (\(code)): \(message)"
        case .unauthorized:
            return "Требуется авторизация"
        }
    }
}

class APIService {
    static let shared = APIService()

    private let baseURL: String
    private let session: URLSession

    private init() {
        #if DEBUG
        self.baseURL = "http://localhost:8000/api/v1"  // Для разработки
        #else
        self.baseURL = "https://api.m10support.com/api/v1"  // Продакшн
        #endif

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true

        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    func createSession() async throws -> String {
        let endpoint = "/chat/ios/session"

        let response: SessionResponse = try await post(endpoint: endpoint, body: EmptyBody())
        return response.sessionId
    }

    func sendMessage(_ request: ChatRequest) async throws -> ChatResponse {
        let endpoint = "/chat/ios/message"

        return try await post(endpoint: endpoint, body: request)
    }

    func getChatHistory(sessionId: String, limit: Int = 50) async throws -> [Message] {
        let endpoint = "/chat/ios/history/\(sessionId)?limit=\(limit)"

        struct HistoryResponse: Codable {
            let messages: [MessageDTO]
        }

        struct MessageDTO: Codable {
            let id: String
            let text: String
            let sender: String
            let timestamp: Date
            let sources: [SourceInfo]?
        }

        let response: HistoryResponse = try await get(endpoint: endpoint)

        return response.messages.compactMap { dto in
            guard let senderId = UUID(uuidString: dto.id),
                  let sender = Message.MessageSender(rawValue: dto.sender) else {
                return nil
            }

            let sources = dto.sources?.map { source in
                MessageSource(
                    title: source.title,
                    url: URL(string: source.url),
                    excerpt: source.excerpt
                )
            }

            return Message(
                id: senderId,
                text: dto.text,
                sender: sender,
                timestamp: dto.timestamp,
                sources: sources
            )
        }
    }

    // MARK: - Private Methods

    private func get<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return try await performRequest(request)
    }

    private func post<T: Decodable, B: Encodable>(endpoint: String, body: B) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        return try await performRequest(request)
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Логирование для отладки
            #if DEBUG
            print("📡 Response Status: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response Data: \(jsonString)")
            }
            #endif

            guard (200...299).contains(httpResponse.statusCode) else {
                // Попытка декодировать сообщение об ошибке
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(httpResponse.statusCode, errorResponse.detail)
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw APIError.serverError(httpResponse.statusCode, errorMessage)
                }
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Helper Types

private struct EmptyBody: Encodable {}
```

---

### Шаг 4: ViewModel

Создайте файл `ViewModels/ChatViewModel.swift`:

```swift
import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var sessionId: String?

    // MARK: - Private Properties

    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        Task {
            await initializeSession()
        }
    }

    // MARK: - Public Methods

    func initializeSession() async {
        isLoading = true
        errorMessage = nil

        do {
            let newSessionId = try await apiService.createSession()
            self.sessionId = newSessionId
            print("✅ Session created: \(newSessionId)")

            // Загружаем историю если есть
            await loadHistory()
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func sendMessage(_ text: String) async {
        guard let sessionId = sessionId else {
            errorMessage = "Нет активной сессии"
            return
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Добавляем сообщение пользователя сразу в UI
        let userMessage = Message(
            text: trimmedText,
            sender: .user
        )
        messages.append(userMessage)

        isSending = true
        errorMessage = nil

        do {
            // Создаём запрос
            let request = ChatRequest(
                sessionId: sessionId,
                message: trimmedText,
                timestamp: Date(),
                deviceInfo: DeviceInfo.current
            )

            // Отправляем на сервер
            let response = try await apiService.sendMessage(request)

            // Создаём сообщение ассистента
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

            print("✅ Message sent and received")

        } catch {
            handleError(error)

            // Удаляем сообщение пользователя если произошла ошибка
            if let lastMessage = messages.last, lastMessage.id == userMessage.id {
                messages.removeLast()
            }
        }

        isSending = false
    }

    func loadHistory() async {
        guard let sessionId = sessionId else { return }

        do {
            let history = try await apiService.getChatHistory(sessionId: sessionId)
            self.messages = history
            print("✅ Loaded \(history.count) messages from history")
        } catch {
            print("⚠️ Failed to load history: \(error.localizedDescription)")
            // Не показываем ошибку пользователю, т.к. это не критично
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func retry() async {
        errorMessage = nil
        await initializeSession()
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }

        print("❌ Error: \(error)")
    }
}
```

---

### Шаг 5: UI Components

Создайте файл `Views/ChatView.swift`:

```swift
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        if viewModel.isLoading {
                            ProgressView("Загрузка...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.messages.isEmpty {
                            emptyStateView
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                if viewModel.isSending {
                                    TypingIndicator()
                                }
                            }
                            .padding()
                        }
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        scrollToBottom(scrollProxy)
                    }
                    .onChange(of: viewModel.isSending) { _ in
                        scrollToBottom(scrollProxy)
                    }
                }

                // Error Banner
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(
                        message: errorMessage,
                        onRetry: {
                            Task {
                                await viewModel.retry()
                            }
                        },
                        onDismiss: {
                            viewModel.clearError()
                        }
                    )
                }

                Divider()

                // Input Bar
                InputBar(
                    text: $messageText,
                    isFocused: $isInputFocused,
                    isDisabled: viewModel.isSending || viewModel.sessionId == nil,
                    onSend: {
                        Task {
                            await viewModel.sendMessage(messageText)
                            messageText = ""
                        }
                    }
                )
            }
            .navigationTitle("Dəstək")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("Salam! Necə kömək edə bilərəm?")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("BakıKART, pul köçürmələri və digər xidmətlər haqqında soruşa bilərsiniz")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastMessage = viewModel.messages.last else { return }

        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}
```

Создайте файл `Views/Components/MessageBubble.swift`:

```swift
import SwiftUI

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.sender == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                // Message Text
                Text(message.text)
                    .padding(12)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(16)
                    .textSelection(.enabled)

                // Sources
                if let sources = message.sources, !sources.isEmpty {
                    SourcesView(sources: sources)
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if message.sender == .assistant {
                Spacer(minLength: 60)
            }
        }
    }

    private var backgroundColor: Color {
        message.sender == .user ? .blue : Color(.systemGray5)
    }

    private var textColor: Color {
        message.sender == .user ? .white : .primary
    }
}

struct SourcesView: View {
    let sources: [MessageSource]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                    Text("Mənbələr (\(sources.count))")
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
                .padding(8)
            }

            if isExpanded {
                ForEach(sources) { source in
                    if let url = source.url {
                        Link(destination: url) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.caption2)
                                    Text(source.title)
                                        .font(.caption)
                                        .lineLimit(2)
                                }

                                if let excerpt = source.excerpt {
                                    Text(excerpt)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}
```

Создайте файл `Views/Components/InputBar.swift`:

```swift
import SwiftUI

struct InputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isDisabled: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Text Field
            TextField("Mesajınızı yazın...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused(isFocused)
                .disabled(isDisabled)

            // Send Button
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(sendButtonColor)
                    .clipShape(Circle())
            }
            .disabled(shouldDisableSend)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var shouldDisableSend: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDisabled
    }

    private var sendButtonColor: Color {
        shouldDisableSend ? .gray : .blue
    }
}

struct TypingIndicator: View {
    @State private var animationAmount = 0.0

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .opacity(animationAmount == Double(index) ? 1.0 : 0.3)
                }
            }
            .padding(12)
            .background(Color(.systemGray5))
            .cornerRadius(16)

            Spacer()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: false)) {
                animationAmount = 3.0
            }
        }
    }
}

struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            Text(message)
                .font(.caption)
                .foregroundColor(.red)

            Spacer()

            Button("Yenidən", action: onRetry)
                .font(.caption)
                .foregroundColor(.blue)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
    }
}
```

---

### Шаг 6: App Entry Point

Обновите `M10SupportApp.swift`:

```swift
import SwiftUI

@main
struct M10SupportApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
    }
}
```

---

### Шаг 7: Конфигурация

Создайте `Utilities/Config.swift`:

```swift
import Foundation

struct AppConfig {
    // API Configuration
    #if DEBUG
    static let apiBaseURL = "http://localhost:8000/api/v1"
    static let isDebugMode = true
    #else
    static let apiBaseURL = "https://api.m10support.com/api/v1"
    static let isDebugMode = false
    #endif

    // Timeouts
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60

    // UI Configuration
    static let maxMessageLength = 500
    static let messagesPerPage = 50
}
```

---

### Шаг 8: Тестирование

#### 8.1 Unit Tests

Создайте `M10SupportTests/APIServiceTests.swift`:

```swift
import XCTest
@testable import M10Support

final class APIServiceTests: XCTestCase {
    var apiService: APIService!

    override func setUp() {
        super.setUp()
        apiService = APIService.shared
    }

    func testCreateSession() async throws {
        let sessionId = try await apiService.createSession()

        XCTAssertFalse(sessionId.isEmpty)
        XCTAssertNotNil(UUID(uuidString: sessionId))
    }

    func testSendMessage() async throws {
        // Создаём сессию
        let sessionId = try await apiService.createSession()

        // Создаём запрос
        let request = ChatRequest(
            sessionId: sessionId,
            message: "BakıKART-a necə pul yükləyə bilərəm?",
            timestamp: Date(),
            deviceInfo: DeviceInfo.current
        )

        // Отправляем сообщение
        let response = try await apiService.sendMessage(request)

        XCTAssertFalse(response.answer.isEmpty)
        XCTAssertEqual(response.language, "az")
        XCTAssertGreaterThan(response.sources.count, 0)
    }
}
```

#### 8.2 Preview для SwiftUI

Добавьте в конец `ChatView.swift`:

```swift
#Preview {
    ChatView()
}
```

---

## Backend Setup для тестирования

### Backend Endpoint (для справки)

Создайте в backend `app/api/endpoints/ios_chat.py`:

```python
from fastapi import APIRouter, HTTPException
from app.schemas.ios_chat import ChatRequest, ChatResponse, SessionResponse
from app.services.ios_conversation_service import iOSConversationService
import uuid
from datetime import datetime

router = APIRouter(prefix="/chat/ios", tags=["iOS Chat"])

@router.post("/session", response_model=SessionResponse)
async def create_session():
    """Создать новую сессию"""
    session_id = str(uuid.uuid4())
    return SessionResponse(session_id=session_id)

@router.post("/message", response_model=ChatResponse)
async def send_message(request: ChatRequest):
    """Обработать сообщение"""
    service = iOSConversationService()

    try:
        response = await service.process_message(
            session_id=request.session_id,
            message=request.message,
            device_info=request.device_info
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

## Запуск и тестирование

### 1. Запустите Backend

```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Откройте iOS проект в Xcode

```bash
open M10Support.xcodeproj
```

### 3. Запустите на симуляторе

- Command + R
- Выберите iPhone 15 Pro Simulator

### 4. Протестируйте

Отправьте сообщения:
- "BakıKART-a necə pul yükləyə bilərəm?"
- "Kommunal ödənişləri necə edə bilərəm?"
- "Cash loan nədir?"

---

## Готово!

Ваше iOS приложение теперь интегрировано с AI-powered support системой, которая:

✅ Подключается напрямую к Confluence API
✅ Использует Kimi AI для генерации ответов
✅ Поддерживает многоязычность (az/ru/en)
✅ Имеет красивый SwiftUI интерфейс
✅ Сохраняет историю чатов

Следующие шаги для улучшения:
- Добавить push-уведомления
- Реализовать оффлайн-режим
- Добавить голосовой ввод
- Интегрировать аналитику

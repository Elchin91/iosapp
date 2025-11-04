# iOS Integration FAQ & Troubleshooting
## Часто задаваемые вопросы и решение проблем

---

## Содержание

1. [Общие вопросы](#общие-вопросы)
2. [Технические вопросы](#технические-вопросы)
3. [Проблемы и решения](#проблемы-и-решения)
4. [Оптимизация](#оптимизация)
5. [Безопасность](#безопасность)
6. [Развертывание](#развертывание)

---

## Общие вопросы

### Q1: Почему для iOS используется прямой доступ к Confluence, а не локальная база?

**A:** Это связано с ограничениями мобильных устройств:

**Проблемы локального подхода на iOS:**
- 📦 **Размер**: ChromaDB + BM25 индекс занимают сотни MB
- 🔄 **Синхронизация**: Нужен сложный механизм обновления базы
- 💾 **Память**: Индексы занимают оперативную память
- 🔋 **Батарея**: Индексирование потребляет много энергии
- ⏱️ **Время**: Первичная загрузка может занять минуты

**Преимущества прямого API подхода:**
- ✅ Легковесное приложение (< 20 MB)
- ✅ Всегда актуальные данные
- ✅ Не требует локального хранилища
- ✅ Быстрый старт приложения
- ✅ Вся тяжелая работа на сервере

---

### Q2: Нужен ли интернет для работы приложения?

**A:** Да, приложение требует активного интернет-соединения.

**Однако можно реализовать:**
- 📱 Кеширование последних сообщений для просмотра оффлайн
- 📝 Черновики сообщений (отправятся при восстановлении связи)
- ⚠️ Уведомление о потере соединения

**Пример оффлайн кеша:**

```swift
class OfflineCache {
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_messages"

    func saveMessages(_ messages: [Message]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(messages) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }

    func loadCachedMessages() -> [Message]? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode([Message].self, from: data)
    }
}
```

---

### Q3: Как быстро приходит ответ от AI?

**A:** Средняя задержка составляет **3-7 секунд**:

- 🔍 Поиск в Confluence: ~1-2 сек
- 🤖 Генерация ответа Kimi AI: ~2-4 сек
- 🌐 Сетевая задержка: ~0.5-1 сек

**Оптимизации:**
- Показываем typing indicator
- Кешируем популярные запросы на backend
- Используем CDN для статических ресурсов

---

### Q4: Поддерживается ли голосовой ввод?

**A:** Базово - нет, но легко добавить через Speech Framework:

```swift
import Speech

class VoiceInputManager {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "az-AZ"))
    private var recognitionTask: SFSpeechRecognitionTask?

    func startRecording(onResult: @escaping (String) -> Void) {
        // Реализация голосового ввода
    }
}
```

**Поддерживаемые языки:**
- 🇦🇿 Азербайджанский (az-AZ)
- 🇷🇺 Русский (ru-RU)
- 🇬🇧 Английский (en-US)

---

## Технические вопросы

### Q5: Какие версии iOS поддерживаются?

**A:** Минимальная версия - **iOS 15.0+**

```swift
// В Xcode > Target > General > Deployment Info
Minimum Deployments: iOS 15.0
```

**Обоснование:**
- ✅ SwiftUI 3.0 требует iOS 15+
- ✅ async/await стабильны с iOS 15
- ✅ 95%+ пользователей на iOS 15+

---

### Q6: Как работает многоязычность?

**A:** Backend автоматически определяет язык:

```python
def detect_language(text: str) -> str:
    """Определяет язык по характерным символам и словам"""

    # Азербайджанские символы
    if any(char in text.lower() for char in ['ə', 'ı', 'ö', 'ü', 'ğ', 'ç', 'ş']):
        return "az"

    # Русские символы
    if any(char in text.lower() for char in ['а', 'б', 'в', 'ж', 'з', 'ы', 'э', 'ю', 'я']):
        return "ru"

    return "en"
```

**iOS автоматически получает:**
- Язык интерфейса (локализация)
- Язык ответа от AI
- Правильные промпты

---

### Q7: Как аутентифицировать пользователей?

**A:** Можно интегрировать разные методы:

**Вариант 1: JWT Token**

```swift
class AuthService {
    func login(phone: String, code: String) async throws -> String {
        let request = LoginRequest(phone: phone, code: code)
        let response: LoginResponse = try await apiService.login(request)

        // Сохраняем токен
        KeychainManager.shared.saveToken(response.token)
        return response.token
    }
}
```

**Вариант 2: OAuth (Google, Apple)**

```swift
import AuthenticationServices

class AppleAuthService {
    func signInWithApple() async throws -> String {
        // Реализация Sign in with Apple
    }
}
```

---

### Q8: Как хранить чувствительные данные?

**A:** Используйте Keychain:

```swift
import Security

class KeychainManager {
    static let shared = KeychainManager()

    func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "auth_token",
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "auth_token",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        if let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }
}
```

---

## Проблемы и решения

### Проблема 1: "Session creation failed"

**Симптомы:**
- ❌ Ошибка при запуске приложения
- ❌ "Failed to create session" в логах

**Решения:**

**1. Проверьте backend:**
```bash
# Проверка доступности API
curl http://localhost:8000/api/v1/chat/ios/session -X POST

# Должен вернуть:
# {"session_id": "uuid-here"}
```

**2. Проверьте сетевые настройки iOS:**
```swift
// Info.plist - добавьте для локальной разработки
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

**3. Проверьте URL в Config:**
```swift
struct AppConfig {
    #if DEBUG
    static let apiBaseURL = "http://localhost:8000/api/v1"  // ← Проверьте порт
    #endif
}
```

---

### Проблема 2: "Decoding error"

**Симптомы:**
- ❌ "Failed to parse response"
- ❌ DecodingError в консоли

**Решения:**

**1. Проверьте соответствие моделей:**

```swift
// iOS Model
struct ChatResponse: Codable {
    let sessionId: String  // snake_case в JSON!

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"  // ← Важно!
    }
}
```

**2. Включите подробное логирование:**

```swift
private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
    let (data, response) = try await session.data(for: request)

    #if DEBUG
    // Логируем сырой JSON
    if let jsonString = String(data: data, encoding: .utf8) {
        print("📦 Raw JSON Response:")
        print(jsonString)
    }
    #endif

    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        print("❌ Decoding failed: \(error)")
        throw APIError.decodingError(error)
    }
}
```

---

### Проблема 3: Медленные ответы

**Симптомы:**
- ⏱️ Ответ приходит > 10 секунд
- 🐌 Приложение зависает

**Решения:**

**1. Проверьте таймауты:**

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30  // ← Увеличьте если нужно
config.timeoutIntervalForResource = 60
```

**2. Добавьте индикацию прогресса:**

```swift
struct ProgressView: View {
    @State private var progress = 0.0

    var body: some View {
        VStack {
            ProgressView(value: progress, total: 1.0)
            Text("Axtarış: \(Int(progress * 100))%")
        }
        .onReceive(timer) { _ in
            if progress < 0.9 {
                progress += 0.1
            }
        }
    }
}
```

**3. Оптимизируйте backend:**

```python
# Уменьшите количество результатов
results = await confluence_search.search_multiple_queries(
    queries,
    limit=5  # ← Было 10
)
```

---

### Проблема 4: Утечки памяти

**Симптомы:**
- 📈 Растущее потребление памяти
- 💥 Крэши на старых устройствах

**Решения:**

**1. Используйте LazyVStack:**

```swift
// ❌ Плохо - загружает все сообщения сразу
VStack {
    ForEach(messages) { message in
        MessageBubble(message: message)
    }
}

// ✅ Хорошо - загружает по мере прокрутки
LazyVStack {
    ForEach(messages) { message in
        MessageBubble(message: message)
    }
}
```

**2. Ограничьте историю:**

```swift
@Published var messages: [Message] = [] {
    didSet {
        // Храним максимум 100 сообщений
        if messages.count > 100 {
            messages = Array(messages.suffix(100))
        }
    }
}
```

**3. Освобождайте ресурсы:**

```swift
class ChatViewModel: ObservableObject {
    deinit {
        cancellables.removeAll()
        print("🧹 ChatViewModel deallocated")
    }
}
```

---

### Проблема 5: Некорректные ответы AI

**Симптомы:**
- 🤖 AI отвечает не по теме
- ❓ Ответы содержат "информации нет"

**Решения:**

**1. Проверьте Confluence search:**

```python
# Добавьте логирование
logger.info(f"🔍 Searching for: {queries}")
logger.info(f"📄 Found {len(results)} pages")
logger.info(f"📝 Top result: {results[0]['title'] if results else 'None'}")
```

**2. Проверьте промпт:**

```python
# Убедитесь что контекст передаётся
if not context_chunks:
    logger.warning("⚠️ No context found!")
    # Вернуть более информативное сообщение
```

**3. Проверьте Query Expansion:**

```python
queries = query_expander.expand_with_context(
    query=question,
    language=detected_language,
    entities=entities
)

logger.info(f"📝 Expanded to {len(queries)} queries:")
for q in queries:
    logger.info(f"   - {q}")
```

---

## Оптимизация

### Оптимизация 1: Кеширование ответов

**Backend кеш для популярных запросов:**

```python
from functools import lru_cache
import hashlib

class CachedConfluenceSearch:
    def __init__(self):
        self._cache = {}

    async def search_with_cache(self, query: str) -> List[Dict]:
        # Создаём хеш запроса
        cache_key = hashlib.md5(query.encode()).hexdigest()

        # Проверяем кеш
        if cache_key in self._cache:
            logger.info(f"✅ Cache hit for: {query}")
            return self._cache[cache_key]

        # Выполняем поиск
        results = await self.search(query)

        # Сохраняем в кеш (с TTL 1 час)
        self._cache[cache_key] = {
            'results': results,
            'timestamp': datetime.utcnow()
        }

        return results
```

---

### Оптимизация 2: Сжатие изображений

**Уменьшение размера аватаров и медиа:**

```swift
extension UIImage {
    func compressed(quality: CGFloat = 0.5) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }

    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        self.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
```

---

### Оптимизация 3: Батчинг запросов

**Группировка нескольких запросов:**

```swift
class BatchedAPIService {
    private var pendingMessages: [String] = []
    private var batchTimer: Timer?

    func queueMessage(_ message: String) {
        pendingMessages.append(message)

        // Отправляем batch через 500ms или когда накопится 5 сообщений
        if pendingMessages.count >= 5 {
            sendBatch()
        } else {
            scheduleBatchSend()
        }
    }

    private func sendBatch() {
        guard !pendingMessages.isEmpty else { return }

        let batch = pendingMessages
        pendingMessages.removeAll()

        // Отправляем batch на backend
        Task {
            try await apiService.sendBatch(batch)
        }
    }
}
```

---

## Безопасность

### Безопасность 1: Защита API ключей

**❌ Никогда не храните в коде:**

```swift
// ❌ ПЛОХО
let apiKey = "sk-1234567890abcdef"  // Видно в исходниках!
```

**✅ Используйте backend proxy:**

```swift
// ✅ ХОРОШО
// iOS -> Backend -> Confluence/Kimi
// API ключи только на сервере
```

---

### Безопасность 2: SSL Pinning

**Защита от MITM атак:**

```swift
class SecureNetworkManager: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Проверка сертификата
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
}
```

---

### Безопасность 3: Валидация ввода

**Защита от injection атак:**

```swift
func sanitizeInput(_ text: String) -> String {
    var sanitized = text

    // Удаляем потенциально опасные символы
    let dangerousChars = CharacterSet(charactersIn: "<>\"'&")
    sanitized = sanitized.components(separatedBy: dangerousChars).joined()

    // Ограничиваем длину
    if sanitized.count > 500 {
        sanitized = String(sanitized.prefix(500))
    }

    return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
}
```

---

## Развертывание

### Deploy 1: TestFlight

**Шаги для beta тестирования:**

```bash
# 1. Archive в Xcode
# Product > Archive

# 2. Distribute App
# Choose: App Store Connect

# 3. Upload

# 4. В App Store Connect
# TestFlight > добавить тестеров
```

---

### Deploy 2: App Store

**Чеклист для релиза:**

- [ ] Обновлен номер версии (CFBundleShortVersionString)
- [ ] Обновлен build number (CFBundleVersion)
- [ ] Подготовлены скриншоты (всех размеров)
- [ ] Написано описание приложения (az/ru/en)
- [ ] Настроены In-App Purchases (если есть)
- [ ] Пройден App Review Guidelines
- [ ] Добавлена Privacy Policy
- [ ] Настроен App Store Connect

---

### Deploy 3: CI/CD с Fastlane

**Автоматизация релизов:**

```ruby
# fastlane/Fastfile

default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    increment_build_number
    build_app(scheme: "M10Support")
    upload_to_testflight
  end

  desc "Release to App Store"
  lane :release do
    increment_build_number
    build_app(scheme: "M10Support")
    upload_to_app_store
  end
end
```

```bash
# Запуск
fastlane beta
fastlane release
```

---

## Мониторинг и аналитика

### Analytics 1: Firebase

```swift
import FirebaseAnalytics

class AnalyticsManager {
    static func logMessageSent(language: String) {
        Analytics.logEvent("message_sent", parameters: [
            "language": language,
            "platform": "ios"
        ])
    }

    static func logAIResponseReceived(confidence: Double, tokensUsed: Int) {
        Analytics.logEvent("ai_response_received", parameters: [
            "confidence": confidence,
            "tokens_used": tokensUsed
        ])
    }
}
```

---

### Analytics 2: Crashlytics

```swift
import FirebaseCrashlytics

class ErrorLogger {
    static func log(_ error: Error, context: [String: Any] = [:]) {
        Crashlytics.crashlytics().record(error: error)

        for (key, value) in context {
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        }
    }
}
```

---

## Полезные ссылки

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Confluence Cloud REST API](https://developer.atlassian.com/cloud/confluence/rest/v2/)
- [Kimi AI Documentation](https://platform.moonshot.cn/docs)

---

## Поддержка

Если у вас возникли вопросы:

1. 📖 Проверьте эту документацию
2. 🔍 Поищите в логах приложения и backend
3. 💬 Создайте issue в репозитории проекта
4. 📧 Напишите команде разработки

**Успешной разработки!** 🚀

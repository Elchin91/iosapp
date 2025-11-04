//
//  TelegramService.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import Foundation

// MARK: - Telegram Models

struct TelegramUpdate: Codable {
    let updateId: Int
    let message: TelegramMessage?

    enum CodingKeys: String, CodingKey {
        case updateId = "update_id"
        case message
    }
}

struct TelegramMessage: Codable {
    let messageId: Int
    let from: TelegramUser?
    let chat: TelegramChat
    let date: Int
    let text: String?

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case from
        case chat
        case date
        case text
    }
}

struct TelegramUser: Codable {
    let id: Int
    let isBot: Bool
    let firstName: String
    let lastName: String?
    let username: String?

    enum CodingKeys: String, CodingKey {
        case id
        case isBot = "is_bot"
        case firstName = "first_name"
        case lastName = "last_name"
        case username
    }
}

struct TelegramChat: Codable {
    let id: Int
    let type: String
    let firstName: String?
    let lastName: String?
    let username: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case firstName = "first_name"
        case lastName = "last_name"
        case username
    }
}

struct TelegramResponse<T: Codable>: Codable {
    let ok: Bool
    let result: T?
    let description: String?
}

struct TelegramSendMessageResponse: Codable {
    let messageId: Int
    let chat: TelegramChat
    let date: Int
    let text: String

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case chat
        case date
        case text
    }
}

// MARK: - Telegram Service Error

enum TelegramError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case apiError(String)
    case noChatId
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Telegram API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "Telegram API error: \(message)"
        case .noChatId:
            return "No chat ID available. Please send a message to the bot first."
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Telegram Service

@MainActor
class TelegramService: ObservableObject {
    // MARK: - Properties

    private let botToken: String
    private let baseURL: String

    @Published var isPolling: Bool = false
    @Published var chatId: Int?
    @Published var lastError: String?

    private var pollingTask: Task<Void, Never>?
    private var lastUpdateId: Int = 0

    // Callback for incoming messages
    var onMessageReceived: ((String) -> Void)?

    // MARK: - Initialization

    init(botToken: String) {
        self.botToken = botToken
        self.baseURL = "https://api.telegram.org/bot\(botToken)"

        // Load saved chat ID from UserDefaults
        if let savedChatId = UserDefaults.standard.value(forKey: "telegram_chat_id") as? Int {
            self.chatId = savedChatId
            print("Loaded saved Telegram chat ID: \(savedChatId)")
        }
    }

    // MARK: - Public Methods

    /// Sends a message to the Telegram bot
    func sendMessage(text: String) async throws {
        guard let chatId = chatId else {
            throw TelegramError.noChatId
        }

        let endpoint = "\(baseURL)/sendMessage"

        guard let url = URL(string: endpoint) else {
            throw TelegramError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "chat_id": chatId,
            "text": text,
            "parse_mode": "HTML"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TelegramError.apiError("Invalid response")
            }

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TelegramError.apiError("Status \(httpResponse.statusCode): \(errorMessage)")
            }

            let decoder = JSONDecoder()
            let telegramResponse = try decoder.decode(TelegramResponse<TelegramSendMessageResponse>.self, from: data)

            if !telegramResponse.ok {
                throw TelegramError.apiError(telegramResponse.description ?? "Unknown error")
            }

            print("Message sent to Telegram successfully")

        } catch let error as TelegramError {
            throw error
        } catch {
            throw TelegramError.networkError(error)
        }
    }

    /// Starts long polling to receive messages from Telegram
    func startPolling() {
        guard !isPolling else {
            print("Polling is already active")
            return
        }

        isPolling = true
        print("Starting Telegram polling...")

        pollingTask = Task {
            while !Task.isCancelled && isPolling {
                do {
                    try await pollUpdates()
                    // Short delay between polling requests
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                } catch {
                    print("Polling error: \(error.localizedDescription)")
                    lastError = error.localizedDescription
                    // Wait longer on error before retrying
                    try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                }
            }
        }
    }

    /// Stops long polling
    func stopPolling() {
        print("Stopping Telegram polling...")
        isPolling = false
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Private Methods

    private func pollUpdates() async throws {
        let endpoint = "\(baseURL)/getUpdates"

        var components = URLComponents(string: endpoint)
        components?.queryItems = [
            URLQueryItem(name: "offset", value: String(lastUpdateId + 1)),
            URLQueryItem(name: "timeout", value: "30"), // Long polling timeout
            URLQueryItem(name: "allowed_updates", value: "[\"message\"]")
        ]

        guard let url = components?.url else {
            throw TelegramError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 35 // Slightly longer than polling timeout

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TelegramError.apiError("Invalid response")
            }

            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TelegramError.apiError("Status \(httpResponse.statusCode): \(errorMessage)")
            }

            let decoder = JSONDecoder()
            let telegramResponse = try decoder.decode(TelegramResponse<[TelegramUpdate]>.self, from: data)

            if !telegramResponse.ok {
                throw TelegramError.apiError(telegramResponse.description ?? "Unknown error")
            }

            guard let updates = telegramResponse.result else {
                return
            }

            for update in updates {
                await processUpdate(update)
            }

        } catch let error as TelegramError {
            throw error
        } catch {
            throw TelegramError.networkError(error)
        }
    }

    private func processUpdate(_ update: TelegramUpdate) async {
        // Update the last update ID to avoid processing the same update twice
        lastUpdateId = max(lastUpdateId, update.updateId)

        guard let message = update.message,
              let text = message.text,
              !text.isEmpty else {
            return
        }

        // Skip messages from bots
        if let from = message.from, from.isBot {
            return
        }

        // Save chat ID if we don't have one yet
        if chatId == nil {
            chatId = message.chat.id
            UserDefaults.standard.set(message.chat.id, forKey: "telegram_chat_id")
            print("Saved new Telegram chat ID: \(message.chat.id)")
        }

        // Only process messages from the saved chat ID
        guard message.chat.id == chatId else {
            print("Ignoring message from different chat: \(message.chat.id)")
            return
        }

        print("Received message from Telegram: \(text)")

        // Call the callback with the received message
        onMessageReceived?(text)
    }

    /// Clears the saved chat ID
    func clearChatId() {
        chatId = nil
        UserDefaults.standard.removeObject(forKey: "telegram_chat_id")
        print("Cleared Telegram chat ID")
    }
}

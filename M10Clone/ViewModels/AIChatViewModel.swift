//
//  AIChatViewModel.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import Foundation
import SwiftUI

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    @Published var isTyping: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sessionId: String?

    private let apiService = APIService.shared
    private let telegramService: TelegramService

    init() {
        // Initialize Telegram service with bot token from config
        self.telegramService = TelegramService(botToken: APIConfig.Telegram.botToken)

        // Set up callback for incoming Telegram messages
        telegramService.onMessageReceived = { [weak self] text in
            Task { @MainActor in
                self?.handleTelegramMessage(text)
            }
        }

        Task {
            await initializeSession()
            // Start Telegram polling after session is initialized
            telegramService.startPolling()
        }
    }
    
    func initializeSession() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newSessionId = try await apiService.createSession()
            self.sessionId = newSessionId
            print("✅ Session created: \(newSessionId)")
            
            // Добавляем приветственное сообщение
            messages.append(Message(
                text: "Salam! Mən m10 dəstək xidmətindən Aydın. Necə kömək edə bilərəm?",
                isUser: false
            ))
            
            // Загружаем историю если есть
            await loadHistory()
        } catch {
            handleError(error)
            // Даже если сессия не создалась, показываем приветствие
            messages.append(Message(
                text: "Salam! Mən m10 dəstək xidmətindən Aydın. Necə kömək edə bilərəm?",
                isUser: false
            ))
        }
        
        isLoading = false
    }
    
    func sendMessage() {
        guard let sessionId = sessionId else {
            errorMessage = "Нет активной сессии"
            return
        }

        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Добавляем сообщение пользователя сразу в UI
        let userMessage = Message(
            text: trimmedText,
            isUser: true
        )
        messages.append(userMessage)

        let currentMessage = trimmedText
        messageText = ""
        isTyping = true
        errorMessage = nil

        Task {
            do {
                // Send message to Telegram bot
                do {
                    try await telegramService.sendMessage(text: "User: \(currentMessage)")
                    print("Message forwarded to Telegram")
                } catch {
                    print("Failed to send message to Telegram: \(error.localizedDescription)")
                    // Continue even if Telegram fails
                }

                // Создаём запрос
                let request = ChatRequest(
                    sessionId: sessionId,
                    message: currentMessage,
                    timestamp: Date(),
                    deviceInfo: DeviceInfo.current
                )

                // Отправляем на сервер
                let response = try await apiService.sendMessage(request)

                // Создаём сообщение ассистента
                let assistantMessage = Message(
                    id: UUID(uuidString: response.messageId) ?? UUID(),
                    text: response.answer,
                    isUser: false,
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

                // Send assistant response to Telegram
                do {
                    try await telegramService.sendMessage(text: "Assistant: \(response.answer)")
                } catch {
                    print("Failed to send response to Telegram: \(error.localizedDescription)")
                }

            } catch {
                handleError(error)
                // Удаляем сообщение пользователя если произошла ошибка
                if let lastMessage = messages.last, lastMessage.id == userMessage.id {
                    messages.removeLast()
                }
                // Показываем fallback ответ
                messages.append(Message(
                    text: generateFallbackResponse(for: currentMessage),
                    isUser: false
                ))
            }

            isTyping = false
        }
    }
    
    func loadHistory() async {
        guard let sessionId = sessionId else { return }
        
        do {
            let history = try await apiService.getChatHistory(sessionId: sessionId)
            if !history.isEmpty {
                self.messages = history
                print("✅ Loaded \(history.count) messages from history")
            }
        } catch {
            print("⚠️ Failed to load history: \(error.localizedDescription)")
            // Не показываем ошибку пользователю, т.к. это не критично
        }
    }
    
    func handleAttachment() {
        // Placeholder for attachment functionality
        print("Attachment button tapped")
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
    
    private func generateFallbackResponse(for userMessage: String) -> String {
        let lowercased = userMessage.lowercased()

        if lowercased.contains("баланс") || lowercased.contains("balans") {
            return "Balansınızı yoxlamaq üçün əsas ekrana keçin. Orada bütün məlumatlarınızı görə bilərsiniz."
        } else if lowercased.contains("платеж") || lowercased.contains("ödəniş") {
            return "Ödəniş etmək üçün 'Plaтежи' bölməsinə keçin. Hansı xidməti ödəmək istəyirsiniz?"
        } else if lowercased.contains("перевод") || lowercased.contains("köçürmə") {
            return "Pul köçürmək üçün 'Köçürmələr' bölməsindən istifadə edə bilərsiniz. Köçürmələr pulsuz və ani olur!"
        } else if lowercased.contains("bakıkart") || lowercased.contains("бакыкарт") {
            return "BakıKART balansını artırmaq üçün:\n1. 'Xidmətlər' bölməsinə keçin\n2. 'BakıKART' seçin\n3. Kart nömrəsini daxil edin\n4. Məbləği seçin\n5. 'Ödə' düyməsinə toxunun"
        } else {
            return "Anladım. Mən sizə balans, ödənişlər və köçürmələr haqqında kömək edə bilərəm. Xahiş edirəm, daha dəqiq sual verin."
        }
    }

    // MARK: - Telegram Integration

    private func handleTelegramMessage(_ text: String) {
        print("Handling Telegram message: \(text)")

        // Add message from Telegram to the chat
        let telegramMessage = Message(
            text: text,
            isUser: false
        )
        messages.append(telegramMessage)

        // Optionally, you can also process this message through the API
        // and send the response back to Telegram
        Task {
            guard let sessionId = sessionId else { return }

            isTyping = true

            do {
                let request = ChatRequest(
                    sessionId: sessionId,
                    message: text,
                    timestamp: Date(),
                    deviceInfo: DeviceInfo.current
                )

                let response = try await apiService.sendMessage(request)

                let assistantMessage = Message(
                    id: UUID(uuidString: response.messageId) ?? UUID(),
                    text: response.answer,
                    isUser: false,
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

                // Send response back to Telegram
                do {
                    try await telegramService.sendMessage(text: "Assistant: \(response.answer)")
                } catch {
                    print("Failed to send response to Telegram: \(error.localizedDescription)")
                }

            } catch {
                print("Error processing Telegram message: \(error.localizedDescription)")
            }

            isTyping = false
        }
    }

    deinit {
        // Stop polling when view model is destroyed
        telegramService.stopPolling()
    }
}

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

    init() {
        // Add welcome message
        messages.append(Message(
            text: "Привет! Я AI-ассистент M10 Digital Wallet. Чем могу помочь?",
            isUser: false
        ))
    }

    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let userMessage = Message(text: messageText, isUser: true)
        messages.append(userMessage)

        let currentMessage = messageText
        messageText = ""

        // Simulate AI response
        isTyping = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

            let aiResponse = generateAIResponse(for: currentMessage)
            messages.append(Message(text: aiResponse, isUser: false))
            isTyping = false
        }
    }

    func handleAttachment() {
        // Placeholder for attachment functionality
        print("Attachment button tapped")
    }

    private func generateAIResponse(for userMessage: String) -> String {
        let lowercased = userMessage.lowercased()

        if lowercased.contains("баланс") || lowercased.contains("счет") {
            return "Ваш текущий баланс: 15,250.00 ₽. Последняя транзакция: -500₽ в магазине 'Пятерочка' сегодня в 14:23."
        } else if lowercased.contains("платеж") || lowercased.contains("оплат") {
            return "Для совершения платежа перейдите в раздел 'Платежи'. Какую услугу вы хотите оплатить?"
        } else if lowercased.contains("перевод") {
            return "Вы можете перевести деньги через вкладку 'Переводы'. Переводы по номеру телефона или номеру карты мгновенные и без комиссии!"
        } else if lowercased.contains("помощь") || lowercased.contains("помог") {
            return "Я могу помочь вам с:\n• Проверкой баланса\n• Совершением платежей\n• Переводами\n• Историей операций\n• Настройками карты\n\nЧто вас интересует?"
        } else if lowercased.contains("привет") || lowercased.contains("здравствуй") {
            return "Здравствуйте! Рад помочь вам с финансовыми операциями. Что вас интересует?"
        } else {
            return "Понял ваш запрос. Я могу помочь с управлением вашим кошельком, платежами и переводами. Уточните, пожалуйста, что именно вас интересует?"
        }
    }
}

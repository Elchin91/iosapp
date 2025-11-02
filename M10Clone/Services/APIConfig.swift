//
//  APIConfig.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import Foundation

struct APIConfig {
    // MARK: - Backend API Configuration
    // iOS приложение обращается к Backend API, который уже настроен
    // с интеграцией Kimi и Confluence
    
    #if DEBUG
    static let baseURL = "http://localhost:8000/api/v1"  // Для локальной разработки
    #else
    static let baseURL = "https://api.m10support.com/api/v1"  // Production URL
    #endif
    
    // MARK: - Timeouts
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60
    
    // MARK: - Chat Settings
    static let maxMessageLength = 500
    static let maxHistoryMessages = 50
}

// MARK: - Backend Configuration (для справки)
// Эти данные используются Backend API, а не iOS приложением напрямую

struct BackendConfig {
    // Kimi K2 API Configuration
    // Используется backend для генерации ответов
    static let kimiAPIKey = "sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG"
    static let kimiBaseURL = "https://api.moonshot.cn/v1/chat/completions"
    static let kimiModel = "kimi-k2-turbo-preview"
    
    // Confluence API Configuration
    // Используется backend для поиска в документации
    // Требуется: CONFLUENCE_BASE_URL, CONFLUENCE_EMAIL, CONFLUENCE_API_TOKEN
    // Space Key: M10SUPPORT
    
    // Telegram Bot Configuration
    // Используется backend для интеграции с Telegram
    static let telegramBotToken = "8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA"
}

// MARK: - API Endpoints

enum APIEndpoint {
    case createSession
    case sendMessage
    case getHistory(sessionId: String, limit: Int = 50)
    
    var path: String {
        switch self {
        case .createSession:
            return "/chat/ios/session"
        case .sendMessage:
            return "/chat/ios/message"
        case .getHistory(let sessionId, let limit):
            return "/chat/ios/history/\(sessionId)?limit=\(limit)"
        }
    }
    
    var fullURL: String {
        return APIConfig.baseURL + path
    }
}


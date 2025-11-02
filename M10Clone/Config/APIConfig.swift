//
//  APIConfig.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import Foundation

struct APIConfig {
    // MARK: - Backend Configuration
    #if DEBUG
    // Локальный backend с полной поддержкой Confluence, Kimi AI, NER
    static let baseURL = "http://localhost:8000/api/v1"
    #else
    // Production backend (будет настроено при деплое)
    static let baseURL = "https://m10-support-ai.railway.app/api/v1"
    #endif
    
    // MARK: - Kimi K2 API Configuration (для справки, используется на backend)
    struct Kimi {
        static let apiKey = "sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG"
        static let baseURL = "https://api.moonshot.cn/v1/chat/completions"
        static let model = "kimi-k2-turbo-preview"
    }
    
    // MARK: - Telegram Bot Configuration (для справки)
    struct Telegram {
        static let botToken = "8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA"
    }
    
    // MARK: - Network Timeouts
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60
    
    // MARK: - API Endpoints
    enum APIEndpoint {
        case createSession
        case sendMessage
        case getHistory(sessionId: String, limit: Int)
        
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
    }
    
    // MARK: - Mock Mode Configuration
    // false = используем полноценный backend с Confluence, Kimi AI, NER, Vector Search
    // true = используем локальные fallback ответы
    static let useMockMode = false
}
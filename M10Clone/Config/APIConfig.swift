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
    // Для локального тестирования используйте IP адрес вашего компьютера
    // ВАЖНО: Замените на ваш реальный IP адрес!
    static let baseURL = "http://192.168.1.100:8000/api/v1"  // TODO: Замените на ваш IP
    #else
    // Для production используйте реальный URL вашего backend
    // Например: "https://your-app.railway.app/api/v1"
    static let baseURL = "https://m10-backend.railway.app/api/v1"
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
    // Установите true для тестирования без backend
    // Установите false когда backend запущен
    static let useMockMode = false  // Изменено для работы с реальным backend
}
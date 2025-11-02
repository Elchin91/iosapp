//
//  APIService.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

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
        // Для разработки можно использовать локальный сервер или заглушку
        self.baseURL = "https://api.m10support.com/api/v1"  // Замените на ваш URL
        #else
        self.baseURL = "https://api.m10support.com/api/v1"
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
        
        struct EmptyBody: Encodable {}
        
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
            guard let messageId = UUID(uuidString: dto.id) else {
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
                id: messageId,
                text: dto.text,
                isUser: dto.sender == "user",
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
            
            #if DEBUG
            print("📡 Response Status: \(httpResponse.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Response Data: \(jsonString.prefix(500))")
            }
            #endif
            
            guard (200...299).contains(httpResponse.statusCode) else {
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


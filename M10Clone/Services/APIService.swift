//
//  APIService.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//  iOS приложение обращается к Backend API, который интегрирован с:
//  - Kimi K2 API (для генерации ответов)
//  - Confluence Cloud API (для поиска в документации)
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
    
    // MARK: - Configuration
    // Установите useMockMode = true для тестирования без backend
    private let useMockMode = false  // Измените на true для mock режима
    
    private let baseURL: String
    private let session: URLSession
    
    private init() {
        self.baseURL = APIConfig.baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.requestTimeout
        config.timeoutIntervalForResource = APIConfig.resourceTimeout
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    func createSession() async throws -> String {
        if useMockMode {
            return UUID().uuidString
        }
        
        struct EmptyBody: Encodable {}
        
        let response: SessionResponse = try await post(endpoint: APIEndpoint.createSession.path, body: EmptyBody())
        return response.sessionId
    }
    
    func sendMessage(_ request: ChatRequest) async throws -> ChatResponse {
        if useMockMode {
            return try await mockSendMessage(request)
        }
        
        return try await post(endpoint: APIEndpoint.sendMessage.path, body: request)
    }
    
    func getChatHistory(sessionId: String, limit: Int = 50) async throws -> [Message] {
        let endpoint = APIEndpoint.getHistory(sessionId: sessionId, limit: limit).path
        
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
    
    // MARK: - Mock Methods (для тестирования без backend)
    
    private func mockSendMessage(_ request: ChatRequest) async throws -> ChatResponse {
        // Имитация задержки сети
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 секунды
        
        // Генерируем простой ответ на основе запроса
        let answer = generateMockResponse(for: request.message)
        
        return ChatResponse(
            sessionId: request.sessionId,
            messageId: UUID().uuidString,
            answer: answer,
            language: "az",
            sources: [
                SourceInfo(
                    title: "Документация m10",
                    url: "https://confluence.m10.az/spaces/M10SUPPORT",
                    excerpt: "Информация о сервисах m10"
                )
            ],
            timestamp: Date(),
            metadata: ResponseMetadata(
                tokensUsed: 250,
                model: "kimi-k2-turbo-preview",
                confidence: 0.85
            )
        )
    }
    
    private func generateMockResponse(for message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("bakıkart") || lowercased.contains("бакыкарт") {
            return "BakıKART balansını artırmaq üçün:\n\n1. m10 tətbiqini açın\n2. 'Xidmətlər' bölməsinə keçin\n3. 'BakıKART' seçin\n4. Kart nömrəsini daxil edin\n5. Məbləği seçin (minimum 1 AZN, maksimum 100 AZN)\n6. 'Ödə' düyməsinə toxunun\n\nƏməliyyat dərhal başa çatacaq və pul kartınıza keçəcək."
        } else if lowercased.contains("баланс") || lowercased.contains("balans") {
            return "Balansınızı yoxlamaq üçün əsas ekrana keçin. Orada bütün məlumatlarınızı görə bilərsiniz."
        } else if lowercased.contains("платеж") || lowercased.contains("ödəniş") {
            return "Ödəniş etmək üçün 'Plaтежи' bölməsinə keçin. Orada müxtəlif xidmətləri görə bilərsiniz:\n\n• Kommunal ödənişlər (işıq, qaz, su)\n• Mobil operatorlar\n• İnternet və TV\n• Digər xidmətlər"
        } else if lowercased.contains("перевод") || lowercased.contains("köçürmə") {
            return "Pul köçürmək üçün 'Köçürmələr' bölməsindən istifadə edə bilərsiniz.\n\nKöçürmələr:\n• Pulsuz\n• Ani\n• İstənilən kart üçün (Azərbaycanda)\n\nTelefon nömrəsi və ya kart nömrəsi ilə köçürmə edə bilərsiniz."
        } else if lowercased.contains("кредит") || lowercased.contains("kredit") {
            return "m10-da kredit xidməti mövcuddur. Kredit almaq üçün:\n\n1. Əsas ekranda 'Kredit' kartını tapın\n2. Kredit məbləğini seçin\n3. Müraciət edin\n\nMaksimum kredit: 25,000 AZN"
        } else {
            return "Anladım. Mən sizə kömək edə bilərəm:\n\n• BakıKART balans artırma\n• Pul köçürmələri\n• Kommunal ödənişlər\n• Kredit xidmətləri\n• Balans yoxlama\n\nHansı sualınız var?"
        }
    }
}


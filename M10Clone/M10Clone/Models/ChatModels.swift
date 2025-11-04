//
//  ChatModels.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import Foundation
import UIKit

// MARK: - Message

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    var sources: [MessageSource]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case isUser = "is_user"
        case timestamp
        case sources
    }
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date(), sources: [MessageSource]? = nil) {
        self.id = id
        self.text = text
        self.isUser = isUser
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


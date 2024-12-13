import Foundation

struct ChatSession: Codable, Identifiable {
    let sessionId: Int
    let title: String?
    let status: ChatStatus
    let startedAt: Date
    let endedAt: Date?
    let summary: String?
    var messages: [ChatMessage]?
    
    var id: Int { sessionId }
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case title
        case status
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case summary
        case messages = "chatmessages"
    }
}

struct ChatMessage: Codable, Identifiable {
    let messageId: Int
    let sessionId: Int
    let role: MessageRole
    let content: String
    let sentAt: Date
    let metadata: [String: String]?
    
    var id: Int { messageId }
    
    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case sessionId = "session_id"
        case role
        case content
        case sentAt = "sent_at"
        case metadata
    }
}

enum ChatStatus: String, Codable {
    case active = "active"
    case ended = "ended"
    case archived = "archived"
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
} 
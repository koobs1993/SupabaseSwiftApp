import Foundation
import Supabase

protocol ChatServiceProtocol {
    func createSession(userId: UUID) async throws -> ChatSession
    func fetchSessions(userId: UUID) async throws -> [ChatSession]
    func saveMessage(sessionId: Int, userId: UUID, role: MessageRole, content: String) async throws -> ChatMessage
    func endSession(sessionId: Int, summary: String) async throws
    func archiveSession(sessionId: Int) async throws
    func fetchMessages(sessionId: Int) async throws -> [ChatMessage]
    func setupRealtimeSubscription(sessionId: Int, onMessage: @escaping (ChatMessage) -> Void) -> RealtimeSubscription
}

class ChatService: ChatServiceProtocol {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func createSession(userId: UUID) async throws -> ChatSession {
        try await supabase.database
            .from("chatsessions")
            .insert([
                "user_id": userId,
                "status": ChatStatus.active.rawValue,
                "started_at": ISO8601DateFormatter().string(from: Date())
            ])
            .single()
            .execute()
            .value
    }
    
    func fetchSessions(userId: UUID) async throws -> [ChatSession] {
        let response = try await supabase.database
            .from("chatsessions")
            .select("*, chatmessages(*)")
            .eq("user_id", userId)
            .order("started_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func saveMessage(sessionId: Int, userId: UUID, role: MessageRole, content: String) async throws -> ChatMessage {
        try await supabase.database
            .from("chatmessages")
            .insert([
                "session_id": sessionId,
                "user_id": userId,
                "role": role.rawValue,
                "content": content,
                "sent_at": ISO8601DateFormatter().string(from: Date())
            ])
            .single()
            .execute()
            .value
    }
    
    func endSession(sessionId: Int, summary: String) async throws {
        try await supabase.database
            .from("chatsessions")
            .update([
                "status": ChatStatus.ended.rawValue,
                "ended_at": ISO8601DateFormatter().string(from: Date()),
                "summary": summary
            ])
            .eq("session_id", sessionId)
            .execute()
    }
    
    func archiveSession(sessionId: Int) async throws {
        try await supabase.database
            .from("chatsessions")
            .update([
                "status": ChatStatus.archived.rawValue
            ])
            .eq("session_id", sessionId)
            .execute()
    }
    
    func fetchMessages(sessionId: Int) async throws -> [ChatMessage] {
        let response = try await supabase.database
            .from("chatmessages")
            .select()
            .eq("session_id", sessionId)
            .order("sent_at")
            .execute()
        
        return try response.value
    }
    
    func setupRealtimeSubscription(sessionId: Int, onMessage: @escaping (ChatMessage) -> Void) -> RealtimeSubscription {
        supabase.realtime
            .channel("public:chatmessages")
            .on("INSERT") { message in
                guard let messageData = try? JSONDecoder().decode(ChatMessage.self, from: message),
                      messageData.sessionId == sessionId else { return }
                onMessage(messageData)
            }
            .subscribe()
    }
} 
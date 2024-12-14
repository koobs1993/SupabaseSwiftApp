import Foundation
import Supabase

protocol WeeklyColumnServiceProtocol {
    func fetchColumns() async throws -> [WeeklyColumn]
    func fetchQuestions(for columnId: Int) async throws -> [WeeklyQuestion]
    func saveResponse(userId: UUID, questionId: Int, response: String) async throws
    func saveProgress(userId: UUID, columnId: Int, lastQuestionId: Int, completed: Bool) async throws
    func fetchResponses(userId: UUID, columnId: Int) async throws -> [Int: String]
}

class WeeklyColumnService: WeeklyColumnServiceProtocol {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func fetchColumns() async throws -> [WeeklyColumn] {
        let query = supabase.database
            .from("weeklycolumns")
            .select("""
                *,
                characterproblems:characterproblems(
                    characters(
                        *,
                        problems(*)
                    )
                ),
                userweeklyprogress(*)
            """)
            .eq("is_active", true)
            .order("sequence_number", ascending: true)
            .order("publish_date", ascending: false)
        
        return try await query.execute().value
    }
    
    func fetchQuestions(for columnId: Int) async throws -> [WeeklyQuestion] {
        let query = supabase.database
            .from("weeklyquestions")
            .select("*")
            .eq("column_id", columnId)
            .order("sequence_order")
        
        return try await query.execute().value
    }
    
    func saveResponse(userId: UUID, questionId: Int, response: String) async throws {
        try await supabase.database
            .from("weeklyresponses")
            .upsert([
                "user_id": userId,
                "question_id": questionId,
                "response_text": response,
                "submitted_at": ISO8601DateFormatter().string(from: Date())
            ])
            .execute()
    }
    
    func saveProgress(userId: UUID, columnId: Int, lastQuestionId: Int, completed: Bool) async throws {
        var data: [String: Any] = [
            "user_id": userId,
            "column_id": columnId,
            "last_question_id": lastQuestionId,
            "last_accessed": ISO8601DateFormatter().string(from: Date())
        ]
        
        if completed {
            data["completed_at"] = ISO8601DateFormatter().string(from: Date())
        }
        
        try await supabase.database
            .from("userweeklyprogress")
            .upsert(data)
            .execute()
    }
    
    func fetchResponses(userId: UUID, columnId: Int) async throws -> [Int: String] {
        let query = supabase.database
            .from("weeklyresponses")
            .select("""
                response_text,
                question_id,
                weeklyquestions!inner(column_id)
            """)
            .eq("user_id", userId)
            .eq("weeklyquestions.column_id", columnId)
        
        struct Response: Codable {
            let responseText: String
            let questionId: Int
            
            enum CodingKeys: String, CodingKey {
                case responseText = "response_text"
                case questionId = "question_id"
            }
        }
        
        let responses: [Response] = try await query.execute().value
        return Dictionary(uniqueKeysWithValues: responses.map { ($0.questionId, $0.responseText) })
    }
} 
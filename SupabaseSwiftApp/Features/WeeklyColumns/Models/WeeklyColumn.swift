import Foundation

struct WeeklyColumn: Identifiable, Codable {
    let columnId: Int
    let title: String
    let content: String?
    let featuredImageUrl: String?
    let sequenceNumber: Int?
    let publishDate: Date?
    let isActive: Bool
    var userProgress: UserWeeklyProgress?
    var characters: [Character]?
    
    enum CodingKeys: String, CodingKey {
        case columnId = "column_id"
        case title
        case content
        case featuredImageUrl = "featured_image_url"
        case sequenceNumber = "sequence_number"
        case publishDate = "publish_date"
        case isActive = "is_active"
        case userProgress = "userweeklyprogress"
        case characters = "characterproblems"
    }
    
    var id: Int { columnId }
    
    var shortDescription: String {
        content?.prefix(150).appending("...") ?? ""
    }
    
    var estimatedMinutes: Int {
        let wordsPerMinute = 200.0
        let words = content?.split(separator: " ").count ?? 0
        return max(1, Int(ceil(Double(words) / wordsPerMinute)))
    }
}

struct UserWeeklyProgress: Codable {
    let progressId: Int
    let userId: UUID
    let columnId: Int
    let lastQuestionId: Int?
    let startedAt: Date?
    let completedAt: Date?
    let lastAccessed: Date?
    
    enum CodingKeys: String, CodingKey {
        case progressId = "progress_id"
        case userId = "user_id"
        case columnId = "column_id"
        case lastQuestionId = "last_question_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case lastAccessed = "last_accessed"
    }
}

struct WeeklyQuestion: Identifiable, Codable {
    let questionId: Int
    let columnId: Int
    let questionText: String
    let sequenceOrder: Int
    let isRequired: Bool
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case columnId = "column_id"
        case questionText = "question_text"
        case sequenceOrder = "sequence_order"
        case isRequired = "is_required"
    }
    
    var id: Int { questionId }
} 
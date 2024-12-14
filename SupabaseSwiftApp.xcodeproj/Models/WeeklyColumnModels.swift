import Foundation

struct WeeklyColumn: Codable, Identifiable {
    let columnId: Int
    let title: String
    let content: String?
    let featuredImageUrl: String?
    let sequenceNumber: Int?
    let publishDate: Date?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    var characters: [Character]?
    var userProgress: UserWeeklyProgress?
    
    var id: Int { columnId }
    
    var estimatedMinutes: Int {
        guard let content = content else { return 5 }
        return content.split(separator: " ").count / 200 * 60
    }
    
    var shortDescription: String {
        guard let content = content else { return "" }
        let sentences = content.components(separatedBy: ". ")
        return sentences.prefix(2).joined(separator: ". ") + "..."
    }
    
    enum CodingKeys: String, CodingKey {
        case columnId = "column_id"
        case title
        case content
        case featuredImageUrl = "featured_image_url"
        case sequenceNumber = "sequence_number"
        case publishDate = "publish_date"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case characters = "characterproblems"
        case userProgress = "userweeklyprogress"
    }
}

struct Character: Codable, Identifiable {
    let characterId: Int
    let name: String
    let imageUrl: String?
    let bio: String?
    let isActive: Bool
    let deletedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let problems: [Problem]?
    
    var id: Int { characterId }
    
    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case name
        case imageUrl = "image_url"
        case bio
        case isActive = "is_active"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case problems
    }
}

struct Problem: Codable, Identifiable {
    let problemId: Int
    let name: String
    let iconUrl: String?
    let shortDescription: String?
    let longDescription: String?
    let severityLevel: Int?
    let tags: [String]?
    let createdBy: UUID?
    let isActive: Bool
    let deletedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { problemId }
    
    enum CodingKeys: String, CodingKey {
        case problemId = "problem_id"
        case name
        case iconUrl = "icon_url"
        case shortDescription = "short_description"
        case longDescription = "long_description"
        case severityLevel = "severity_level"
        case tags
        case createdBy = "created_by"
        case isActive = "is_active"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WeeklyQuestion: Codable, Identifiable {
    let questionId: Int
    let columnId: Int
    let questionText: String
    let sequenceOrder: Int?
    let isRequired: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { questionId }
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case columnId = "column_id"
        case questionText = "question_text"
        case sequenceOrder = "sequence_order"
        case isRequired = "is_required"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserWeeklyProgress: Codable, Identifiable {
    let progressId: Int
    let userId: UUID
    let columnId: Int
    let lastQuestionId: Int?
    let startedAt: Date?
    let completedAt: Date?
    let lastAccessed: Date?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { progressId }
    
    enum CodingKeys: String, CodingKey {
        case progressId = "progress_id"
        case userId = "user_id"
        case columnId = "column_id"
        case lastQuestionId = "last_question_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case lastAccessed = "last_accessed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 
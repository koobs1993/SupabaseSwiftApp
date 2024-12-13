import Foundation

enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case text
    case scale
    case checklist
}

struct PsychTest: Codable, Identifiable {
    let testId: Int
    let title: String
    let imageUrl: String?
    let durationMinutes: Int
    let totalQuestions: Int
    let description: String?
    let information: String?
    let isActive: Bool
    let deletedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    var benefits: [TestBenefit]?
    var userProgress: UserTest?
    
    var id: Int { testId }
    
    enum CodingKeys: String, CodingKey {
        case testId = "test_id"
        case title
        case imageUrl = "image_url"
        case durationMinutes = "duration_minutes"
        case totalQuestions = "total_questions"
        case description
        case information
        case isActive = "is_active"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case benefits = "testbenefits"
        case userProgress = "usertests"
    }
}

struct TestBenefit: Codable, Identifiable {
    let benefitId: Int
    let testId: Int
    let iconUrl: String?
    let benefitText: String
    let displayOrder: Int
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { benefitId }
    
    enum CodingKeys: String, CodingKey {
        case benefitId = "benefit_id"
        case testId = "test_id"
        case iconUrl = "icon_url"
        case benefitText = "benefit_text"
        case displayOrder = "display_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct TestQuestion: Codable, Identifiable {
    let questionId: Int
    let testId: Int
    let questionText: String
    let questionType: QuestionType
    let sequenceOrder: Int?
    let metadata: [String: Any]?
    let isRequired: Bool
    let createdAt: Date
    let updatedAt: Date
    var options: [QuestionOption]?
    
    var id: Int { questionId }
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case testId = "test_id"
        case questionText = "question_text"
        case questionType = "question_type"
        case sequenceOrder = "sequence_order"
        case metadata
        case isRequired = "is_required"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case options = "questionoptions"
    }
}

struct QuestionOption: Codable, Identifiable {
    let optionId: Int
    let questionId: Int
    let optionText: String
    let scoreValue: Int
    let sequenceOrder: Int?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { optionId }
    
    enum CodingKeys: String, CodingKey {
        case optionId = "option_id"
        case questionId = "question_id"
        case optionText = "option_text"
        case scoreValue = "score_value"
        case sequenceOrder = "sequence_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserTest: Codable, Identifiable {
    let userTestId: Int
    let userId: UUID
    let testId: Int
    let lastQuestionId: Int?
    let startTime: Date?
    let completionTime: Date?
    let status: TestStatus
    let testResults: [String: Any]?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { userTestId }
    
    enum CodingKeys: String, CodingKey {
        case userTestId = "user_test_id"
        case userId = "user_id"
        case testId = "test_id"
        case lastQuestionId = "last_question_id"
        case startTime = "start_time"
        case completionTime = "completion_time"
        case status
        case testResults = "test_results"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserTestResponse: Codable, Identifiable {
    let responseId: Int
    let userTestId: Int
    let questionId: Int
    let responseValue: String
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { responseId }
    
    enum CodingKeys: String, CodingKey {
        case responseId = "response_id"
        case userTestId = "user_test_id"
        case questionId = "question_id"
        case responseValue = "response_value"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 
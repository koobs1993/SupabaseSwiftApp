import Foundation

// Enums to match database types
enum CourseStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed
    case archived
}

enum TestStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed
}

// Weekly Column Model
struct WeeklyColumn: Identifiable, Codable {
    let columnId: Int
    let title: String
    let content: String?
    let featuredImageUrl: String?
    let sequenceNumber: Int?
    let publishDate: Date?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
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
    }
}

// Course Model
struct Course: Identifiable, Codable {
    let courseId: Int
    let title: String
    let description: String?
    let featuredImage: String?
    let sequenceOrder: Int?
    let totalLessons: Int
    let estimatedCompletionTime: TimeInterval?
    let isActive: Bool
    let createdBy: UUID
    let deletedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case title
        case description
        case featuredImage = "featured_image"
        case sequenceOrder = "sequence_order"
        case totalLessons = "total_lessons"
        case estimatedCompletionTime = "estimated_completion_time"
        case isActive = "is_active"
        case createdBy = "created_by"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Test Model
struct PsychTest: Identifiable, Codable {
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
    }
}

// User Course Progress
struct UserCourse: Identifiable, Codable {
    let userCourseId: Int
    let userId: UUID
    let courseId: Int
    let startDate: Date?
    let completionDate: Date?
    let status: CourseStatus
    let lastAccessed: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userCourseId = "user_course_id"
        case userId = "user_id"
        case courseId = "course_id"
        case startDate = "start_date"
        case completionDate = "completion_date"
        case status
        case lastAccessed = "last_accessed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// User Test Progress
struct UserTest: Identifiable, Codable {
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
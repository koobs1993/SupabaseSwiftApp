import Foundation

enum CourseStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case archived = "archived"
}

struct Course: Codable, Identifiable {
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
    var lessons: [Lesson]?
    var progress: UserCourse?
    
    var id: Int { courseId }
    
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
        case lessons
        case progress = "usercourses"
    }
}

struct Lesson: Codable, Identifiable {
    let lessonId: Int
    let courseId: Int
    let title: String
    let content: String?
    let sequenceOrder: Int?
    let totalQuestions: Int
    let estimatedCompletionTime: TimeInterval?
    let deletedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    var questions: [Question]?
    
    var id: Int { lessonId }
    
    enum CodingKeys: String, CodingKey {
        case lessonId = "lesson_id"
        case courseId = "course_id"
        case title
        case content
        case sequenceOrder = "sequence_order"
        case totalQuestions = "total_questions"
        case estimatedCompletionTime = "estimated_completion_time"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case questions
    }
}

struct Question: Codable, Identifiable {
    let questionId: Int
    let lessonId: Int
    let questionText: String
    let questionType: QuestionType
    let sequenceOrder: Int?
    let isRequired: Bool
    let metadata: [String: Any]?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { questionId }
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case lessonId = "lesson_id"
        case questionText = "question_text"
        case questionType = "question_type"
        case sequenceOrder = "sequence_order"
        case isRequired = "is_required"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case text = "text"
    case scale = "scale"
    case checklist = "checklist"
}

struct UserCourse: Codable, Identifiable {
    let userCourseId: Int
    let userId: UUID
    let courseId: Int
    let startDate: Date?
    let completionDate: Date?
    let status: CourseStatus
    let lastAccessed: Date?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { userCourseId }
    
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

struct UserLesson: Codable, Identifiable {
    let userLessonId: Int
    let userCourseId: Int
    let lessonId: Int
    let completionDate: Date?
    let status: CourseStatus
    let lastAccessed: Date?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { userLessonId }
    
    enum CodingKeys: String, CodingKey {
        case userLessonId = "user_lesson_id"
        case userCourseId = "user_course_id"
        case lessonId = "lesson_id"
        case completionDate = "completion_date"
        case status
        case lastAccessed = "last_accessed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserResponse: Codable, Identifiable {
    let responseId: Int
    let userLessonId: Int
    let questionId: Int
    let responseText: String
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { responseId }
    
    enum CodingKeys: String, CodingKey {
        case responseId = "response_id"
        case userLessonId = "user_lesson_id"
        case questionId = "question_id"
        case responseText = "response_text"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 
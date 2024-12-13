import Foundation

// MARK: - Question Models
enum OnboardingQuestionType: String, Codable {
    case singleChoice
    case multipleChoice
    case text
    case date
}

struct OnboardingQuestion: Identifiable, Codable {
    let id: Int
    let section: String
    let subsection: String?
    let question: String
    let type: OnboardingQuestionType
    let options: [String]?
    let maxSelections: Int?
    let isRequired: Bool
    let order: Int
    
    var displayOrder: String {
        "\(section).\(order)"
    }
}

struct OnboardingResponse: Codable {
    let userId: UUID
    let questionId: Int
    var answer: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case questionId = "question_id"
        case answer = "response"
        case createdAt = "created_at"
    }
}

// MARK: - Demographic Models
enum Gender: String, Codable {
    case male = "male"
    case female = "female"
    case preferNotToSpecify = "prefer_not_to_specify"
}

enum AgeRange: String, Codable {
    case age18to24 = "18-24"
    case age25to34 = "25-34"
    case age35to44 = "35-44"
    case age45to54 = "45-54"
    case age55to64 = "55-64"
    case age65Plus = "65+"
}

enum Education: String, Codable {
    case secondaryGeneral = "secondary_general"
    case secondaryVocational = "secondary_vocational"
    case incompleteHigher = "incomplete_higher"
    case bachelors = "bachelors"
    case masters = "masters"
    case doctoral = "doctoral"
}

enum ProfessionalField: String, Codable {
    case education = "education"
    case science = "science"
    case healthcare = "healthcare"
    case it = "it"
    case business = "business"
    case publicService = "public_service"
    case culture = "culture"
    case other = "other"
}

enum MaritalStatus: String, Codable {
    case single = "single"
    case married = "married"
    case cohabiting = "cohabiting"
    case divorced = "divorced"
    case widowed = "widowed"
}

// MARK: - Research Area Models
enum ResearchSituation: String, Codable {
    case veryPositive = "very_positive"
    case ratherPositive = "rather_positive"
    case neutral = "neutral"
    case ratherNegative = "rather_negative"
    case veryNegative = "very_negative"
}

enum Expectation: String, Codable {
    case personalGrowth = "personal_growth"
    case professionalDevelopment = "professional_development"
    case financialWellbeing = "financial_wellbeing"
    case socialRecognition = "social_recognition"
    case selfRealization = "self_realization"
}

enum PrimaryMotivator: String, Codable {
    case financialReward = "financial_reward"
    case professionalInterest = "professional_interest"
    case creativeFullfillment = "creative_fulfillment"
    case socialRecognition = "social_recognition"
    case internalNeed = "internal_need"
}

enum ActivityFrequency: String, Codable {
    case everyDay = "every_day"
    case severalTimesWeek = "several_times_week"
    case onceWeek = "once_week"
    case severalTimesMonth = "several_times_month"
    case veryRarely = "very_rarely"
}

enum InvestmentWillingness: String, Codable {
    case activelyYes = "actively_yes"
    case ratherYes = "rather_yes"
    case neutral = "neutral"
    case ratherNo = "rather_no"
    case definitelyNo = "definitely_no"
}

// MARK: - User Profile
struct UserResearchProfile: Codable {
    let userId: UUID
    var gender: Gender?
    var ageRange: AgeRange?
    var education: Education?
    var professionalField: String?
    var maritalStatus: MaritalStatus?
    var researchSituation: ResearchSituation?
    var expectations: [Expectation]?
    var lifePlans: String?
    var primaryMotivator: PrimaryMotivator?
    var activityFrequency: ActivityFrequency?
    var specificActions: String?
    var investmentWillingness: InvestmentWillingness?
    var achievedResults: String?
    var additionalComments: String?
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case gender
        case ageRange = "age_range"
        case education
        case professionalField = "professional_field"
        case maritalStatus = "marital_status"
        case researchSituation = "research_situation"
        case expectations
        case lifePlans = "life_plans"
        case primaryMotivator = "primary_motivator"
        case activityFrequency = "activity_frequency"
        case specificActions = "specific_actions"
        case investmentWillingness = "investment_willingness"
        case achievedResults = "achieved_results"
        case additionalComments = "additional_comments"
        case completedAt = "completed_at"
    }
} 
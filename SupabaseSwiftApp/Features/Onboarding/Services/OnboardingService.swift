import Foundation
import Supabase

protocol OnboardingServiceProtocol {
    func getQuestions() async throws -> [OnboardingQuestion]
    func saveResponse(userId: UUID, questionId: Int, answer: String) async throws
    func saveUserProfile(_ profile: UserResearchProfile) async throws
    func getUserProfile(userId: UUID) async throws -> UserResearchProfile?
}

class OnboardingService: OnboardingServiceProtocol {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func getQuestions() async throws -> [OnboardingQuestion] {
        let response = try await supabase.database
            .from("onboarding_questions")
            .select()
            .order("section")
            .order("order")
            .execute()
        
        return try response.value
    }
    
    func saveResponse(userId: UUID, questionId: Int, answer: String) async throws {
        try await supabase.database
            .from("onboarding_responses")
            .upsert([
                "user_id": userId,
                "question_id": questionId,
                "response": answer,
                "created_at": ISO8601DateFormatter().string(from: Date())
            ])
            .execute()
    }
    
    func saveUserProfile(_ profile: UserResearchProfile) async throws {
        var data: [String: Any] = [
            "user_id": profile.userId,
            "completed_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Add optional fields if they exist
        if let gender = profile.gender { data["gender"] = gender.rawValue }
        if let ageRange = profile.ageRange { data["age_range"] = ageRange.rawValue }
        if let education = profile.education { data["education"] = education.rawValue }
        if let professionalField = profile.professionalField { data["professional_field"] = professionalField }
        if let maritalStatus = profile.maritalStatus { data["marital_status"] = maritalStatus.rawValue }
        if let researchSituation = profile.researchSituation { data["research_situation"] = researchSituation.rawValue }
        if let expectations = profile.expectations { data["expectations"] = expectations.map { $0.rawValue } }
        if let lifePlans = profile.lifePlans { data["life_plans"] = lifePlans }
        if let primaryMotivator = profile.primaryMotivator { data["primary_motivator"] = primaryMotivator.rawValue }
        if let activityFrequency = profile.activityFrequency { data["activity_frequency"] = activityFrequency.rawValue }
        if let specificActions = profile.specificActions { data["specific_actions"] = specificActions }
        if let investmentWillingness = profile.investmentWillingness { data["investment_willingness"] = investmentWillingness.rawValue }
        if let achievedResults = profile.achievedResults { data["achieved_results"] = achievedResults }
        if let additionalComments = profile.additionalComments { data["additional_comments"] = additionalComments }
        
        try await supabase.database
            .from("user_research_profiles")
            .upsert(data)
            .execute()
    }
    
    func getUserProfile(userId: UUID) async throws -> UserResearchProfile? {
        let response = try await supabase.database
            .from("user_research_profiles")
            .select()
            .eq("user_id", userId)
            .single()
            .execute()
        
        return try? response.value
    }
    
    // Helper method to initialize the questions in the database
    func initializeQuestions() async throws {
        let questions: [[String: Any]] = [
            // I. Socio-Demographic Block
            ["id": 1, "section": "I", "subsection": "Personal Information", "question": "What is your gender?", "type": OnboardingQuestionType.singleChoice.rawValue, "options": ["Male", "Female", "Prefer not to specify"], "is_required": true, "order": 1],
            ["id": 2, "section": "I", "subsection": "Personal Information", "question": "What is your age range?", "type": OnboardingQuestionType.singleChoice.rawValue, "options": ["18-24", "25-34", "35-44", "45-54", "55-64", "65+"], "is_required": true, "order": 2],
            ["id": 3, "section": "I", "subsection": "Personal Information", "question": "What is your education level?", "type": OnboardingQuestionType.singleChoice.rawValue, "options": ["Secondary general", "Secondary vocational", "Incomplete higher education", "Bachelor's degree", "Master's degree", "Candidate/Doctoral degree"], "is_required": true, "order": 3],
            ["id": 4, "section": "I", "subsection": "Personal Information", "question": "What is your professional field?", "type": OnboardingQuestionType.singleChoice.rawValue, "options": ["Education", "Science", "Healthcare", "IT and Technology", "Business and Economics", "Public Service", "Culture and Arts", "Other"], "is_required": true, "order": 4],
            ["id": 5, "section": "I", "subsection": "Personal Information", "question": "What is your marital status?", "type": OnboardingQuestionType.singleChoice.rawValue, "options": ["Single", "Married", "Cohabiting", "Divorced", "Widowed"], "is_required": true, "order": 5],
            
            // II. Consciousness Block
            ["id": 6, "section": "II", "subsection": "Opinions and Expectations", "question": "How do you evaluate the current situation in our research area?", "type": OnboardingQuestionType.singleChoice.rawValue, "options": ["Very positive", "Rather positive", "Neutral", "Rather negative", "Very negative"], "is_required": true, "order": 1],
            ["id": 7, "section": "II", "subsection": "Opinions and Expectations", "question": "What are your main expectations from our research area?", "type": OnboardingQuestionType.multipleChoice.rawValue, "options": ["Personal growth", "Professional development", "Financial well-being", "Social recognition", "Self-realization"], "max_selections": 3, "is_required": true, "order": 2],
            ["id": 8, "section": "II", "subsection": "Opinions and Expectations", "question": "What are your life plans for the next 3 years?", "type": OnboardingQuestionType.text.rawValue, "is_required": true, "order": 3],
            ["id": 9, "section": "II", "subsection": "Motivation", "question": "What is your primary motivator?", "type": OnboardingQuestionType.singleChoice.rawValue, "options": ["Financial reward", "Professional interest", "Creative self-fulfillment", "Social recognition", "Internal need"], "is_required": true, "order": 4],
            
            // III. Behavioral Block
            ["id": 10, "section": "III", "subsection": "Actual Actions", "question": "How often do you engage in research activities?", "type": OnboardingQuestionType.singleChoice.rawValue, "options": ["Every day", "Several times a week", "Once a week", "Several times a month", "Very rarely"], "is_required": true, "order": 1],
            ["id": 11, "section": "III", "subsection": "Actual Actions", "question": "What specific actions have you taken in the research area over the past year?", "type": OnboardingQuestionType.text.rawValue, "is_required": true, "order": 2],
            ["id": 12, "section": "III", "subsection": "Actual Actions", "question": "Are you willing to invest time/resources in this direction?", "type": OnboardingQuestionType.singleChoice.rawValue, "options": ["Yes, actively", "Rather yes", "Neutral", "Rather no", "Definitely no"], "is_required": true, "order": 3],
            ["id": 13, "section": "III", "subsection": "Activity Results", "question": "What results have you achieved in the research area?", "type": OnboardingQuestionType.text.rawValue, "is_required": true, "order": 4],
            ["id": 14, "section": "III", "subsection": "Additional", "question": "Is there anything you would like to add or comment on?", "type": OnboardingQuestionType.text.rawValue, "is_required": false, "order": 5]
        ]
        
        try await supabase.database
            .from("onboarding_questions")
            .upsert(questions)
            .execute()
    }
} 
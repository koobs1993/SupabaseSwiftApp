import Foundation
import Supabase

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var questions: [OnboardingQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var responses: [Int: String] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingSuccess = false
    @Published var currentSection = "I"
    @Published var profile = UserResearchProfile(userId: UUID())
    
    private let service: OnboardingServiceProtocol
    private let userId: UUID
    
    init(service: OnboardingServiceProtocol, userId: UUID) {
        self.service = service
        self.userId = userId
        self.profile.userId = userId
    }
    
    convenience init(supabase: SupabaseClient, userId: UUID) {
        self.init(service: OnboardingService(supabase: supabase), userId: userId)
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    var currentQuestion: OnboardingQuestion? {
        questions[safe: currentQuestionIndex]
    }
    
    var currentSectionQuestions: [OnboardingQuestion] {
        questions.filter { $0.section == currentSection }
    }
    
    func fetchQuestions() async {
        isLoading = true
        error = nil
        
        do {
            questions = try await service.getQuestions()
            if let existingProfile = try await service.getUserProfile(userId: userId) {
                profile = existingProfile
                showingSuccess = true
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func submitResponse(_ answer: String) async {
        guard let question = currentQuestion else { return }
        
        do {
            try await service.saveResponse(
                userId: userId,
                questionId: question.id,
                answer: answer
            )
            
            responses[question.id] = answer
            updateProfile(questionId: question.id, answer: answer)
            
            if currentQuestionIndex == questions.count - 1 {
                profile.completedAt = Date()
                try await service.saveUserProfile(profile)
                showingSuccess = true
            } else {
                let nextQuestion = questions[currentQuestionIndex + 1]
                if nextQuestion.section != currentSection {
                    currentSection = nextQuestion.section
                }
                currentQuestionIndex += 1
            }
        } catch {
            self.error = error
        }
    }
    
    private func updateProfile(questionId: Int, answer: String) {
        switch questionId {
        case 1: // Gender
            profile.gender = Gender(rawValue: answer.lowercased())
        case 2: // Age Range
            profile.ageRange = AgeRange(rawValue: answer)
        case 3: // Education
            profile.education = Education(rawValue: answer.lowercased().replacingOccurrences(of: " ", with: "_"))
        case 4: // Professional Field
            profile.professionalField = answer
        case 5: // Marital Status
            profile.maritalStatus = MaritalStatus(rawValue: answer.lowercased())
        case 6: // Research Situation
            profile.researchSituation = ResearchSituation(rawValue: answer.lowercased().replacingOccurrences(of: " ", with: "_"))
        case 7: // Expectations
            let expectations = answer.components(separatedBy: ",").compactMap {
                Expectation(rawValue: $0.trimmingCharacters(in: .whitespaces).lowercased().replacingOccurrences(of: " ", with: "_"))
            }
            profile.expectations = expectations
        case 8: // Life Plans
            profile.lifePlans = answer
        case 9: // Primary Motivator
            profile.primaryMotivator = PrimaryMotivator(rawValue: answer.lowercased().replacingOccurrences(of: " ", with: "_"))
        case 10: // Activity Frequency
            profile.activityFrequency = ActivityFrequency(rawValue: answer.lowercased().replacingOccurrences(of: " ", with: "_"))
        case 11: // Specific Actions
            profile.specificActions = answer
        case 12: // Investment Willingness
            profile.investmentWillingness = InvestmentWillingness(rawValue: answer.lowercased().replacingOccurrences(of: " ", with: "_"))
        case 13: // Achieved Results
            profile.achievedResults = answer
        case 14: // Additional Comments
            profile.additionalComments = answer
        default:
            break
        }
    }
    
    func moveToSection(_ section: String) {
        guard let firstQuestionIndex = questions.firstIndex(where: { $0.section == section }) else { return }
        currentQuestionIndex = firstQuestionIndex
        currentSection = section
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 
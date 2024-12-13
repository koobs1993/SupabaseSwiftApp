import Foundation
import Supabase

@MainActor
class WeeklyColumnViewModel: ObservableObject {
    @Published var columns: [WeeklyColumn] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let service: WeeklyColumnServiceProtocol
    
    init(service: WeeklyColumnServiceProtocol) {
        self.service = service
    }
    
    convenience init(supabase: SupabaseClient) {
        self.init(service: WeeklyColumnService(supabase: supabase))
    }
    
    func fetchColumns() async {
        isLoading = true
        error = nil
        
        do {
            columns = try await service.fetchColumns()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

@MainActor
class WeeklyQuestionViewModel: ObservableObject {
    @Published var questions: [WeeklyQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var responses: [Int: String] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isCompleted = false
    
    private let service: WeeklyColumnServiceProtocol
    private let columnId: Int
    private let userId: UUID
    
    init(service: WeeklyColumnServiceProtocol, columnId: Int, userId: UUID) {
        self.service = service
        self.columnId = columnId
        self.userId = userId
    }
    
    convenience init(supabase: SupabaseClient, columnId: Int, userId: UUID) {
        self.init(service: WeeklyColumnService(supabase: supabase), columnId: columnId, userId: userId)
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    func fetchQuestions() async {
        isLoading = true
        error = nil
        
        do {
            questions = try await service.fetchQuestions(for: columnId)
            responses = try await service.fetchResponses(userId: userId, columnId: columnId)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func submitResponse(_ response: String) async {
        guard let currentQuestion = questions[safe: currentQuestionIndex] else { return }
        
        do {
            try await service.saveResponse(
                userId: userId,
                questionId: currentQuestion.questionId,
                response: response
            )
            
            responses[currentQuestion.questionId] = response
            
            if currentQuestionIndex == questions.count - 1 {
                try await service.saveProgress(
                    userId: userId,
                    columnId: columnId,
                    lastQuestionId: currentQuestion.questionId,
                    completed: true
                )
                isCompleted = true
            } else {
                currentQuestionIndex += 1
                try await service.saveProgress(
                    userId: userId,
                    columnId: columnId,
                    lastQuestionId: currentQuestion.questionId,
                    completed: false
                )
            }
        } catch {
            self.error = error
        }
    }
} 
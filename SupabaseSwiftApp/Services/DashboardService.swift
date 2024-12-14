import Foundation
import Supabase

class DashboardService: ObservableObject {
    @Published var weeklyColumns: [WeeklyColumn] = []
    @Published var courses: [(course: Course, progress: UserCourse?)] = []
    @Published var tests: [(test: PsychTest, progress: UserTest?)] = []
    @Published var characters: [Character] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let supabase: SupabaseClient
    private let userId: UUID
    
    init(supabase: SupabaseClient, userId: UUID) {
        self.supabase = supabase
        self.userId = userId
    }
    
    @MainActor
    func fetchDashboardData() async {
        isLoading = true
        error = nil
        showError = false
        
        await withTaskGroup(of: Void.self) { group in
            // Fetch weekly columns
            group.addTask { await self.fetchWeeklyColumns() }
            
            // Fetch courses
            group.addTask { await self.fetchCourses() }
            
            // Fetch tests
            group.addTask { await self.fetchTests() }
            
            // Fetch characters
            group.addTask { await self.fetchCharacters() }
            
            await group.waitForAll()
        }
        
        isLoading = false
    }
    
    @MainActor
    private func fetchWeeklyColumns() async {
        do {
            let response = try await supabase.database
                .from("weeklycolumns")
                .select("""
                    *,
                    userweeklyprogress!left(*)
                """)
                .eq("is_active", true)
                .order("sequence_number")
                .execute()
            
            weeklyColumns = try response.decode()
        } catch {
            handleError(error, context: "weekly columns")
        }
    }
    
    @MainActor
    private func fetchCourses() async {
        do {
            let response = try await supabase.database
                .from("courses")
                .select("""
                    *,
                    usercourses!left(
                        user_id,
                        course_id,
                        start_date,
                        completion_date,
                        status,
                        last_accessed
                    )
                """)
                .eq("is_active", true)
                .eq("usercourses.user_id", userId)
                .order("sequence_order")
                .execute()
            
            courses = try response.decode()
        } catch {
            handleError(error, context: "courses")
        }
    }
    
    @MainActor
    private func fetchTests() async {
        do {
            let response = try await supabase.database
                .from("psychtests")
                .select("""
                    *,
                    usertests!left(
                        user_id,
                        test_id,
                        start_time,
                        completion_time,
                        status,
                        test_results
                    )
                """)
                .eq("is_active", true)
                .eq("usertests.user_id", userId)
                .execute()
            
            tests = try response.decode()
        } catch {
            handleError(error, context: "tests")
        }
    }
    
    @MainActor
    private func fetchCharacters() async {
        do {
            let response = try await supabase.database
                .from("characters")
                .select("""
                    *,
                    characterproblems!left(
                        problems(*)
                    )
                """)
                .eq("is_active", true)
                .limit(5)
                .execute()
            
            characters = try response.decode()
        } catch {
            handleError(error, context: "characters")
        }
    }
    
    private func handleError(_ error: Error, context: String) {
        self.error = error
        self.errorMessage = "Failed to load \(context): \(error.localizedDescription)"
        self.showError = true
        print("Error fetching \(context): \(error)")
    }
    
    func calculateCourseProgress(_ userCourse: UserCourse?) -> Double {
        guard let userCourse = userCourse else { return 0.0 }
        
        switch userCourse.status {
        case .completed:
            return 1.0
        case .inProgress:
            if let startDate = userCourse.startDate,
               let lastAccessed = userCourse.lastAccessed {
                let totalDuration = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 1
                let completedDuration = Calendar.current.dateComponents([.day], from: startDate, to: lastAccessed).day ?? 0
                return min(Double(completedDuration) / Double(totalDuration), 0.99)
            }
            return 0.5
        case .notStarted, .archived:
            return 0.0
        }
    }
    
    func retryFetch() async {
        await fetchDashboardData()
    }
} 
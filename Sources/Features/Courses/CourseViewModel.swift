import Foundation
import Supabase

@MainActor
class CourseViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var currentCourse: Course?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let courseService: CourseService
    private let userId: UUID
    
    init(supabase: SupabaseClient, userId: UUID) {
        self.courseService = CourseService(supabase: supabase)
        self.userId = userId
    }
    
    func fetchCourses() async {
        isLoading = true
        error = nil
        
        do {
            courses = try await courseService.fetchCourses()
        } catch {
            self.error = error
            print("Error fetching courses: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchCourseDetails(_ courseId: Int) async {
        isLoading = true
        error = nil
        
        do {
            currentCourse = try await courseService.fetchCourseDetails(courseId: courseId)
        } catch {
            self.error = error
            print("Error fetching course details: \(error)")
        }
        
        isLoading = false
    }
    
    func startCourse(_ courseId: Int) async {
        isLoading = true
        error = nil
        
        do {
            try await courseService.startCourse(userId: userId, courseId: courseId)
            await fetchCourseDetails(courseId)
        } catch {
            self.error = error
            print("Error starting course: \(error)")
        }
        
        isLoading = false
    }
    
    func updateProgress(_ courseId: Int, status: CourseStatus) async {
        isLoading = true
        error = nil
        
        do {
            try await courseService.updateCourseProgress(userId: userId, courseId: courseId, status: status)
            await fetchCourseDetails(courseId)
        } catch {
            self.error = error
            print("Error updating course progress: \(error)")
        }
        
        isLoading = false
    }
    
    func startLesson(userCourseId: Int, lessonId: Int) async {
        isLoading = true
        error = nil
        
        do {
            try await courseService.startLesson(userCourseId: userCourseId, lessonId: lessonId)
            if let courseId = currentCourse?.courseId {
                await fetchCourseDetails(courseId)
            }
        } catch {
            self.error = error
            print("Error starting lesson: \(error)")
        }
        
        isLoading = false
    }
    
    func completeLesson(userCourseId: Int, lessonId: Int) async {
        isLoading = true
        error = nil
        
        do {
            try await courseService.completeLesson(userCourseId: userCourseId, lessonId: lessonId)
            if let courseId = currentCourse?.courseId {
                await fetchCourseDetails(courseId)
            }
        } catch {
            self.error = error
            print("Error completing lesson: \(error)")
        }
        
        isLoading = false
    }
    
    func saveResponse(userLessonId: Int, questionId: Int, response: String) async {
        isLoading = true
        error = nil
        
        do {
            try await courseService.saveResponse(userLessonId: userLessonId, questionId: questionId, response: response)
        } catch {
            self.error = error
            print("Error saving response: \(error)")
        }
        
        isLoading = false
    }
    
    func calculateProgress(for course: Course) -> Double {
        guard let progress = course.progress else { return 0.0 }
        
        switch progress.status {
        case .completed:
            return 1.0
        case .inProgress:
            // Calculate based on completed lessons if available
            if let lessons = course.lessons {
                let completedCount = lessons.filter { lesson in
                    // Add logic to check lesson completion status
                    false // Placeholder
                }.count
                return Double(completedCount) / Double(lessons.count)
            }
            return 0.5
        case .notStarted, .archived:
            return 0.0
        }
    }
} 
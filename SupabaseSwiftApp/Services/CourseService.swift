import Foundation
import Supabase

enum CourseError: LocalizedError {
    case fetchFailed
    case notFound
    case invalidData
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch course data"
        case .notFound:
            return "Course not found"
        case .invalidData:
            return "Invalid course data"
        case .networkError:
            return "Network error occurred"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

@MainActor
class CourseService {
    private let supabase: SupabaseClient
    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        setupCache()
    }
    
    private func setupCache() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func fetchCourses() async throws -> [Course] {
        let cacheKey = "courses" as NSString
        
        // Check cache first
        if let cached = cache.object(forKey: cacheKey), !cached.isExpired {
            return cached.courses
        }
        
        do {
            let courses: [Course] = try await supabase.database
                .from("courses")
                .select("""
                    *,
                    usercourses (
                        user_course_id,
                        user_id,
                        course_id,
                        start_date,
                        completion_date,
                        status,
                        last_accessed,
                        created_at,
                        updated_at
                    )
                """)
                .eq("is_active", true)
                .is_("deleted_at", "null")
                .order("sequence_order")
                .execute()
                .value
            
            // Cache the result
            cache.setObject(CacheEntry(courses: courses), forKey: cacheKey)
            return courses
        } catch {
            throw CourseError.fetchFailed
        }
    }
    
    func fetchCourseDetails(courseId: Int) async throws -> Course {
        let cacheKey = "course_\(courseId)" as NSString
        
        // Check cache first
        if let cached = cache.object(forKey: cacheKey), !cached.isExpired {
            return cached.courses[0]
        }
        
        do {
            let course: Course = try await supabase.database
                .from("courses")
                .select("""
                    *,
                    lessons (
                        *,
                        questions (
                            *
                        )
                    ),
                    usercourses (
                        *
                    )
                """)
                .eq("course_id", courseId)
                .single()
                .execute()
                .value
            
            // Cache the result
            cache.setObject(CacheEntry(courses: [course]), forKey: cacheKey)
            return course
        } catch {
            throw CourseError.notFound
        }
    }
    
    func startCourse(userId: UUID, courseId: Int) async throws {
        do {
            try await supabase.database
                .from("usercourses")
                .upsert([
                    "user_id": userId,
                    "course_id": courseId,
                    "start_date": Date(),
                    "status": CourseStatus.inProgress.rawValue,
                    "last_accessed": Date()
                ])
                .execute()
            
            // Invalidate relevant caches
            invalidateCache(for: courseId)
        } catch {
            throw CourseError.invalidData
        }
    }
    
    func updateCourseProgress(userId: UUID, courseId: Int, status: CourseStatus) async throws {
        var data: [String: Any] = [
            "user_id": userId,
            "course_id": courseId,
            "status": status.rawValue,
            "last_accessed": Date(),
            "updated_at": Date()
        ]
        
        if status == .completed {
            data["completion_date"] = Date()
        }
        
        do {
            try await supabase.database
                .from("usercourses")
                .upsert(data)
                .execute()
            
            // Invalidate relevant caches
            invalidateCache(for: courseId)
        } catch {
            throw CourseError.invalidData
        }
    }
    
    func startLesson(userCourseId: Int, lessonId: Int) async throws {
        do {
            try await supabase.database
                .from("userlessons")
                .upsert([
                    "user_course_id": userCourseId,
                    "lesson_id": lessonId,
                    "status": CourseStatus.inProgress.rawValue,
                    "last_accessed": Date()
                ])
                .execute()
            
            // Invalidate relevant caches
            invalidateLessonCache(for: lessonId)
        } catch {
            throw CourseError.invalidData
        }
    }
    
    func completeLesson(userCourseId: Int, lessonId: Int) async throws {
        do {
            try await supabase.database
                .from("userlessons")
                .upsert([
                    "user_course_id": userCourseId,
                    "lesson_id": lessonId,
                    "status": CourseStatus.completed.rawValue,
                    "completion_date": Date(),
                    "last_accessed": Date()
                ])
                .execute()
            
            // Invalidate relevant caches
            invalidateLessonCache(for: lessonId)
        } catch {
            throw CourseError.invalidData
        }
    }
    
    func saveResponse(userLessonId: Int, questionId: Int, response: String) async throws {
        do {
            try await supabase.database
                .from("userresponses")
                .insert([
                    "user_lesson_id": userLessonId,
                    "question_id": questionId,
                    "response_text": response
                ])
                .execute()
        } catch {
            throw CourseError.invalidData
        }
    }
    
    func fetchUserResponses(userLessonId: Int) async throws -> [UserResponse] {
        do {
            return try await supabase.database
                .from("userresponses")
                .select()
                .eq("user_lesson_id", userLessonId)
                .order("created_at")
                .execute()
                .value
        } catch {
            throw CourseError.fetchFailed
        }
    }
    
    // MARK: - Cache Management
    
    private func invalidateCache(for courseId: Int? = nil) {
        if let courseId = courseId {
            cache.removeObject(forKey: "course_\(courseId)" as NSString)
        }
        cache.removeObject(forKey: "courses" as NSString)
    }
    
    private func invalidateLessonCache(for lessonId: Int) {
        // Invalidate any cached courses that might contain this lesson
        invalidateCache()
    }
}

// MARK: - Cache Helper

private class CacheEntry {
    let courses: [Course]
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 300 // 5 minutes
    }
    
    init(courses: [Course]) {
        self.courses = courses
        self.timestamp = Date()
    }
} 
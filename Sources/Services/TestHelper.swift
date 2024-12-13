import Foundation
import Supabase

class TestHelper {
    static let shared = TestHelper()
    private let supabase: SupabaseClient
    
    private init() {
        self.supabase = .shared
    }
    
    // MARK: - Authentication Flow
    func testAuthFlow() async throws {
        // Test Sign Up
        try await testSignUp()
        
        // Test Sign In
        try await testSignIn()
        
        // Test Password Reset
        try await testPasswordReset()
        
        print("✅ Authentication flow tests passed")
    }
    
    // MARK: - Course Flow
    func testCourseFlow() async throws {
        // Test Course Listing
        try await testCourseList()
        
        // Test Course Enrollment
        try await testCourseEnrollment()
        
        // Test Course Progress
        try await testCourseProgress()
        
        print("✅ Course flow tests passed")
    }
    
    // MARK: - Test Flow
    func testPsychTestFlow() async throws {
        // Test Test Listing
        try await testTestList()
        
        // Test Test Session
        try await testTestSession()
        
        // Test Results
        try await testTestResults()
        
        print("✅ Psych test flow tests passed")
    }
    
    // MARK: - Weekly Column Flow
    func testWeeklyColumnFlow() async throws {
        // Test Column Listing
        try await testColumnList()
        
        // Test Column Progress
        try await testColumnProgress()
        
        print("✅ Weekly column flow tests passed")
    }
    
    // MARK: - Character Flow
    func testCharacterFlow() async throws {
        // Test Character Listing
        try await testCharacterList()
        
        // Test Character Details
        try await testCharacterDetails()
        
        // Test Related Characters
        try await testRelatedCharacters()
        
        print("✅ Character flow tests passed")
    }
    
    // MARK: - Chat Flow
    func testChatFlow() async throws {
        // Test Chat Session Creation
        try await testChatSessionCreation()
        
        // Test Message Exchange
        try await testMessageExchange()
        
        // Test Chat History
        try await testChatHistory()
        
        print("✅ Chat flow tests passed")
    }
    
    // MARK: - Profile Flow
    func testProfileFlow() async throws {
        // Test Profile Update
        try await testProfileUpdate()
        
        // Test Settings Update
        try await testSettingsUpdate()
        
        // Test Subscription Management
        try await testSubscriptionManagement()
        
        print("✅ Profile flow tests passed")
    }
    
    // MARK: - Notification Flow
    func testNotificationFlow() async throws {
        // Test Notification Permission
        try await testNotificationPermission()
        
        // Test Notification Reception
        try await testNotificationReception()
        
        print("✅ Notification flow tests passed")
    }
    
    // MARK: - Helper Methods
    private func testSignUp() async throws {
        let response = try await supabase.auth.signUp(
            email: "test@example.com",
            password: "testPassword123"
        )
        assert(response.user != nil, "Sign up failed")
    }
    
    private func testSignIn() async throws {
        let response = try await supabase.auth.signIn(
            email: "test@example.com",
            password: "testPassword123"
        )
        assert(response.user != nil, "Sign in failed")
    }
    
    private func testPasswordReset() async throws {
        try await supabase.auth.resetPasswordForEmail("test@example.com")
    }
    
    private func testCourseList() async throws {
        let response = try await supabase.database
            .from("courses")
            .select()
            .execute()
        assert(!response.data.isEmpty, "No courses found")
    }
    
    private func testCourseEnrollment() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.database
            .from("usercourses")
            .insert([
                "user_id": userId,
                "course_id": 1,
                "status": "not_started"
            ])
            .execute()
    }
    
    private func testCourseProgress() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let response = try await supabase.database
            .from("usercourses")
            .select()
            .eq("user_id", userId)
            .execute()
        assert(!response.data.isEmpty, "No course progress found")
    }
    
    private func testTestList() async throws {
        let response = try await supabase.database
            .from("psychtests")
            .select()
            .execute()
        assert(!response.data.isEmpty, "No tests found")
    }
    
    private func testTestSession() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.database
            .from("usertests")
            .insert([
                "user_id": userId,
                "test_id": 1,
                "status": "not_started"
            ])
            .execute()
    }
    
    private func testTestResults() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let response = try await supabase.database
            .from("usertests")
            .select()
            .eq("user_id", userId)
            .execute()
        assert(!response.data.isEmpty, "No test results found")
    }
    
    private func testColumnList() async throws {
        let response = try await supabase.database
            .from("weeklycolumns")
            .select()
            .execute()
        assert(!response.data.isEmpty, "No weekly columns found")
    }
    
    private func testColumnProgress() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.database
            .from("userweeklyprogress")
            .insert([
                "user_id": userId,
                "column_id": 1
            ])
            .execute()
    }
    
    private func testCharacterList() async throws {
        let response = try await supabase.database
            .from("characters")
            .select()
            .execute()
        assert(!response.data.isEmpty, "No characters found")
    }
    
    private func testCharacterDetails() async throws {
        let response = try await supabase.database
            .from("characters")
            .select("""
                *,
                characterproblems:characterproblems(
                    problems(*)
                )
            """)
            .eq("character_id", 1)
            .single()
            .execute()
        assert(!response.data.isEmpty, "Character details not found")
    }
    
    private func testRelatedCharacters() async throws {
        let response = try await supabase.database
            .from("characterproblems")
            .select("characters(*)")
            .eq("problem_id", 1)
            .execute()
        assert(!response.data.isEmpty, "No related characters found")
    }
    
    private func testChatSessionCreation() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.database
            .from("chatsessions")
            .insert([
                "user_id": userId,
                "status": "active"
            ])
            .execute()
    }
    
    private func testMessageExchange() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.database
            .from("chatmessages")
            .insert([
                "session_id": 1,
                "role": "user",
                "content": "Test message"
            ])
            .execute()
    }
    
    private func testChatHistory() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let response = try await supabase.database
            .from("chatsessions")
            .select("*, chatmessages(*)")
            .eq("user_id", userId)
            .execute()
        assert(!response.data.isEmpty, "No chat history found")
    }
    
    private func testProfileUpdate() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.database
            .from("users")
            .update([
                "first_name": "Test",
                "last_name": "User"
            ])
            .eq("id", userId)
            .execute()
    }
    
    private func testSettingsUpdate() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.database
            .from("userdevicesettings")
            .upsert([
                "user_id": userId,
                "dark_mode_enabled": true
            ])
            .execute()
    }
    
    private func testSubscriptionManagement() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.database
            .from("subscriptions")
            .insert([
                "user_id": userId,
                "product_id": 1,
                "status": "active"
            ])
            .execute()
    }
    
    private func testNotificationPermission() async throws {
        // This would typically be handled by the OS
        print("✓ Notification permission test skipped (requires user interaction)")
    }
    
    private func testNotificationReception() async throws {
        guard let userId = supabase.auth.session?.user.id else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await supabase.database
            .from("pushtokens")
            .insert([
                "user_id": userId,
                "device_token": "test_token",
                "platform": "ios"
            ])
            .execute()
    }
} 
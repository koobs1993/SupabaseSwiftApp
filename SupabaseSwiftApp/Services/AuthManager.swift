import Foundation
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var error: AuthError?
    @Published var isVerifyingEmail = false
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        Task {
            await checkSession()
        }
    }
    
    func signUp(data: SignUpData) async throws {
        do {
            // First create auth user
            let authResponse = try await supabase.auth.signUp(
                email: data.email,
                password: data.password
            )
            
            guard let userId = authResponse.user?.id else {
                throw AuthError.unknown("Failed to get user ID")
            }
            
            // Then create user profile in database
            try await supabase.database
                .from("users")
                .insert([
                    "id": userId,
                    "first_name": data.firstName,
                    "last_name": data.lastName,
                    "email": data.email,
                    "password_hash": "", // Actual hash is handled by Supabase Auth
                    "gender": data.gender.rawValue,
                    "role": data.role.rawValue,
                    "created_at": Date(),
                    "updated_at": Date()
                ])
                .execute()
            
            // Send verification email
            try await sendVerificationEmail(email: data.email)
            
            await checkSession()
        } catch {
            if let sbError = error as? AuthError {
                throw sbError
            }
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Update last login timestamp
            if let userId = supabase.auth.session?.user.id {
                try await supabase.database
                    .from("users")
                    .update([
                        "last_login_at": Date(),
                        "updated_at": Date()
                    ])
                    .eq("id", userId)
                    .execute()
            }
            
            await checkSession()
        } catch {
            if let sbError = error as? AuthError {
                throw sbError
            }
            throw AuthError.invalidCredentials
        }
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "isSubscribed")
    }
    
    func checkSession() async {
        guard let session = supabase.auth.session else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        do {
            let user: User = try await supabase.database
                .from("users")
                .select()
                .eq("id", session.user.id)
                .single()
                .execute()
                .value
            
            currentUser = user
            isAuthenticated = true
            
            // Check email verification status
            isVerifyingEmail = user.emailVerifiedAt == nil
        } catch {
            print("Error fetching user profile: \(error)")
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func sendVerificationEmail(email: String) async throws {
        try await supabase.auth.sendEmailVerification(email: email)
    }
    
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    func updatePassword(newPassword: String) async throws {
        try await supabase.auth.updateUser(attributes: [.password(newPassword)])
        
        // Update password hash in database
        if let userId = currentUser?.id {
            try await supabase.database
                .from("users")
                .update([
                    "updated_at": Date()
                ])
                .eq("id", userId)
                .execute()
        }
    }
    
    func updateProfile(firstName: String?, lastName: String?, phone: String?, gender: Gender?) async throws {
        guard let userId = currentUser?.id else { throw AuthError.unknown("No user logged in") }
        
        var updates: [String: Any] = ["updated_at": Date()]
        
        if let firstName = firstName { updates["first_name"] = firstName }
        if let lastName = lastName { updates["last_name"] = lastName }
        if let phone = phone { updates["phone"] = phone }
        if let gender = gender { updates["gender"] = gender.rawValue }
        
        try await supabase.database
            .from("users")
            .update(updates)
            .eq("id", userId)
            .execute()
        
        await checkSession()
    }
    
    func updateProfileImage(_ imageUrl: String) async throws {
        guard let userId = currentUser?.id else { throw AuthError.unknown("No user logged in") }
        
        try await supabase.database
            .from("users")
            .update([
                "profile_image": imageUrl,
                "updated_at": Date()
            ])
            .eq("id", userId)
            .execute()
        
        await checkSession()
    }
    
    func deleteAccount() async throws {
        guard let userId = currentUser?.id else { throw AuthError.unknown("No user logged in") }
        
        // Soft delete user data
        try await supabase.database
            .from("users")
            .update([
                "deleted_at": Date(),
                "updated_at": Date()
            ])
            .eq("id", userId)
            .execute()
        
        // Sign out and clean up
        try await signOut()
    }
} 
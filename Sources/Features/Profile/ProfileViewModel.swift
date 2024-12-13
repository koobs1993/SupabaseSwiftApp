import Foundation
import StoreKit
import Supabase

enum ProfileError: LocalizedError {
    case invalidPassword
    case invalidPhone
    case invalidEmail
    case updateFailed
    case deletionFailed
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidPassword:
            return "Password must be at least 8 characters long"
        case .invalidPhone:
            return "Please enter a valid phone number"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .updateFailed:
            return "Failed to update profile"
        case .deletionFailed:
            return "Failed to delete account"
        case .exportFailed:
            return "Failed to export user data"
        }
    }
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var availableSubscriptions: [Product] = []
    @Published var isVerifyingEmail = false
    @Published var exportProgress: Double = 0
    
    private let supabase: SupabaseClient
    private let storeKit: StoreKitManager
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        self.storeKit = StoreKitManager.shared
    }
    
    func fetchProfile() async {
        isLoading = true
        error = nil
        
        do {
            let query = supabase.database
                .from("users")
                .select("""
                    *,
                    subscriptions!left(*),
                    userdevicesettings!left(*),
                    notificationsettings!left(*)
                """)
                .eq("id", supabase.auth.session?.user.id ?? "")
                .single()
            
            profile = try await query.execute().value
            isVerifyingEmail = profile?.emailVerifiedAt == nil
            await fetchAvailableSubscriptions()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func updateProfile(firstName: String, lastName: String, phone: String? = nil) async {
        do {
            if let phone = phone {
                guard isValidPhone(phone) else {
                    throw ProfileError.invalidPhone
                }
            }
            
            try await supabase.database
                .from("users")
                .update([
                    "first_name": firstName,
                    "last_name": lastName,
                    "phone": phone
                ])
                .eq("id", supabase.auth.session?.user.id ?? "")
                .execute()
            
            profile?.firstName = firstName
            profile?.lastName = lastName
            profile?.phone = phone
        } catch {
            self.error = error
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard newPassword.count >= 8 else {
            throw ProfileError.invalidPassword
        }
        
        // Verify current password
        try await supabase.auth.signIn(
            email: profile?.email ?? "",
            password: currentPassword
        )
        
        // Update password
        try await supabase.auth.updateUser(
            attributes: [.password(newPassword)]
        )
    }
    
    func updateEmail(newEmail: String) async throws {
        guard isValidEmail(newEmail) else {
            throw ProfileError.invalidEmail
        }
        
        try await supabase.auth.updateUser(
            attributes: [.email(newEmail)]
        )
        
        isVerifyingEmail = true
    }
    
    func sendVerificationEmail() async throws {
        guard let email = profile?.email else { return }
        try await supabase.auth.sendEmailVerification(email: email)
    }
    
    func updateProfileImage(_ imageData: Data) async {
        do {
            let fileName = "\(UUID().uuidString).jpg"
            let path = "profile-images/\(fileName)"
            
            try await supabase.storage
                .from("avatars")
                .upload(
                    path: path,
                    file: imageData,
                    options: FileOptions(contentType: "image/jpeg")
                )
            
            let publicURL = supabase.storage
                .from("avatars")
                .getPublicURL(path: path)
            
            try await supabase.database
                .from("users")
                .update(["profile_image": publicURL])
                .eq("id", supabase.auth.session?.user.id ?? "")
                .execute()
            
            profile?.profileImage = publicURL
        } catch {
            self.error = error
        }
    }
    
    func updateDeviceSettings(_ settings: UserDeviceSettings) async {
        do {
            try await supabase.database
                .from("userdevicesettings")
                .upsert([
                    "user_id": supabase.auth.session?.user.id ?? "",
                    "analytics_enabled": settings.analyticsEnabled,
                    "tracking_authorized": settings.trackingAuthorized,
                    "dark_mode_enabled": settings.darkModeEnabled,
                    "haptics_enabled": settings.hapticsEnabled,
                    "notifications_enabled": settings.notificationsEnabled,
                    "app_version": Bundle.main.appVersionString,
                    "ios_version": UIDevice.current.systemVersion
                ])
                .execute()
            
            profile?.deviceSettings = settings
        } catch {
            self.error = error
        }
    }
    
    func updatePrivacySettings(showProfile: Bool, allowMessages: Bool) async {
        do {
            try await supabase.database
                .from("privacy_settings")
                .upsert([
                    "user_id": supabase.auth.session?.user.id ?? "",
                    "show_profile": showProfile,
                    "allow_messages": allowMessages
                ])
                .execute()
        } catch {
            self.error = error
        }
    }
    
    func exportUserData() async throws -> URL {
        let userId = supabase.auth.session?.user.id ?? ""
        var userData: [String: Any] = [:]
        exportProgress = 0.0
        
        // Fetch user profile
        userData["profile"] = profile
        exportProgress = 0.2
        
        // Fetch courses
        let courses: [Course] = try await supabase.database
            .from("usercourses")
            .select("*")
            .eq("user_id", userId)
            .execute()
            .value
        userData["courses"] = courses
        exportProgress = 0.4
        
        // Fetch test results
        let tests: [UserTest] = try await supabase.database
            .from("usertests")
            .select("*")
            .eq("user_id", userId)
            .execute()
            .value
        userData["tests"] = tests
        exportProgress = 0.6
        
        // Fetch chat history
        let chats: [ChatSession] = try await supabase.database
            .from("chatsessions")
            .select("*")
            .eq("user_id", userId)
            .execute()
            .value
        userData["chats"] = chats
        exportProgress = 0.8
        
        // Create JSON file
        let jsonData = try JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportPath = documentsPath.appendingPathComponent("user_data.json")
        try jsonData.write(to: exportPath)
        
        exportProgress = 1.0
        return exportPath
    }
    
    func deleteAccount() async throws {
        do {
            // Soft delete user data
            try await supabase.database
                .from("users")
                .update([
                    "deleted_at": Date(),
                    "email": "deleted_\(UUID().uuidString)"
                ])
                .eq("id", supabase.auth.session?.user.id ?? "")
                .execute()
            
            // Sign out
            try await signOut()
        } catch {
            throw ProfileError.deletionFailed
        }
    }
    
    private func fetchAvailableSubscriptions() async {
        do {
            let products = try await Product.products(for: Config.subscriptionProductIds)
            availableSubscriptions = products.sorted { $0.price < $1.price }
        } catch {
            self.error = error
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let transaction = try await storeKit.purchase(product)
        
        if let transaction = transaction {
            // Update subscription in Supabase
            try await supabase.database
                .from("subscriptions")
                .upsert([
                    "user_id": supabase.auth.session?.user.id ?? "",
                    "product_id": product.id,
                    "status": SubscriptionStatus.active.rawValue,
                    "start_date": ISO8601DateFormatter().string(from: transaction.purchaseDate),
                    "end_date": ISO8601DateFormatter().string(from: transaction.expirationDate ?? Date.distantFuture)
                ])
                .execute()
            
            await fetchProfile()
        }
        
        return transaction
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await fetchProfile()
        } catch {
            self.error = error
        }
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    // MARK: - Validation Helpers
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = #"^\+?[1-9]\d{1,14}$"#
        return phone.range(of: phoneRegex, options: .regularExpression) != nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
} 
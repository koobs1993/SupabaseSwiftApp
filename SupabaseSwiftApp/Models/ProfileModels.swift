import Foundation

struct UserProfile: Codable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let profileImage: String?
    let gender: Gender?
    let role: UserRole
    let emailVerifiedAt: Date?
    let phone: String?
    let lastLoginAt: Date?
    let deletedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    var deviceSettings: UserDeviceSettings?
    var subscription: Subscription?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case profileImage = "profile_image"
        case gender
        case role
        case emailVerifiedAt = "email_verified_at"
        case phone
        case lastLoginAt = "last_login_at"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deviceSettings = "userdevicesettings"
        case subscription = "subscriptions"
    }
}

struct UserDeviceSettings: Codable {
    let settingsId: Int
    let userId: UUID
    let analyticsEnabled: Bool
    let trackingAuthorized: Bool
    let appVersion: String?
    let iosVersion: String?
    let preferredLanguage: String?
    let darkModeEnabled: Bool
    let hapticsEnabled: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case settingsId = "settings_id"
        case userId = "user_id"
        case analyticsEnabled = "analytics_enabled"
        case trackingAuthorized = "tracking_authorized"
        case appVersion = "app_version"
        case iosVersion = "ios_version"
        case preferredLanguage = "preferred_language"
        case darkModeEnabled = "dark_mode_enabled"
        case hapticsEnabled = "haptics_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Subscription: Codable {
    let subscriptionId: Int
    let userId: UUID
    let productId: Int
    let status: SubscriptionStatus
    let originalTransactionId: String?
    let purchaseDate: Date
    let expiresDate: Date?
    let isTrialPeriod: Bool
    let isInIntroOfferPeriod: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case subscriptionId = "subscription_id"
        case userId = "user_id"
        case productId = "product_id"
        case status
        case originalTransactionId = "original_transaction_id"
        case purchaseDate = "purchase_date"
        case expiresDate = "expires_date"
        case isTrialPeriod = "is_trial_period"
        case isInIntroOfferPeriod = "is_in_intro_offer_period"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum SubscriptionStatus: String, Codable {
    case active = "active"
    case canceled = "canceled"
    case expired = "expired"
    case pending = "pending"
    case failed = "failed"
    case paused = "paused"
} 
import Foundation

enum Gender: String, Codable {
    case male = "male"
    case female = "female"
    case nonBinary = "non_binary"
    case preferNotToSay = "prefer_not_to_say"
}

enum UserRole: String, Codable {
    case user = "user"
    case admin = "admin"
    case moderator = "moderator"
}

struct User: Codable, Identifiable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let passwordHash: String
    let profileImage: String?
    let gender: Gender?
    let role: UserRole
    let emailVerifiedAt: Date?
    let phone: String?
    let lastLoginAt: Date?
    let deletedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case passwordHash = "password_hash"
        case profileImage = "profile_image"
        case gender
        case role
        case emailVerifiedAt = "email_verified_at"
        case phone
        case lastLoginAt = "last_login_at"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 
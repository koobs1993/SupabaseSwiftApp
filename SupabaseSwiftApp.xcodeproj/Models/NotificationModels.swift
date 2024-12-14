import Foundation
import SwiftUI

struct UserNotification: Identifiable, Codable {
    let notificationId: Int
    let userId: UUID
    let title: String
    let message: String
    let notificationType: NotificationType
    let isRead: Bool
    let metadata: [String: String]?
    let actionType: NotificationActionType?
    let thumbnail: String?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { notificationId }
    
    enum CodingKeys: String, CodingKey {
        case notificationId = "notification_id"
        case userId = "user_id"
        case title
        case message
        case notificationType = "notification_type"
        case isRead = "is_read"
        case metadata
        case actionType = "action_type"
        case thumbnail
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum NotificationType: String, Codable {
    case course = "course"
    case test = "test"
    case chat = "chat"
    case system = "system"
    
    var icon: String {
        switch self {
        case .course: return "book.fill"
        case .test: return "clipboard.fill"
        case .chat: return "message.fill"
        case .system: return "bell.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .course: return .blue
        case .test: return .purple
        case .chat: return .green
        case .system: return .orange
        }
    }
}

enum NotificationActionType: String, Codable {
    case openCourse = "open_course"
    case openTest = "open_test"
    case openChat = "open_chat"
    case openProfile = "open_profile"
    case openURL = "open_url"
    case none = "none"
}

struct NotificationSetting: Codable, Identifiable {
    let settingId: Int
    let userId: UUID
    let notificationType: String
    let isEnabled: Bool
    let showPreviews: Bool
    let withSound: Bool
    let withBadge: Bool
    let customSettings: [String: Any]?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { settingId }
    
    enum CodingKeys: String, CodingKey {
        case settingId = "setting_id"
        case userId = "user_id"
        case notificationType = "notification_type"
        case isEnabled = "is_enabled"
        case showPreviews = "show_previews"
        case withSound = "with_sound"
        case withBadge = "with_badge"
        case customSettings = "custom_settings"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UserDevice: Codable, Identifiable {
    let deviceId: Int
    let userId: UUID
    let deviceIdentifier: String
    let deviceName: String?
    let deviceModel: String?
    let deviceType: String?
    let lastActive: Date?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { deviceId }
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case userId = "user_id"
        case deviceIdentifier = "device_identifier"
        case deviceName = "device_name"
        case deviceModel = "device_model"
        case deviceType = "device_type"
        case lastActive = "last_active"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PushToken: Codable, Identifiable {
    let tokenId: Int
    let deviceId: Int
    let pushToken: String
    let environment: EnvironmentType
    let isValid: Bool
    let lastValidated: Date?
    let createdAt: Date
    let updatedAt: Date
    
    var id: Int { tokenId }
    
    enum CodingKeys: String, CodingKey {
        case tokenId = "token_id"
        case deviceId = "device_id"
        case pushToken = "push_token"
        case environment
        case isValid = "is_valid"
        case lastValidated = "last_validated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum EnvironmentType: String, Codable {
    case production = "production"
    case sandbox = "sandbox"
}

enum TimeFrame: String, CaseIterable {
    case all = "All Time"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    
    func filter(_ date: Date) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(date)
        case .week:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
        }
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
} 
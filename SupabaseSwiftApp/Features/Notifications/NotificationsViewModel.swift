import Foundation
import Supabase

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [UserNotification] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedFilter: NotificationType?
    @Published var filterOptions: Set<NotificationType> = []
    @Published var selectedTimeFrame: TimeFrame = .all
    @Published var searchText = ""
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    var filteredAndSearchedNotifications: [UserNotification] {
        notifications
            .filter { notification in
                let typeMatch = filterOptions.isEmpty || filterOptions.contains(notification.type)
                let timeMatch = selectedTimeFrame.filter(notification.createdAt)
                let searchMatch = searchText.isEmpty ||
                    notification.title.localizedCaseInsensitiveContains(searchText) ||
                    notification.message.localizedCaseInsensitiveContains(searchText)
                return typeMatch && timeMatch && searchMatch
            }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var groupedNotifications: [(String, [UserNotification])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredAndSearchedNotifications) { notification -> String in
            if calendar.isDateInToday(notification.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(notification.createdAt) {
                return "Yesterday"
            } else if calendar.isDate(notification.createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else {
                return "Earlier"
            }
        }
        
        let sortedKeys = ["Today", "Yesterday", "This Week", "Earlier"]
        return sortedKeys.compactMap { key in
            guard let notifications = grouped[key] else { return nil }
            return (key, notifications.sorted { $0.createdAt > $1.createdAt })
        }
    }
    
    func fetchNotifications() async {
        isLoading = true
        error = nil
        
        do {
            let query = supabase.database
                .from("notifications")
                .select("*")
                .eq("user_id", supabase.auth.session?.user.id ?? "")
                .order("created_at", ascending: false)
            
            notifications = try await query.execute().value
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func markAsRead(_ notification: UserNotification) async {
        do {
            try await supabase.database
                .from("notifications")
                .update(["is_read": true])
                .eq("notification_id", notification.id)
                .execute()
            
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = UserNotification(
                    id: notification.id,
                    userId: notification.userId,
                    title: notification.title,
                    message: notification.message,
                    type: notification.type,
                    isRead: true,
                    createdAt: notification.createdAt,
                    metadata: notification.metadata,
                    actionType: notification.actionType,
                    thumbnail: notification.thumbnail
                )
            }
        } catch {
            self.error = error
        }
    }
    
    func markAllAsRead() async {
        do {
            try await supabase.database
                .from("notifications")
                .update(["is_read": true])
                .eq("user_id", supabase.auth.session?.user.id ?? "")
                .execute()
            
            notifications = notifications.map { notification in
                UserNotification(
                    id: notification.id,
                    userId: notification.userId,
                    title: notification.title,
                    message: notification.message,
                    type: notification.type,
                    isRead: true,
                    createdAt: notification.createdAt,
                    metadata: notification.metadata,
                    actionType: notification.actionType,
                    thumbnail: notification.thumbnail
                )
            }
        } catch {
            self.error = error
        }
    }
    
    func deleteNotification(_ notification: UserNotification) async {
        do {
            try await supabase.database
                .from("notifications")
                .delete()
                .eq("notification_id", notification.id)
                .execute()
            
            notifications.removeAll { $0.id == notification.id }
        } catch {
            self.error = error
        }
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
} 
import Foundation
import UserNotifications
import UIKit

class PushNotificationHandler: NSObject {
    static let shared = PushNotificationHandler()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    func registerForPushNotifications() {
        notificationCenter.delegate = self
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) { granted, _ in
            guard granted else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func handleNotification(_ notification: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let aps = notification["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let title = alert["title"] as? String,
              let body = alert["body"] as? String else {
            completion()
            return
        }
        
        // Store notification in local database
        Task {
            do {
                try await storeNotification(title: title, body: body, payload: notification)
            } catch {
                print("Error storing notification: \(error)")
            }
            completion()
        }
    }
    
    private func storeNotification(title: String, body: String, payload: [AnyHashable: Any]) async throws {
        guard let supabase = try? SupabaseClient(supabaseURL: URL(string: "YOUR_SUPABASE_URL")!, supabaseKey: "YOUR_SUPABASE_KEY") else {
            return
        }
        
        try await supabase.database
            .from("notifications")
            .insert([
                "user_id": supabase.auth.session?.user.id ?? "",
                "title": title,
                "message": body,
                "type": determineNotificationType(from: payload),
                "metadata": payload
            ])
            .execute()
    }
    
    private func determineNotificationType(from payload: [AnyHashable: Any]) -> String {
        (payload["type"] as? String) ?? "system"
    }
}

extension PushNotificationHandler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotification(response.notification.request.content.userInfo, completion: completionHandler)
    }
} 
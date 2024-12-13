import UIKit
import UserNotifications
import Supabase

class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationManager = NotificationPermissionManager()
    let pushNotificationHandler = PushNotificationHandler.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        notificationManager.startPeriodicCheck()
        pushNotificationHandler.registerForPushNotifications()
        
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushNotificationHandler.handleNotification(notification) {
                // Handle completion
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // Send token to your server
        Task {
            await updateDeviceToken(token)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    private func updateDeviceToken(_ token: String) async {
        do {
            try await SupabaseClient.shared.database
                .from("user_devices")
                .upsert([
                    "user_id": SupabaseClient.shared.auth.session?.user.id ?? "",
                    "device_token": token,
                    "platform": "ios",
                    "device_type": "ios",
                    "is_active": true,
                    "last_active": Date()
                ])
                .execute()
        } catch {
            print("Error updating device token: \(error)")
        }
    }
} 
import Foundation
import UserNotifications
import UIKit

class NotificationPermissionManager: ObservableObject {
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var shouldShowPrompt = false
    
    private let userDefaults = UserDefaults.standard
    private let promptIntervalDays = 7 // Time between re-prompts
    private let maxPrompts = 3 // Maximum number of times to show prompt
    
    private enum UserDefaultsKeys {
        static let lastPromptDate = "lastNotificationPromptDate"
        static let promptCount = "notificationPromptCount"
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationStatus = settings.authorizationStatus
                self?.evaluatePromptNeed()
            }
        }
    }
    
    private func evaluatePromptNeed() {
        guard notificationStatus == .denied else { return }
        
        let promptCount = userDefaults.integer(forKey: UserDefaultsKeys.promptCount)
        guard promptCount < maxPrompts else { return }
        
        if let lastPromptDate = userDefaults.object(forKey: UserDefaultsKeys.lastPromptDate) as? Date {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0
            shouldShowPrompt = daysSinceLastPrompt >= promptIntervalDays
        } else {
            shouldShowPrompt = true
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.updatePromptMetrics()
                self?.checkNotificationStatus()
            }
        }
    }
    
    private func updatePromptMetrics() {
        let currentCount = userDefaults.integer(forKey: UserDefaultsKeys.promptCount)
        userDefaults.set(currentCount + 1, forKey: UserDefaultsKeys.promptCount)
        userDefaults.set(Date(), forKey: UserDefaultsKeys.lastPromptDate)
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func startPeriodicCheck() {
        // Check every day
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.checkNotificationStatus()
        }
    }
} 
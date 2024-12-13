import Foundation
import StoreKit
import UIKit

class ReviewPromptManager: ObservableObject {
    @Published var shouldShowPrompt = false
    
    private let userDefaults = UserDefaults.standard
    private let minimumActionsBeforePrompt = 3
    private let daysBeforeReprompt = 60
    
    private enum UserDefaultsKeys {
        static let lastReviewPromptDate = "lastReviewPromptDate"
        static let hasSubmittedReview = "hasSubmittedReview"
        static let actionCount = "userActionCount"
    }
    
    func incrementActionCount() {
        let currentCount = userDefaults.integer(forKey: UserDefaultsKeys.actionCount)
        userDefaults.set(currentCount + 1, forKey: UserDefaultsKeys.actionCount)
        checkIfShouldPrompt()
    }
    
    private func checkIfShouldPrompt() {
        // Don't show if user has already reviewed
        guard !userDefaults.bool(forKey: UserDefaultsKeys.hasSubmittedReview) else { return }
        
        let actionCount = userDefaults.integer(forKey: UserDefaultsKeys.actionCount)
        guard actionCount >= minimumActionsBeforePrompt else { return }
        
        if let lastPromptDate = userDefaults.object(forKey: UserDefaultsKeys.lastReviewPromptDate) as? Date {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0
            shouldShowPrompt = daysSinceLastPrompt >= daysBeforeReprompt
        } else {
            shouldShowPrompt = true
        }
    }
    
    func recordReviewSubmission() {
        userDefaults.set(true, forKey: UserDefaultsKeys.hasSubmittedReview)
        userDefaults.set(Date(), forKey: UserDefaultsKeys.lastReviewPromptDate)
        shouldShowPrompt = false
    }
    
    func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            recordReviewSubmission()
        }
    }
    
    // Helper method to reset review status (for testing)
    func resetReviewStatus() {
        userDefaults.removeObject(forKey: UserDefaultsKeys.lastReviewPromptDate)
        userDefaults.removeObject(forKey: UserDefaultsKeys.hasSubmittedReview)
        userDefaults.removeObject(forKey: UserDefaultsKeys.actionCount)
    }
} 
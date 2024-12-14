import SwiftUI
import Supabase

// MARK: - Configuration
private enum Config {
    static let supabaseURL = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "YOUR_SUPABASE_URL")!
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "YOUR_SUPABASE_ANON_KEY"
}

extension SupabaseClient {
    static let shared = SupabaseClient(
        supabaseURL: Config.supabaseURL,
        supabaseKey: Config.supabaseAnonKey
    )
}

@main
struct SupabaseSwiftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var notificationManager = NotificationPermissionManager()
    @StateObject private var reviewManager = ReviewPromptManager()
    @StateObject private var authManager: AuthManager
    
    init() {
        let authManager = AuthManager(supabase: .shared)
        _authManager = StateObject(wrappedValue: authManager)
    }
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isSubscribed") private var isSubscribed = false
    @State private var showingNotificationPrompt = false
    @State private var showingReviewPrompt = false
    @State private var showingTestRunner = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasCompletedOnboarding || !isSubscribed {
                    OnboardingView()
                        .environmentObject(authManager)
                } else {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(reviewManager)
                }
                
                if showingNotificationPrompt {
                    NotificationPromptView(
                        permissionManager: notificationManager,
                        isPresented: $showingNotificationPrompt
                    )
                }
                
                if showingReviewPrompt {
                    ReviewPromptView(
                        manager: reviewManager,
                        isPresented: $showingReviewPrompt
                    )
                }
            }
            .onAppear {
                notificationManager.checkNotificationStatus()
            }
            .onChange(of: notificationManager.shouldShowPrompt) { shouldShow in
                showingNotificationPrompt = shouldShow
            }
            .onChange(of: reviewManager.shouldShowPrompt) { shouldShow in
                withAnimation {
                    showingReviewPrompt = shouldShow
                }
            }
            .sheet(isPresented: $showingTestRunner) {
                TestRunnerView()
            }
            .overlay(alignment: .bottomTrailing) {
                #if DEBUG
                Button {
                    showingTestRunner.toggle()
                } label: {
                    Image(systemName: "hammer.circle.fill")
                        .font(.title)
                        .padding()
                }
                #endif
            }
        }
    }
} 
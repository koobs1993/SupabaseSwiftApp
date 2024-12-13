import Foundation

enum Config {
    static let supabaseURL = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "")!
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    static let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    
    enum App {
        static let name = "SupabaseSwiftApp"
        static let bundleIdentifier = "com.yourdomain.supabaseswiftapp"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    enum Features {
        static let enablePushNotifications = true
        static let enableInAppPurchases = true
        static let enableAnalytics = true
    }
    
    enum Cache {
        static let maxSizeMB = 50
        static let durationDays = 7
    }
    
    enum Network {
        static let timeoutSeconds = 30
        static let maxRetryAttempts = 3
    }
    
    static func validate() -> Bool {
        guard !supabaseURL.absoluteString.isEmpty else {
            print("Error: SUPABASE_URL not set")
            return false
        }
        
        guard !supabaseAnonKey.isEmpty else {
            print("Error: SUPABASE_ANON_KEY not set")
            return false
        }
        
        guard !openAIKey.isEmpty else {
            print("Error: OPENAI_API_KEY not set")
            return false
        }
        
        return true
    }
} 
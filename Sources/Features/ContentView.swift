import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var reviewManager: ReviewPromptManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                HomeView()
                    .onAppear {
                        // Increment action count when user views home screen
                        reviewManager.incrementActionCount()
                    }
            } else {
                AuthView()
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var reviewManager: ReviewPromptManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to SupabaseSwiftApp")
                    .font(.title)
                    .padding()
                
                Button("Sign Out") {
                    Task {
                        try? await authManager.signOut()
                    }
                }
                .padding()
                
                // Example of tracking meaningful user actions
                Button("Complete Action") {
                    // Increment action count when user completes a meaningful action
                    reviewManager.incrementActionCount()
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var reviewManager: ReviewPromptManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(isSignUp ? "Sign Up" : "Sign In") {
                    Task {
                        do {
                            if isSignUp {
                                try await authManager.signUp(email: email, password: password)
                                // Increment action count when user signs up
                                reviewManager.incrementActionCount()
                            } else {
                                try await authManager.signIn(email: email, password: password)
                                // Increment action count when user signs in
                                reviewManager.incrementActionCount()
                            }
                        } catch {
                            print("Authentication error: \(error)")
                        }
                    }
                }
                .padding()
                
                Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                    isSignUp.toggle()
                }
            }
            .padding()
            .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager())
            .environmentObject(ReviewPromptManager())
    }
} 
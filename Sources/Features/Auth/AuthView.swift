import SwiftUI

struct AuthView: View {
    @State private var isSignUp = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                // Logo or App Name
                Text("Welcome")
                    .font(.largeTitle)
                    .bold()
                    .padding(.vertical, 32)
                
                if isSignUp {
                    SignUpView(isSignUp: $isSignUp)
                } else {
                    SignInView(isSignUp: $isSignUp)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct SignInView: View {
    @Binding var isSignUp: Bool
    @StateObject private var viewModel = SignInViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Email Field
            TextField("Email", text: $viewModel.data.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            // Password Field
            SecureField("Password", text: $viewModel.data.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)
            
            // Sign In Button
            Button(action: {
                Task {
                    await viewModel.signIn(using: authManager)
                }
            }) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!viewModel.data.isValid || authManager.isLoading)
            
            // Error Message
            if let error = authManager.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Switch to Sign Up
            Button("Don't have an account? Sign Up") {
                isSignUp = true
            }
            .foregroundColor(.blue)
        }
    }
}

struct SignUpView: View {
    @Binding var isSignUp: Bool
    @StateObject private var viewModel = SignUpViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // First Name
                TextField("First Name", text: $viewModel.data.firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.givenName)
                
                // Last Name
                TextField("Last Name", text: $viewModel.data.lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.familyName)
                
                // Email
                TextField("Email", text: $viewModel.data.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                // Password
                SecureField("Password", text: $viewModel.data.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.newPassword)
                
                // Confirm Password
                SecureField("Confirm Password", text: $viewModel.data.confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.newPassword)
                
                // Gender Selection
                Picker("Gender", selection: $viewModel.data.gender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName)
                            .tag(gender)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Sign Up Button
                Button(action: {
                    Task {
                        await viewModel.signUp(using: authManager)
                    }
                }) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign Up")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!viewModel.data.isValid || authManager.isLoading)
                
                // Error Message
                if let error = authManager.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Switch to Sign In
                Button("Already have an account? Sign In") {
                    isSignUp = false
                }
                .foregroundColor(.blue)
            }
        }
    }
}

class SignInViewModel: ObservableObject {
    @Published var data = SignInData()
}

class SignUpViewModel: ObservableObject {
    @Published var data = SignUpData()
    
    func signUp(using authManager: AuthManager) async {
        do {
            try await authManager.signUp(data: data)
        } catch {
            print("Sign up error: \(error)")
        }
    }
    
    func signIn(using authManager: AuthManager) async {
        do {
            try await authManager.signIn(data: SignInData(email: data.email, password: data.password))
        } catch {
            print("Sign in error: \(error)")
        }
    }
} 
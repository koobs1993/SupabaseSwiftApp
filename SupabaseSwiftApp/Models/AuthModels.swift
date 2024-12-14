import Foundation

struct SignUpData {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var gender: Gender = .preferNotToSay
    var role: UserRole = .user
    
    var isValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        email.contains("@")
    }
}

struct SignInData {
    var email: String = ""
    var password: String = ""
    
    var isValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        email.contains("@")
    }
}

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case emailAlreadyInUse
    case invalidCredentials
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters long"
        case .passwordMismatch:
            return "Passwords do not match"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .invalidCredentials:
            return "Invalid email or password"
        case .unknown(let message):
            return message
        }
    }
} 
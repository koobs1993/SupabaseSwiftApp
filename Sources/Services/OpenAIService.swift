import Foundation

enum OpenAIError: LocalizedError {
    case invalidAPIKey
    case invalidResponse
    case rateLimitExceeded
    case serverError(Int)
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Error decoding response"
        }
    }
}

@MainActor
class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    private var rateLimitRemaining: Int = 3000
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 1.0 // 1 second
    
    init(apiKey: String) {
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    func sendMessage(_ messages: [ChatMessage], temperature: Double = 0.7, maxTokens: Int = 1000) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.invalidAPIKey
        }
        
        // Rate limiting
        if let lastRequest = lastRequestTime,
           Date().timeIntervalSince(lastRequest) < minimumRequestInterval {
            try await Task.sleep(nanoseconds: UInt64(minimumRequestInterval * 1_000_000_000))
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert our messages to OpenAI format
        let openAIMessages = messages.map { message in
            [
                "role": message.role.rawValue,
                "content": message.content
            ]
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4-1106-preview",
            "messages": openAIMessages,
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.invalidResponse
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            lastRequestTime = Date()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.networkError
            }
            
            // Update rate limit info
            if let remaining = httpResponse.value(forHTTPHeaderField: "x-ratelimit-remaining") {
                rateLimitRemaining = Int(remaining) ?? rateLimitRemaining
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decodedResponse = try decoder.decode(OpenAIResponse.self, from: data)
                    return decodedResponse.choices.first?.message.content ?? ""
                } catch {
                    throw OpenAIError.decodingError
                }
            case 401:
                throw OpenAIError.invalidAPIKey
            case 429:
                throw OpenAIError.rateLimitExceeded
            default:
                throw OpenAIError.serverError(httpResponse.statusCode)
            }
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError
        }
    }
}

// MARK: - Response Models

private struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

extension HTTPURLResponse {
    func value(forHTTPHeaderField field: String) -> String? {
        if #available(iOS 13.0, *) {
            return value(forHTTPHeaderField: field)
        } else {
            return allHeaderFields[field] as? String
        }
    }
} 
import Foundation
import Supabase

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage = ""
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentSession: ChatSession?
    @Published var sessions: [ChatSession] = []
    
    let supabase: SupabaseClient
    let userId: UUID
    private var subscription: RealtimeSubscription?
    private let chatService: ChatServiceProtocol
    private let openAI: OpenAIService
    private let minimumResponseDelay: TimeInterval = 1.0
    
    init(supabase: SupabaseClient, userId: UUID) {
        self.supabase = supabase
        self.userId = userId
        self.chatService = ChatService(supabase: supabase)
        self.openAI = OpenAIService(apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "")
    }
    
    func startNewSession() async {
        do {
            currentSession = try await chatService.createSession(userId: userId)
            messages = []
            setupRealtimeSubscription()
            await sendSystemMessage()
        } catch {
            self.error = error
        }
    }
    
    func fetchSessions() async {
        do {
            sessions = try await chatService.fetchSessions(userId: userId)
        } catch {
            self.error = error
        }
    }
    
    private func setupRealtimeSubscription() {
        guard let sessionId = currentSession?.sessionId else { return }
        
        subscription = chatService.setupRealtimeSubscription(sessionId: sessionId) { [weak self] message in
            DispatchQueue.main.async {
                self?.messages.append(message)
            }
        }
    }
    
    private func sendSystemMessage() async {
        await sendMessage(
            role: .system,
            content: """
            You are a psychology-focused AI assistant. Your role is to:
            1. Provide supportive and empathetic responses
            2. Help users explore their thoughts and feelings
            3. Suggest healthy coping strategies and self-care practices
            4. Encourage professional help when appropriate
            5. Maintain clear boundaries about not providing medical advice or therapy
            
            Always be warm, understanding, and non-judgmental. Use a conversational tone while maintaining professionalism.
            """
        )
    }
    
    func sendMessage(role: MessageRole, content: String) async {
        guard let sessionId = currentSession?.sessionId else { return }
        
        do {
            let message = try await chatService.saveMessage(
                sessionId: sessionId,
                userId: userId,
                role: role,
                content: content
            )
            
            messages.append(message)
            
            if role == .user {
                await generateAIResponse()
            }
        } catch {
            self.error = error
        }
    }
    
    private func generateAIResponse() async {
        isLoading = true
        
        do {
            let startTime = Date()
            let response = try await openAI.sendMessage(messages)
            
            // Calculate remaining delay needed
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < minimumResponseDelay {
                try await Task.sleep(nanoseconds: UInt64((minimumResponseDelay - elapsed) * 1_000_000_000))
            }
            
            await sendMessage(role: .assistant, content: response)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func endSession() async {
        guard let sessionId = currentSession?.sessionId else { return }
        
        do {
            // Generate a summary using ChatGPT
            let summaryPrompt = """
            Please provide a brief summary of this conversation, focusing on:
            1. Main topics discussed
            2. Key insights or progress made
            3. Any action items or recommendations given
            Keep it concise and professional.
            """
            
            let summaryMessage = ChatMessage(
                messageId: -1,
                sessionId: sessionId,
                role: .system,
                content: summaryPrompt,
                sentAt: Date(),
                metadata: nil
            )
            
            var summaryMessages = messages
            summaryMessages.append(summaryMessage)
            
            let summary = try await openAI.sendMessage(summaryMessages)
            try await chatService.endSession(sessionId: sessionId, summary: summary)
            
            subscription?.unsubscribe()
            currentSession = nil
        } catch {
            self.error = error
        }
    }
    
    func archiveSession(_ session: ChatSession) async {
        do {
            try await chatService.archiveSession(sessionId: session.sessionId)
            await fetchSessions()
        } catch {
            self.error = error
        }
    }
    
    deinit {
        subscription?.unsubscribe()
    }
} 
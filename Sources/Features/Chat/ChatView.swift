import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var showingHistory = false
    
    init(supabase: SupabaseClient, userId: UUID) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(supabase: supabase, userId: userId))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.currentSession == nil {
                    WelcomeView(
                        onStart: {
                            Task {
                                await viewModel.startNewSession()
                            }
                        },
                        onViewHistory: {
                            showingHistory = true
                        }
                    )
                } else {
                    ChatSessionView(viewModel: viewModel)
                }
            }
            .navigationTitle("Chat")
            .sheet(isPresented: $showingHistory) {
                if let userId = viewModel.userId {
                    ChatHistoryView(supabase: viewModel.supabase, userId: userId)
                }
            }
        }
    }
}

// MARK: - Welcome View
private struct WelcomeView: View {
    let onStart: () -> Void
    let onViewHistory: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "message.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom)
            
            Text("Welcome to Chat")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Chat with our AI assistant about your thoughts and feelings. While this isn't a substitute for professional help, we're here to listen and support you.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button {
                    onStart()
                } label: {
                    Text("Start New Chat")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button {
                    onViewHistory()
                } label: {
                    Text("View Chat History")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .padding()
    }
}

// MARK: - Chat Session View
private struct ChatSessionView: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    @State private var showingEndConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            // Input Area
            VStack(spacing: 8) {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $viewModel.inputMessage, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                    
                    Button {
                        let message = viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !message.isEmpty else { return }
                        
                        Task {
                            await viewModel.sendMessage(role: .user, content: message)
                            viewModel.inputMessage = ""
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(
                                viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .gray
                                : .blue
                            )
                    }
                    .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End Chat") {
                    showingEndConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
        .confirmationDialog(
            "End Chat",
            isPresented: $showingEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Chat", role: .destructive) {
                Task {
                    await viewModel.endSession()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will end your current chat session. You can view it later in chat history.")
        }
    }
}

// MARK: - Chat History View
private struct ChatHistoryView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.sessions) { session in
                    ChatHistoryRow(session: session)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.archiveSession(session)
                                }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }
                }
            }
            .navigationTitle("Chat History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchSessions()
        }
    }
}

private struct ChatHistoryRow: View {
    let session: ChatSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.title ?? "Chat Session")
                    .font(.headline)
                
                Spacer()
                
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let lastMessage = session.messages?.last {
                Text(lastMessage.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                StatusBadge(status: session.status)
                
                if let messageCount = session.messages?.count {
                    Text("\(messageCount) messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Views
private struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.systemGray6))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role != .user {
                Spacer()
            }
        }
    }
}

private struct TypingIndicator: View {
    @State private var animationOffset = 0.0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                        .offset(y: animationOffset)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Spacer()
        }
        .onAppear {
            animationOffset = -5
        }
    }
}

private struct StatusBadge: View {
    let status: ChatStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundColor(statusColor)
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return .green
        case .ended:
            return .blue
        case .archived:
            return .gray
        }
    }
} 
import SwiftUI

// MARK: - Message Components
struct MessageBubble: View {
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
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 6, height: 6)
                    .scaleEffect(dotCount == index ? 1.2 : 1)
                    .animation(.easeInOut(duration: 0.3), value: dotCount)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
                dotCount = (dotCount + 1) % 3
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    let onStart: () -> Void
    let onViewHistory: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Welcome to Psychology Chat")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Chat with our AI assistant for support and guidance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
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
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ChatStatus
    
    var color: Color {
        switch status {
        case .active: return .green
        case .ended: return .blue
        case .archived: return .gray
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Chat History Row
struct ChatHistoryRow: View {
    let session: ChatSession
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatter.string(from: session.startedAt))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                StatusBadge(status: session.status)
            }
            
            if let summary = session.summary {
                Text(summary)
                    .font(.body)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
} 
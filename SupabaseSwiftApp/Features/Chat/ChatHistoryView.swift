import SwiftUI

class ChatHistoryViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabase: SupabaseClient
    private let userId: UUID
    
    init(supabase: SupabaseClient, userId: UUID) {
        self.supabase = supabase
        self.userId = userId
    }
    
    @MainActor
    func fetchSessions() async {
        isLoading = true
        error = nil
        
        do {
            let query = supabase.database
                .from("chatsessions")
                .select("*, chatmessages(*)")
                .eq("user_id", userId)
                .order("started_at", ascending: false)
                .limit(50)
            
            sessions = try await query.execute().value
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func archiveSession(_ session: ChatSession) async {
        do {
            try await supabase.database
                .from("chatsessions")
                .update([
                    "status": ChatStatus.archived.rawValue
                ])
                .eq("session_id", session.sessionId)
                .execute()
            
            await fetchSessions()
        } catch {
            self.error = error
        }
    }
}

struct ChatHistoryView: View {
    @StateObject private var viewModel: ChatHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(supabase: SupabaseClient, userId: UUID) {
        _viewModel = StateObject(wrappedValue: ChatHistoryViewModel(supabase: supabase, userId: userId))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Chat History",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Start a new chat to begin")
                    )
                } else {
                    List {
                        ForEach(viewModel.sessions) { session in
                            NavigationLink(destination: ChatSessionDetailView(session: session)) {
                                ChatHistoryRow(session: session)
                            }
                            .swipeActions {
                                if session.status != .archived {
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
                    }
                }
            }
            .navigationTitle("Chat History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await viewModel.fetchSessions()
        }
    }
}

struct ChatSessionDetailView: View {
    let session: ChatSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Session Info
                VStack(spacing: 8) {
                    HStack {
                        Text(session.startedAt.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        StatusBadge(status: session.status)
                    }
                    
                    if let summary = session.summary {
                        Text(summary)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Messages
                LazyVStack(spacing: 12) {
                    ForEach(session.messages ?? []) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Chat Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if session.status == .active {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Resume") {
                        // TODO: Implement resume chat functionality
                        dismiss()
                    }
                }
            }
        }
    }
} 
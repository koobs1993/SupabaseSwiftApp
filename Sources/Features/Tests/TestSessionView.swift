import SwiftUI

struct TestSessionView: View {
    @StateObject private var viewModel: TestSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmExit = false
    @State private var showingPauseMenu = false
    @State private var showingResults = false
    
    init(supabase: SupabaseClient, userId: UUID, testId: Int) {
        _viewModel = StateObject(wrappedValue: TestSessionViewModel(
            supabase: supabase,
            userId: userId,
            testId: testId
        ))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        Task { await viewModel.fetchQuestions() }
                    }
                } else if viewModel.questions.isEmpty {
                    startTestView
                } else if let results = viewModel.testResults {
                    TestResultsView(results: results)
                } else {
                    questionView
                }
            }
            .navigationTitle(viewModel.questions.isEmpty ? "Psychology Test" : "Question \(viewModel.currentQuestionIndex + 1)/\(viewModel.questions.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        showingConfirmExit = true
                    }
                }
                
                if !viewModel.questions.isEmpty && viewModel.testResults == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(viewModel.isPaused ? "Resume" : "Pause") {
                            if viewModel.isPaused {
                                viewModel.resumeTest()
                            } else {
                                viewModel.pauseTest()
                                showingPauseMenu = true
                            }
                        }
                    }
                }
            }
            .overlay {
                if let timeRemaining = viewModel.timeRemaining {
                    VStack {
                        TimerView(timeRemaining: timeRemaining)
                            .padding()
                        Spacer()
                    }
                }
            }
        }
        .confirmationDialog(
            "Are you sure you want to exit?",
            isPresented: $showingConfirmExit,
            titleVisibility: .visible
        ) {
            Button("Exit Test", role: .destructive) {
                dismiss()
            }
            Button("Continue Test", role: .cancel) {}
        } message: {
            Text("Your progress will be saved, but you'll need to start from the beginning next time.")
        }
        .sheet(isPresented: $showingPauseMenu) {
            PauseMenuView(
                viewModel: viewModel,
                dismiss: dismiss,
                resumeTest: { showingPauseMenu = false }
            )
        }
    }
    
    private var startTestView: some View {
        VStack(spacing: 20) {
            Text("Ready to begin?")
                .font(.title)
                .bold()
            
            VStack(spacing: 16) {
                InfoRow(
                    icon: "clock",
                    title: "Duration",
                    description: "\(viewModel.test?.durationMinutes ?? 0) minutes"
                )
                
                InfoRow(
                    icon: "list.bullet",
                    title: "Questions",
                    description: "\(viewModel.questions.count) questions"
                )
                
                InfoRow(
                    icon: "pause",
                    title: "Breaks",
                    description: "You can pause at any time"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Text("Make sure you're in a quiet place and can focus without interruptions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Button {
                Task {
                    await viewModel.startTest()
                }
            } label: {
                Text("Begin Test")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var questionView: some View {
        VStack {
            // Progress Bar
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(.blue)
                .padding()
            
            if let question = viewModel.questions[safe: viewModel.currentQuestionIndex] {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(question.questionText)
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        QuestionView(
                            question: question,
                            response: viewModel.responses[question.questionId],
                            onResponse: { response in
                                Task {
                                    await viewModel.submitResponse(response, forQuestion: question.questionId)
                                    
                                    if viewModel.isLastQuestion {
                                        await viewModel.submitTest()
                                        showingResults = true
                                    } else {
                                        viewModel.currentQuestionIndex += 1
                                    }
                                }
                            }
                        )
                    }
                    .padding()
                }
                
                // Navigation Buttons
                HStack {
                    if viewModel.currentQuestionIndex > 0 {
                        Button("Previous") {
                            viewModel.currentQuestionIndex -= 1
                        }
                    }
                    
                    Spacer()
                    
                    if viewModel.isLastQuestion {
                        Button {
                            Task {
                                await viewModel.submitTest()
                                showingResults = true
                            }
                        } label: {
                            Text("Submit")
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.responses[question.questionId] == nil)
                    } else {
                        Button {
                            viewModel.currentQuestionIndex += 1
                        } label: {
                            Text("Next")
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.responses[question.questionId] == nil)
                    }
                }
                .padding()
            }
        }
    }
}

struct TimerView: View {
    let timeRemaining: TimeInterval
    
    var body: some View {
        HStack {
            Image(systemName: "clock")
            Text(timeString)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 2)
    }
    
    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(description)
                    .font(.headline)
            }
            
            Spacer()
        }
    }
}

struct PauseMenuView: View {
    @ObservedObject var viewModel: TestSessionViewModel
    let dismiss: DismissAction
    let resumeTest: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Test Paused")
                    .font(.title)
                    .bold()
                
                Text("Take a moment to breathe. When you're ready, tap Resume to continue.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    Button {
                        resumeTest()
                    } label: {
                        Label("Resume Test", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(role: .destructive) {
                        dismiss()
                    } label: {
                        Label("Exit Test", systemImage: "xmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                }
                .padding(.top)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 
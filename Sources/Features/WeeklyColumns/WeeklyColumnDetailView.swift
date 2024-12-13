import SwiftUI
import UIKit

struct WeeklyColumnDetailView: View {
    let column: WeeklyColumn
    @StateObject private var viewModel: WeeklyQuestionViewModel
    @State private var showingContent = false
    @State private var showingErrorAlert = false
    @Environment(\.authManager) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    init(column: WeeklyColumn, supabase: SupabaseClient, userId: UUID) {
        self.column = column
        _viewModel = StateObject(wrappedValue: WeeklyQuestionViewModel(
            supabase: supabase,
            columnId: column.columnId,
            userId: userId
        ))
    }
    
    var body: some View {
        Group {
            if !showingContent {
                QuestionsView(
                    viewModel: viewModel,
                    onComplete: { showingContent = true }
                )
            } else {
                ContentView(column: column)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
        }
        .onChange(of: viewModel.error) { error in
            showingErrorAlert = error != nil
        }
        .task {
            if column.userProgress?.completedAt != nil {
                showingContent = true
            } else {
                await viewModel.fetchQuestions()
            }
        }
    }
}

// MARK: - Questions View
private struct QuestionsView: View {
    @ObservedObject var viewModel: WeeklyQuestionViewModel
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress Bar
            ProgressBar(progress: viewModel.progress)
                .frame(height: 8)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let question = viewModel.questions[safe: viewModel.currentQuestionIndex] {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(question.questionText)
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding(.horizontal)
                        
                        QuestionInputView(
                            response: viewModel.responses[question.questionId] ?? "",
                            isRequired: question.isRequired,
                            onSubmit: { response in
                                Task {
                                    await viewModel.submitResponse(response)
                                    if viewModel.isCompleted {
                                        onComplete()
                                    }
                                }
                            }
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Reflection Questions")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Exit") {
                    dismiss()
                }
            }
        }
    }
}

private struct QuestionInputView: View {
    let response: String
    let isRequired: Bool
    let onSubmit: (String) -> Void
    @State private var inputText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            TextEditor(text: $inputText)
                .frame(height: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2))
                )
                .focused($isFocused)
            
            HStack {
                if isRequired {
                    Text("*Required")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button {
                    onSubmit(inputText)
                    inputText = ""
                    isFocused = false
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 120)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isValidInput ? Color.blue : Color.gray)
                        )
                }
                .disabled(!isValidInput)
            }
        }
        .onAppear {
            inputText = response
        }
    }
    
    private var isValidInput: Bool {
        if isRequired {
            return !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }
}

private struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress)
                    .cornerRadius(4)
                    .animation(.spring(), value: progress)
            }
        }
    }
}

// MARK: - Content View
private struct ContentView: View {
    let column: WeeklyColumn
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Featured Image
                if let url = column.featuredImageUrl {
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title and Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text(column.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let date = column.publishDate {
                            Text(date.formatted(date: .long, time: .omitted))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Content
                    if let content = column.content {
                        Text(content)
                            .font(.body)
                            .lineSpacing(6)
                    }
                    
                    // Characters Section
                    if let characters = column.characters, !characters.isEmpty {
                        CharactersSection(characters: characters)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [
                column.title,
                column.shortDescription,
                URL(string: "yourapp://columns/\(column.columnId)")!
            ])
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Supporting Views
private struct CharactersSection: View {
    let characters: [Character]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Featured Characters")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            ForEach(characters) { character in
                CharacterCard(character: character)
            }
        }
    }
}

private struct CharacterCard: View {
    let character: Character
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let url = character.imageUrl {
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.headline)
                    
                    if let bio = character.bio {
                        Text(isExpanded ? bio : bio.prefix(100) + "...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
} 
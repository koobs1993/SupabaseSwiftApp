import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(supabase: SupabaseClient, userId: UUID) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(supabase: supabase, userId: userId))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.showingSuccess {
                    OnboardingCompletedView()
                } else {
                    QuestionnaireView(viewModel: viewModel)
                }
            }
            .navigationTitle("Research Questionnaire")
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
        .task {
            await viewModel.fetchQuestions()
        }
    }
}

// MARK: - Questionnaire View
private struct QuestionnaireView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var selectedAnswers: Set<String> = []
    @State private var textInput = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress and Section Navigation
            SectionNavigator(
                currentSection: viewModel.currentSection,
                onSectionSelect: { viewModel.moveToSection($0) }
            )
            .padding(.horizontal)
            
            ProgressBar(progress: viewModel.progress)
                .frame(height: 4)
                .padding(.horizontal)
            
            ScrollView {
                if let question = viewModel.currentQuestion {
                    VStack(alignment: .leading, spacing: 24) {
                        // Section and Subsection Headers
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Section \(question.section)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            if let subsection = question.subsection {
                                Text(subsection)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top)
                        
                        // Question
                        Text(question.question)
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        // Answer Input
                        Group {
                            switch question.type {
                            case .singleChoice:
                                SingleChoiceInput(
                                    options: question.options ?? [],
                                    selectedAnswer: viewModel.responses[question.id] ?? "",
                                    onSelect: { answer in
                                        Task {
                                            await viewModel.submitResponse(answer)
                                        }
                                    }
                                )
                                
                            case .multipleChoice:
                                MultipleChoiceInput(
                                    options: question.options ?? [],
                                    maxSelections: question.maxSelections ?? 1,
                                    selectedAnswers: selectedAnswers,
                                    onSubmit: { answers in
                                        Task {
                                            await viewModel.submitResponse(answers.joined(separator: ","))
                                        }
                                    }
                                )
                                
                            case .text:
                                TextInput(
                                    text: $textInput,
                                    isRequired: question.isRequired,
                                    onSubmit: { text in
                                        Task {
                                            await viewModel.submitResponse(text)
                                            textInput = ""
                                        }
                                    }
                                )
                                
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Supporting Views
private struct SectionNavigator: View {
    let currentSection: String
    let onSectionSelect: (String) -> Void
    private let sections = ["I", "II", "III"]
    
    var body: some View {
        HStack {
            ForEach(sections, id: \.self) { section in
                Button {
                    onSectionSelect(section)
                } label: {
                    Text(section)
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(section == currentSection ? Color.blue : Color.clear)
                        )
                        .foregroundColor(section == currentSection ? .white : .blue)
                }
            }
        }
        .padding(.vertical)
    }
}

private struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * progress)
                    .animation(.spring(), value: progress)
            }
        }
    }
}

private struct SingleChoiceInput: View {
    let options: [String]
    let selectedAnswer: String
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    HStack {
                        Text(option)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if option == selectedAnswer {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(option == selectedAnswer ? Color.blue : Color.gray.opacity(0.2))
                    )
                }
            }
        }
    }
}

private struct MultipleChoiceInput: View {
    let options: [String]
    let maxSelections: Int
    @Binding var selectedAnswers: Set<String>
    let onSubmit: ([String]) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    if selectedAnswers.contains(option) {
                        selectedAnswers.remove(option)
                    } else if selectedAnswers.count < maxSelections {
                        selectedAnswers.insert(option)
                    }
                } label: {
                    HStack {
                        Text(option)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedAnswers.contains(option) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedAnswers.contains(option) ? Color.blue : Color.gray.opacity(0.2))
                    )
                }
            }
            
            if !selectedAnswers.isEmpty {
                Button {
                    onSubmit(Array(selectedAnswers))
                    selectedAnswers.removeAll()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top)
            }
        }
    }
}

private struct TextInput: View {
    @Binding var text: String
    let isRequired: Bool
    let onSubmit: (String) -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $text)
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
                    onSubmit(text)
                    isFocused = false
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 120)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isValid ? Color.blue : Color.gray)
                        )
                }
                .disabled(!isValid)
            }
        }
    }
    
    private var isValid: Bool {
        if isRequired {
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }
}

private struct OnboardingCompletedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Thank You!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your responses have been saved. This information will help us provide you with a better experience.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button {
                // Handle completion
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top)
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(supabase: .init(supabaseURL: URL(string: "")!, supabaseKey: ""), userId: UUID())
} 
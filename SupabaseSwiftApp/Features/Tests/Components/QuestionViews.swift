import SwiftUI

struct QuestionView: View {
    let question: TestQuestion
    let response: String?
    let onResponse: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch question.questionType {
            case .multipleChoice:
                MultipleChoiceQuestionView(
                    options: question.options ?? [],
                    selectedOption: response,
                    onSelect: onResponse
                )
            case .scale:
                ScaleQuestionView(
                    value: Int(response ?? "0") ?? 0,
                    onSelect: { onResponse(String($0)) }
                )
            case .text:
                TextQuestionView(
                    text: response ?? "",
                    onSubmit: onResponse
                )
            case .checklist:
                ChecklistQuestionView(
                    options: question.options ?? [],
                    selectedOptions: Set(response?.components(separatedBy: ",") ?? []),
                    onSelect: { onResponse($0.joined(separator: ",")) }
                )
            }
        }
    }
}

struct MultipleChoiceQuestionView: View {
    let options: [QuestionOption]
    let selectedOption: String?
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(options) { option in
                Button {
                    onSelect(String(option.optionId))
                } label: {
                    HStack {
                        Text(option.optionText)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedOption == String(option.optionId) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 2)
                    )
                }
            }
        }
    }
}

struct ScaleQuestionView: View {
    let value: Int
    let onSelect: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
            
            Slider(value: .init(
                get: { Double(value) },
                set: { onSelect(Int($0)) }
            ), in: 0...10, step: 1)
            
            HStack {
                Text("0")
                Spacer()
                Text("10")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

struct TextQuestionView: View {
    @State private var text: String
    let onSubmit: (String) -> Void
    
    init(text: String, onSubmit: @escaping (String) -> Void) {
        self._text = State(initialValue: text)
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            TextEditor(text: $text)
                .frame(height: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
            
            Button("Submit") {
                onSubmit(text)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

struct ChecklistQuestionView: View {
    let options: [QuestionOption]
    let selectedOptions: Set<String>
    let onSelect: (Set<String>) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(options) { option in
                Button {
                    var newSelection = selectedOptions
                    let optionId = String(option.optionId)
                    if selectedOptions.contains(optionId) {
                        newSelection.remove(optionId)
                    } else {
                        newSelection.insert(optionId)
                    }
                    onSelect(newSelection)
                } label: {
                    HStack {
                        Text(option.optionText)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: selectedOptions.contains(String(option.optionId)) ?
                              "checkmark.square.fill" : "square")
                            .foregroundColor(selectedOptions.contains(String(option.optionId)) ?
                                           .blue : .gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 2)
                    )
                }
            }
        }
    }
} 
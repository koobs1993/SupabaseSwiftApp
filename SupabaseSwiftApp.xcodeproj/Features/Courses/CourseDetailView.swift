import SwiftUI

struct CourseDetailView: View {
    let course: Course
    @StateObject private var viewModel: CourseViewModel
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    init(course: Course) {
        self.course = course
        _viewModel = StateObject(wrappedValue: CourseViewModel(supabase: SupabaseClient.shared))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                if let imageUrl = course.featuredImage {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 200)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title and Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let description = course.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Course Stats
                    HStack(spacing: 20) {
                        StatView(
                            icon: "book.fill",
                            value: "\(course.totalLessons)",
                            label: "Lessons"
                        )
                        
                        if let time = course.estimatedCompletionTime {
                            StatView(
                                icon: "clock.fill",
                                value: "\(Int(time/3600))",
                                label: "Hours"
                            )
                        }
                    }
                    
                    // Progress Section
                    if let progress = course.progress {
                        ProgressSection(progress: progress)
                    }
                    
                    // Lessons List
                    if let lessons = course.lessons {
                        LessonsList(lessons: lessons, courseProgress: course.progress)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if course.progress == nil {
                    Button("Start Course") {
                        Task {
                            await viewModel.startCourse(course.id)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
}

struct ProgressSection: View {
    let progress: UserCourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(progress.status.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let date = progress.lastAccessed {
                        Text("Last accessed: \(date.formatted(.relative))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if progress.status == .completed, let date = progress.completionDate {
                    Text("Completed on: \(date.formatted())")
                        .font(.caption)
                        .foregroundColor(.green)
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
}

struct LessonsList: View {
    let lessons: [Lesson]
    let courseProgress: UserCourse?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lessons")
                .font(.headline)
            
            ForEach(lessons.sorted { $0.sequenceOrder ?? 0 < $1.sequenceOrder ?? 0 }) { lesson in
                NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                    LessonRow(lesson: lesson)
                }
            }
        }
    }
}

struct LessonRow: View {
    let lesson: Lesson
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let time = lesson.estimatedCompletionTime {
                    Text("\(Int(time/60)) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
}

struct LessonDetailView: View {
    let lesson: Lesson
    @State private var selectedQuestionIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Lesson Content
                if let content = lesson.content {
                    Text(content)
                        .font(.body)
                }
                
                // Questions
                if let questions = lesson.questions {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reflection Questions")
                            .font(.headline)
                        
                        TabView(selection: $selectedQuestionIndex) {
                            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                                QuestionView(question: question)
                                    .tag(index)
                            }
                        }
                        .frame(height: 300)
                        .tabViewStyle(.page)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(lesson.title)
    }
}

struct QuestionView: View {
    let question: Question
    @State private var response = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.questionText)
                .font(.headline)
            
            switch question.questionType {
            case .text:
                TextField("Your answer", text: $response)
                    .textFieldStyle(.roundedBorder)
            case .multipleChoice:
                // Implement multiple choice UI
                EmptyView()
            case .scale:
                // Implement scale UI
                EmptyView()
            case .checklist:
                // Implement checklist UI
                EmptyView()
            }
            
            Button("Submit") {
                // Handle submission
            }
            .buttonStyle(.borderedProminent)
            .disabled(response.isEmpty)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
}

#Preview {
    NavigationView {
        CourseDetailView(course: Course(
            courseId: 1,
            title: "Sample Course",
            description: "A sample course description",
            featuredImage: nil,
            sequenceOrder: 1,
            totalLessons: 5,
            estimatedCompletionTime: 3600,
            isActive: true,
            createdBy: UUID(),
            deletedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
} 
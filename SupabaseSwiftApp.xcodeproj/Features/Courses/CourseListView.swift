import SwiftUI

struct CourseListView: View {
    @StateObject private var viewModel: CourseViewModel
    @EnvironmentObject private var authManager: AuthManager
    
    init(supabase: SupabaseClient) {
        _viewModel = StateObject(wrappedValue: CourseViewModel(supabase: supabase))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    ErrorView(error: error, retryAction: {
                        Task {
                            await viewModel.fetchCourses()
                        }
                    })
                } else {
                    courseList
                }
            }
            .navigationTitle("Courses")
            .task {
                await viewModel.fetchCourses()
            }
        }
    }
    
    private var courseList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.courses) { course in
                    NavigationLink(destination: CourseDetailView(course: course)) {
                        CourseCard(course: course)
                    }
                }
            }
            .padding()
        }
    }
}

struct CourseCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Course Image
            if let imageUrl = course.featuredImage {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Course Info
            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = course.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Progress and Stats
                HStack {
                    // Lessons count
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                        Text("\(course.totalLessons) lessons")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Progress if available
                    if let progress = course.progress {
                        ProgressView(value: progressPercentage(progress))
                            .frame(width: 100)
                            .tint(progressColor(progress.status))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
    }
    
    private func progressPercentage(_ progress: UserCourse) -> Double {
        switch progress.status {
        case .completed:
            return 1.0
        case .inProgress:
            return 0.5 // You might want to calculate this based on completed lessons
        case .notStarted, .archived:
            return 0.0
        }
    }
    
    private func progressColor(_ status: CourseStatus) -> Color {
        switch status {
        case .completed:
            return .green
        case .inProgress:
            return .blue
        case .notStarted, .archived:
            return .gray
        }
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Error loading courses")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

#Preview {
    CourseListView(supabase: SupabaseClient(supabaseURL: URL(string: "")!, supabaseKey: ""))
        .environmentObject(AuthManager(supabase: SupabaseClient(supabaseURL: URL(string: "")!, supabaseKey: "")))
} 
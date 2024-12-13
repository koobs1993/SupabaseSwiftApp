import SwiftUI

struct DashboardView: View {
    @StateObject private var dashboardService: DashboardService
    @EnvironmentObject var authManager: AuthManager
    
    init(supabase: SupabaseClient, userId: UUID) {
        _dashboardService = StateObject(wrappedValue: DashboardService(supabase: supabase, userId: userId))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if dashboardService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Weekly Columns Section
                    VStack(alignment: .leading) {
                        Text("Weekly Column")
                            .font(.title2)
                            .bold()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(dashboardService.weeklyColumns) { column in
                                    WeeklyColumnView(column: column)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Courses Section
                    VStack(alignment: .leading) {
                        Text("Courses")
                            .font(.title2)
                            .bold()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(dashboardService.courses, id: \.course.courseId) { courseData in
                                    CourseView(
                                        course: courseData.course,
                                        progress: dashboardService.calculateCourseProgress(courseData.progress)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Tests Section
                    VStack(alignment: .leading) {
                        Text("Tests")
                            .font(.title2)
                            .bold()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(dashboardService.tests, id: \.test.testId) { testData in
                                    TestView(test: testData.test, progress: testData.progress)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .task {
            await dashboardService.fetchDashboardData()
        }
        .refreshable {
            await dashboardService.fetchDashboardData()
        }
    }
}

// Component Views
struct WeeklyColumnView: View {
    let column: WeeklyColumn
    
    var body: some View {
        VStack(alignment: .leading) {
            if let imageUrl = column.featuredImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Text(column.title)
                .font(.headline)
            if let content = column.content {
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 200)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct CourseView: View {
    let course: Course
    let progress: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            if let imageUrl = course.featuredImage {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Text(course.title)
                .font(.headline)
            if let description = course.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            ProgressView(value: Double(progress) / 100)
                .tint(.blue)
            
            Text("\(progress)% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if progress < 100 {
                Button("Start Next Lesson") {
                    // Handle navigation to next lesson
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 5)
            }
        }
        .frame(width: 200)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct TestView: View {
    let test: PsychTest
    let progress: UserTest?
    
    var body: some View {
        VStack {
            if let imageUrl = test.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Text(test.title)
                .font(.headline)
            
            if let description = test.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if let progress = progress {
                Text(progress.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(progress.status == .completed ? .green : .blue)
            }
            
            Text("\(test.durationMinutes) minutes")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 180)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
} 
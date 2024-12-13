import SwiftUI

struct WeeklyColumnListView: View {
    @StateObject private var viewModel: WeeklyColumnViewModel
    @Environment(\.authManager) private var authManager
    
    init(supabase: SupabaseClient) {
        _viewModel = StateObject(wrappedValue: WeeklyColumnViewModel(supabase: supabase))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.columns.isEmpty {
                    ContentUnavailableView(
                        "No Columns Available",
                        systemImage: "newspaper",
                        description: Text("Check back later for new weekly columns")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.columns) { column in
                                if let userId = authManager.currentUser?.id {
                                    NavigationLink(
                                        destination: WeeklyColumnDetailView(
                                            column: column,
                                            supabase: authManager.supabase,
                                            userId: userId
                                        )
                                    ) {
                                        WeeklyColumnCard(column: column)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Weekly Columns")
            .refreshable {
                await viewModel.fetchColumns()
            }
        }
        .task {
            await viewModel.fetchColumns()
        }
    }
}

struct WeeklyColumnCard: View {
    let column: WeeklyColumn
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let url = column.featuredImageUrl {
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(column.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(column.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(column.estimatedMinutes) min read", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let date = column.publishDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let progress = column.userProgress {
                    ProgressIndicator(progress: progress)
                }
            }
            .padding(.horizontal)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
    }
}

struct ProgressIndicator: View {
    let progress: UserWeeklyProgress
    
    var body: some View {
        HStack(spacing: 8) {
            if progress.completedAt != nil {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if progress.startedAt != nil {
                Label("In Progress", systemImage: "clock.fill")
                    .foregroundColor(.blue)
            }
        }
        .font(.caption)
        .padding(.top, 4)
    }
} 
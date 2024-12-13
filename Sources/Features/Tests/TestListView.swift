import SwiftUI

struct TestListView: View {
    @StateObject private var viewModel: TestViewModel
    @State private var selectedTest: PsychTest?
    @State private var searchText = ""
    @State private var showingFilters = false
    
    init(supabase: SupabaseClient, userId: UUID) {
        _viewModel = StateObject(wrappedValue: TestViewModel(supabase: supabase, userId: userId))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryButton(
                            title: "All",
                            isSelected: viewModel.selectedCategory == nil,
                            action: { viewModel.selectedCategory = nil }
                        )
                        
                        ForEach(TestCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                isSelected: viewModel.selectedCategory == category,
                                action: { viewModel.selectedCategory = category }
                            )
                        }
                    }
                    .padding()
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search tests", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) { _ in
                            viewModel.searchText = searchText
                            viewModel.updateFilteredTests()
                        }
                }
                .padding(.horizontal)
                
                // Main Content
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let error = viewModel.error {
                        ErrorView(error: error) {
                            Task {
                                await viewModel.fetchTests()
                            }
                        }
                    } else if viewModel.filteredTests.isEmpty {
                        EmptyStateView(
                            showingNoResults: !searchText.isEmpty || viewModel.selectedCategory != nil
                        )
                    } else {
                        testList
                    }
                }
            }
            .navigationTitle("Psychology Tests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .task {
            await viewModel.fetchTests()
        }
        .sheet(item: $selectedTest) { test in
            TestDetailView(test: test)
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(viewModel: viewModel)
        }
    }
    
    private var testList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredTests) { test in
                    TestCard(test: test)
                        .onTapGesture {
                            selectedTest = test
                        }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.fetchTests()
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct FilterView: View {
    @ObservedObject var viewModel: TestViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Status")) {
                    Toggle("Show Completed", isOn: .constant(true))
                    Toggle("Show In Progress", isOn: .constant(true))
                }
                
                Section(header: Text("Duration")) {
                    Toggle("Under 10 minutes", isOn: .constant(true))
                    Toggle("10-20 minutes", isOn: .constant(true))
                    Toggle("Over 20 minutes", isOn: .constant(true))
                }
                
                Section(header: Text("Sort By")) {
                    Picker("Sort Order", selection: .constant(0)) {
                        Text("Newest First").tag(0)
                        Text("Oldest First").tag(1)
                        Text("Duration").tag(2)
                        Text("Popularity").tag(3)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TestCard: View {
    let test: PsychTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Test Image
            if let imageUrl = test.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
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
                // Category Badge
                if let category = test.category {
                    Text(category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                
                // Title
                Text(test.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Description
                if let description = test.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Test Info
                HStack(spacing: 16) {
                    Label("\(test.durationMinutes) min", systemImage: "clock")
                    Label("\(test.totalQuestions) questions", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Progress or Status
                if let progress = test.userProgress {
                    HStack {
                        Image(systemName: statusIcon(for: progress.status))
                            .foregroundColor(statusColor(for: progress.status))
                        Text(progress.status.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(statusColor(for: progress.status))
                        
                        if progress.status == .inProgress {
                            Spacer()
                            Text("Continue")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
    }
    
    private func statusIcon(for status: TestStatus) -> String {
        switch status {
        case .completed:
            return "checkmark.circle.fill"
        case .inProgress:
            return "clock.fill"
        case .notStarted:
            return "circle"
        }
    }
    
    private func statusColor(for status: TestStatus) -> Color {
        switch status {
        case .completed:
            return .green
        case .inProgress:
            return .blue
        case .notStarted:
            return .gray
        }
    }
}

struct EmptyStateView: View {
    let showingNoResults: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: showingNoResults ? "magnifyingglass" : "list.clipboard")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(showingNoResults ? "No Results Found" : "No Tests Available")
                .font(.headline)
            
            Text(showingNoResults ? 
                "Try adjusting your filters or search terms" :
                "Check back later for new psychological tests")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if showingNoResults {
                Button {
                    // Clear filters
                } label: {
                    Text("Clear Filters")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Error Loading Tests")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
} 
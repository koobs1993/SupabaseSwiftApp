import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel: NotificationsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(supabase: SupabaseClient) {
        _viewModel = StateObject(wrappedValue: NotificationsViewModel(supabase: supabase))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.notifications.isEmpty {
                    EmptyNotificationsView()
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Mark All Read") {
                        Task {
                            await viewModel.markAllAsRead()
                        }
                    }
                    .disabled(viewModel.notifications.allSatisfy(\.isRead))
                }
            }
        }
        .task {
            await viewModel.fetchNotifications()
        }
    }
    
    private var notificationsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(
                            title: "All",
                            isSelected: viewModel.selectedFilter == nil,
                            action: { viewModel.selectedFilter = nil }
                        )
                        
                        ForEach(NotificationType.allCases, id: \.self) { type in
                            FilterButton(
                                title: type.rawValue.capitalized,
                                isSelected: viewModel.selectedFilter == type,
                                action: { viewModel.selectedFilter = type }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Notifications
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(viewModel.groupedNotifications, id: \.0) { section in
                        Section(header: NotificationSectionHeader(title: section.0)) {
                            ForEach(section.1) { notification in
                                NotificationRow(notification: notification) {
                                    Task {
                                        await viewModel.markAsRead(notification)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.fetchNotifications()
        }
    }
}

struct NotificationRow: View {
    let notification: UserNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: notification.type.icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(notification.type.color)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(notification.createdAt.timeAgoDisplay())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground).opacity(0.8))
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct EmptyNotificationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Notifications")
                .font(.headline)
            
            Text("You're all caught up!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NotificationsView(supabase: SupabaseClient(supabaseURL: URL(string: "")!, supabaseKey: ""))
} 
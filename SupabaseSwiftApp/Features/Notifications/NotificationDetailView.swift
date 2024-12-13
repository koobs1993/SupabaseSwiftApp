import SwiftUI

struct NotificationDetailView: View {
    let notification: UserNotification
    @Environment(\.dismiss) private var dismiss
    @State private var showingActionSheet = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: notification.type.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(notification.type.color)
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(notification.title)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(notification.createdAt.formatted())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                // Thumbnail if available
                if let thumbnailURL = notification.thumbnail {
                    AsyncImage(url: URL(string: thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 200)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                    }
                }
                
                // Content
                Text(notification.message)
                    .font(.body)
                    .padding()
                
                // Metadata
                if let metadata = notification.metadata {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(Array(metadata.keys), id: \.self) { key in
                            if let value = metadata[key] {
                                MetadataRow(key: key, value: value)
                            }
                        }
                    }
                }
                
                // Action Button
                if let actionType = notification.actionType {
                    ActionButton(type: actionType.rawValue) {
                        showingActionSheet = true
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        shareNotification()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Take Action"),
                message: Text("Choose what to do with this notification"),
                buttons: [
                    .default(Text("View Details"), action: handleAction),
                    .default(Text("Mark as Unread")),
                    .destructive(Text("Delete")),
                    .cancel()
                ]
            )
        }
        .alert("Delete Notification", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                // Handle delete
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this notification?")
        }
    }
    
    private func handleAction() {
        guard let actionType = notification.actionType else { return }
        
        switch actionType {
        case .openCourse:
            // Handle course opening
            break
        case .openTest:
            // Handle test opening
            break
        case .openChat:
            // Handle chat opening
            break
        case .openProfile:
            // Handle profile opening
            break
        case .openURL:
            if let urlString = notification.metadata?["url"],
               let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        case .none:
            break
        }
    }
    
    private func shareNotification() {
        let text = """
        \(notification.title)
        
        \(notification.message)
        
        Received: \(notification.createdAt.formatted())
        """
        
        let activityViewController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

struct MetadataRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text(key.capitalized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.horizontal)
    }
}

struct ActionButton: View {
    let type: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(type.capitalized.replacingOccurrences(of: "_", with: " "))
                    .fontWeight(.medium)
                Image(systemName: "chevron.right")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
} 
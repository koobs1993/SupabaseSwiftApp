import SwiftUI

struct NotificationPromptView: View {
    @ObservedObject var permissionManager: NotificationPermissionManager
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .padding(.top)
                
                // Title
                Text("Stay Updated")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Description
                Text("Enable notifications to receive important updates about your journey and daily reflections.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    NotificationBenefitRow(
                        icon: "checkmark.circle.fill",
                        text: "Daily reflection reminders"
                    )
                    NotificationBenefitRow(
                        icon: "checkmark.circle.fill",
                        text: "Progress updates"
                    )
                    NotificationBenefitRow(
                        icon: "checkmark.circle.fill",
                        text: "New content alerts"
                    )
                }
                .padding(.vertical)
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        if permissionManager.notificationStatus == .denied {
                            permissionManager.openSettings()
                        } else {
                            permissionManager.requestNotificationPermission()
                        }
                        isPresented = false
                    } label: {
                        Text(permissionManager.notificationStatus == .denied ? "Open Settings" : "Enable Notifications")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        isPresented = false
                    } label: {
                        Text("Maybe Later")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 24)
        }
    }
}

struct NotificationBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
            
            Text(text)
                .font(.subheadline)
        }
    }
} 
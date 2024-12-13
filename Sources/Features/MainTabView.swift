import SwiftUI

enum Tab {
    case dashboard
    case courses
    case tests
    case chat
    case profile
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .courses: return "Courses"
        case .tests: return "Tests"
        case .chat: return "Chat"
        case .profile: return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .courses: return "book.fill"
        case .tests: return "checklist"
        case .chat: return "message.fill"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard
    @State private var showingNotifications = false
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var notificationsViewModel: NotificationsViewModel
    
    init(supabase: SupabaseClient) {
        _notificationsViewModel = StateObject(wrappedValue: NotificationsViewModel(supabase: supabase))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                if let userId = authManager.currentUser?.id {
                    DashboardView(supabase: authManager.supabase, userId: userId)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                NotificationButton(
                                    unreadCount: notificationsViewModel.unreadCount,
                                    action: { showingNotifications = true }
                                )
                            }
                        }
                } else {
                    Text("User not found")
                }
            }
            .tabItem {
                Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
            }
            .tag(Tab.dashboard)
            
            NavigationView {
                if let userId = authManager.currentUser?.id {
                    CourseListView(supabase: authManager.supabase, userId: userId)
                } else {
                    Text("User not found")
                }
            }
            .tabItem {
                Label(Tab.courses.title, systemImage: Tab.courses.icon)
            }
            .tag(Tab.courses)
            
            NavigationView {
                if let userId = authManager.currentUser?.id {
                    TestListView(supabase: authManager.supabase, userId: userId)
                } else {
                    Text("User not found")
                }
            }
            .tabItem {
                Label(Tab.tests.title, systemImage: Tab.tests.icon)
            }
            .tag(Tab.tests)
            
            if let userId = authManager.currentUser?.id {
                ChatView(supabase: authManager.supabase, userId: userId)
            } else {
                Text("User not found")
            }
            .tabItem {
                Label(Tab.chat.title, systemImage: Tab.chat.icon)
            }
            .tag(Tab.chat)
            
            Text("Profile View")
                .tabItem {
                    Label(Tab.profile.title, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(supabase: authManager.supabase)
        }
        .task {
            await notificationsViewModel.fetchNotifications()
        }
    }
}

struct NotificationButton: View {
    let unreadCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                
                if unreadCount > 0 {
                    Text("\(min(unreadCount, 99))")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
} 
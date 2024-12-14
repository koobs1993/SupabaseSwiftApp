import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingImagePicker = false
    @State private var showingEditProfile = false
    @State private var showingSubscriptions = false
    @State private var showingPasswordChange = false
    @State private var showingPrivacySettings = false
    @State private var showingDeleteConfirmation = false
    @State private var showingExportProgress = false
    @State private var selectedImage: UIImage?
    @State private var showingSignOutConfirmation = false
    
    init(supabase: SupabaseClient) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(supabase: supabase))
    }
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    // Profile Section
                    Section {
                        HStack {
                            ProfileImageView(
                                imageURL: viewModel.profile?.profileImage,
                                image: selectedImage
                            )
                            .onTapGesture {
                                showingImagePicker = true
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.profile?.fullName ?? "")
                                    .font(.headline)
                                Text(viewModel.profile?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if viewModel.isVerifyingEmail {
                                    Button("Verify Email") {
                                        Task {
                                            try? await viewModel.sendVerificationEmail()
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.leading)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Account Section
                    Section("Account") {
                        NavigationLink(destination: EditProfileForm(viewModel: viewModel)) {
                            Label("Edit Profile", systemImage: "person")
                        }
                        
                        Button {
                            showingPasswordChange = true
                        } label: {
                            Label("Change Password", systemImage: "lock")
                        }
                        
                        NavigationLink(destination: PrivacySettingsView(viewModel: viewModel)) {
                            Label("Privacy Settings", systemImage: "hand.raised")
                        }
                    }
                    
                    // Subscription Section
                    Section {
                        Button {
                            showingSubscriptions = true
                        } label: {
                            HStack {
                                Label("Subscription", systemImage: "creditcard")
                                Spacer()
                                Text(viewModel.profile?.subscription?.status.rawValue.capitalized ?? "None")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Settings Section
                    Section {
                        NavigationLink(destination: DeviceSettingsView(viewModel: viewModel)) {
                            Label("Device Settings", systemImage: "gearshape")
                        }
                        
                        NavigationLink(destination: HelpSupportView()) {
                            Label("Help & Support", systemImage: "questionmark.circle")
                        }
                        
                        Button {
                            Task {
                                showingExportProgress = true
                                if let url = try? await viewModel.exportUserData() {
                                    let activityVC = UIActivityViewController(
                                        activityItems: [url],
                                        applicationActivities: nil
                                    )
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = windowScene.windows.first {
                                        window.rootViewController?.present(activityVC, animated: true)
                                    }
                                }
                                showingExportProgress = false
                            }
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    // Danger Zone
                    Section {
                        Button(role: .destructive) {
                            showingSignOutConfirmation = true
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Account", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .refreshable {
                await viewModel.fetchProfile()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingSubscriptions) {
                SubscriptionView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingPasswordChange) {
                PasswordChangeView(viewModel: viewModel)
            }
            .onChange(of: selectedImage) { image in
                if let image = image,
                   let data = image.jpegData(compressionQuality: 0.7) {
                    Task {
                        await viewModel.updateProfileImage(data)
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await viewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        try? await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .overlay {
                if showingExportProgress {
                    ExportProgressView(progress: viewModel.exportProgress)
                }
            }
        }
        .task {
            await viewModel.fetchProfile()
        }
    }
}

struct ProfileImageView: View {
    let imageURL: String?
    let image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if let urlString = imageURL,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
        .aspectRatio(contentMode: .fill)
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct EditProfileForm: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    
    var body: some View {
        Form {
            Section {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await viewModel.updateProfile(firstName: firstName, lastName: lastName)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            firstName = viewModel.profile?.firstName ?? ""
            lastName = viewModel.profile?.lastName ?? ""
        }
    }
}

struct DeviceSettingsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var settings: UserDeviceSettings
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _settings = State(initialValue: viewModel.profile?.deviceSettings ?? UserDeviceSettings(
            analyticsEnabled: true,
            trackingAuthorized: false,
            darkModeEnabled: false,
            hapticsEnabled: true,
            notificationsEnabled: true
        ))
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Analytics", isOn: $settings.analyticsEnabled)
                Toggle("Tracking", isOn: $settings.trackingAuthorized)
                Toggle("Dark Mode", isOn: $settings.darkModeEnabled)
                Toggle("Haptics", isOn: $settings.hapticsEnabled)
                Toggle("Notifications", isOn: $settings.notificationsEnabled)
            }
        }
        .navigationTitle("Device Settings")
        .onChange(of: settings) { newSettings in
            Task {
                await viewModel.updateDeviceSettings(newSettings)
            }
        }
    }
}

struct SubscriptionView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            List {
                if let subscription = viewModel.profile?.subscription {
                    Section("Current Subscription") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(subscription.status.rawValue.capitalized)
                                .font(.headline)
                            
                            if let endDate = subscription.endDate {
                                Text("Renews on \(endDate.formatted(date: .long, time: .omitted))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Available Plans") {
                    ForEach(viewModel.availableSubscriptions, id: \.id) { product in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(product.displayName)
                                .font(.headline)
                            
                            Text(product.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(product.displayPrice)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProduct = product
                        }
                    }
                }
                
                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Manage Subscription")
                    }
                    
                    Button {
                        Task {
                            await viewModel.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                    }
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
            .sheet(item: $selectedProduct) { product in
                PurchaseView(product: product, viewModel: viewModel)
            }
        }
    }
}

struct PurchaseView: View {
    let product: Product
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text(product.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(product.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Text(product.displayPrice)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Button {
                        Task {
                            isPurchasing = true
                            do {
                                if try await viewModel.purchase(product) != nil {
                                    dismiss()
                                }
                            } catch {
                                showingError = true
                            }
                            isPurchasing = false
                        }
                    } label: {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Subscribe Now")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isPurchasing)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }
}

struct HelpSupportView: View {
    var body: some View {
        List {
            Section(header: Text("Support")) {
                Link(destination: URL(string: "https://yourapp.com/faq")!) {
                    Label("FAQ", systemImage: "questionmark.circle")
                }
                
                Link(destination: URL(string: "https://yourapp.com/contact")!) {
                    Label("Contact Support", systemImage: "envelope")
                }
                
                Link(destination: URL(string: "https://yourapp.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "lock.shield")
                }
                
                Link(destination: URL(string: "https://yourapp.com/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            }
            
            Section(header: Text("App Information")) {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text(Bundle.main.appVersionString)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Help & Support")
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

struct PasswordChangeView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                Section {
                    Button("Update Password") {
                        Task {
                            do {
                                guard newPassword == confirmPassword else {
                                    errorMessage = "Passwords don't match"
                                    showingError = true
                                    return
                                }
                                
                                try await viewModel.updatePassword(
                                    currentPassword: currentPassword,
                                    newPassword: newPassword
                                )
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showingError = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

struct PrivacySettingsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showProfile = true
    @State private var allowMessages = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Show Profile", isOn: $showProfile)
                Toggle("Allow Messages", isOn: $allowMessages)
            } footer: {
                Text("These settings control who can see your profile and send you messages.")
            }
        }
        .navigationTitle("Privacy Settings")
        .onChange(of: showProfile) { _ in updateSettings() }
        .onChange(of: allowMessages) { _ in updateSettings() }
    }
    
    private func updateSettings() {
        Task {
            await viewModel.updatePrivacySettings(
                showProfile: showProfile,
                allowMessages: allowMessages
            )
        }
    }
}

struct ExportProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                
                Text("Exporting Data...")
                    .font(.headline)
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .shadow(radius: 10)
        }
    }
} 
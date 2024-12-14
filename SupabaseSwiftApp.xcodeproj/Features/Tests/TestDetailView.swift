import SwiftUI

struct TestDetailView: View {
    let test: PsychTest
    @Environment(\.dismiss) private var dismiss
    @State private var showingTest = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                if let imageUrl = test.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 250)
                    .clipShape(Rectangle())
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Test Information
                    VStack(spacing: 12) {
                        InfoBox(
                            icon: "clock",
                            title: "Duration",
                            value: "\(test.durationMinutes) minutes"
                        )
                        
                        InfoBox(
                            icon: "list.bullet",
                            title: "Questions",
                            value: "\(test.totalQuestions) total"
                        )
                    }
                    
                    // Description
                    if let description = test.description {
                        Text("About this test")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Additional Information
                    if let information = test.information {
                        Text("What to expect")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        Text(information)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Benefits
                    if let benefits = test.benefits, !benefits.isEmpty {
                        Text("Benefits")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        ForEach(benefits.sorted(by: { $0.displayOrder < $1.displayOrder })) { benefit in
                            BenefitRow(benefit: benefit)
                        }
                    }
                    
                    // Action Button
                    actionButton
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(test.title)
        .fullScreenCover(isPresented: $showingTest) {
            if let userId = authManager.currentUser?.id {
                TestSessionView(
                    supabase: authManager.supabase,
                    userId: userId,
                    testId: test.testId
                )
            }
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if let progress = test.userProgress {
            switch progress.status {
            case .completed:
                Button {
                    showingTest = true
                } label: {
                    Label("Retake Test", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
            case .inProgress:
                Button {
                    showingTest = true
                } label: {
                    Label("Continue Test", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
            case .notStarted:
                Button {
                    showingTest = true
                } label: {
                    Label("Start Test", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            Button {
                showingTest = true
            } label: {
                Label("Start Test", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct InfoBox: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BenefitRow: View {
    let benefit: TestBenefit
    
    var body: some View {
        HStack(spacing: 12) {
            if let iconUrl = benefit.iconUrl {
                AsyncImage(url: URL(string: iconUrl)) { image in
                    image
                        .resizable()
                        .frame(width: 24, height: 24)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 24, height: 24)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Text(benefit.benefitText)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
} 
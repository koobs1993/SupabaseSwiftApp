import SwiftUI

struct TestResultsView: View {
    let results: [String: Any]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.top)
                
                VStack(spacing: 8) {
                    Text("Test Completed!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Thank you for completing the test")
                        .foregroundColor(.secondary)
                }
                
                // Results Summary
                ResultsSummaryCard(results: results)
                
                Button {
                    dismiss()
                } label: {
                    Text("Return to Tests")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ResultsSummaryCard: View {
    let results: [String: Any]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(results.keys.sorted()), id: \.self) { key in
                if key != "completion_date" {
                    HStack {
                        Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let value = results[key] {
                            if let score = value as? Int {
                                Text("\(score)")
                                    .fontWeight(.medium)
                            } else if let scores = value as? [String: Int] {
                                Text("\(scores.values.reduce(0, +))")
                                    .fontWeight(.medium)
                            } else {
                                Text("\(String(describing: value))")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
            
            if let dateString = results["completion_date"] as? String,
               let date = ISO8601DateFormatter().date(from: dateString) {
                Divider()
                HStack {
                    Text("Completed")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(date.formatted())
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
    }
} 
import SwiftUI

struct ReviewPromptView: View {
    @ObservedObject var manager: ReviewPromptManager
    @Binding var isPresented: Bool
    @State private var rating: Int?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 24) {
                // Close Button
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    Spacer()
                }
                
                // Illustration
                Image(systemName: "star.bubble.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.yellow)
                
                // Question
                Text("How likely are you to recommend\nour app to a friend?")
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Rating buttons
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { number in
                        Button {
                            rating = number
                            if number >= 4 {
                                manager.requestReview()
                            }
                            isPresented = false
                        } label: {
                            Text("\(number)")
                                .font(.headline)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(rating == number ? Color.blue : Color.gray.opacity(0.1))
                                )
                                .foregroundColor(rating == number ? .white : .primary)
                        }
                    }
                }
                
                // Labels
                HStack {
                    Text("Unlikely")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Very likely")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    ReviewPromptView(
        manager: ReviewPromptManager(),
        isPresented: .constant(true)
    )
} 
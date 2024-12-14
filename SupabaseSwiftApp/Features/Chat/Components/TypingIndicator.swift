import SwiftUI

struct TypingIndicator: View {
    @State private var animationPhase = 0
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(shouldAnimate(for: index) ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.horizontal)
        .onReceive(timer) { _ in
            animationPhase = (animationPhase + 1) % 3
        }
    }
    
    private func shouldAnimate(for index: Int) -> Bool {
        index == animationPhase
    }
}

#Preview {
    TypingIndicator()
        .padding()
} 
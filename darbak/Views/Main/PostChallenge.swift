import SwiftUI
import ConfettiSwiftUI
import Lottie

struct PostChallengeView: View {
    @State private var trigger = 0
    @State private var showContent = false
    
    let onBackToHome: () -> Void

    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()

                Text("مبروك!\nخلصت تحدي اليوم")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(DesignSystem.Colors.text)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: showContent)

                // Lottie animation
                LottieView(animation: .named("jumping"))
                    .playing()
                    .looping()
                    .frame(height: 500)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .animation(.easeOut(duration: 1.0).delay(0.5), value: showContent)

                Spacer()
            }
            .padding()

            //button
            VStack {
                Spacer()
                Button(action: {
                    // Call the callback to go back to home
                    onBackToHome()
                }) {
                    Text("العودة للرئيسية")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.invertedText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .shadow(color: DesignSystem.Shadows.medium, radius: 2, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, 20)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 50)
                .animation(.easeOut(duration: 0.6).delay(1.0), value: showContent)
            }
        }
        .onAppear {
            // Start content animations
            withAnimation(.easeOut(duration: 0.3)) {
                showContent = true
            }
            
            // Start confetti timer
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    trigger += 1
            }
        }
        .confettiCannon(
            trigger: $trigger,
            repetitions: 2  ,
            repetitionInterval: 0.9
          
        )
    }
}
#Preview {
    PostChallengeView(onBackToHome: {})
}


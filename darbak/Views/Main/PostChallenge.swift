import SwiftUI
import ConfettiSwiftUI
import Lottie

struct PostChallengeView: View {
    @State private var trigger = 0

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Spacer()

                Text("مبروك!\nخلصت تحدي اليوم")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                // Lottie animation
                LottieView(animation: .named("jumping"))
                    .playing()
                    .looping()
                    .frame(height: 500)

                Spacer()
            }
            .padding()

            //button
            VStack {
                Spacer()
                CustomButton(title: "العودة للرئيسية") {
                    print("Button tapped!")
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
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
    PostChallengeView()
}


//
//  OnboardingView.swift
//  darbak
//
//  Created by Majed on 05/02/1447 AH.
//

import SwiftUI
import Lottie

struct Onboarding: View {
    @EnvironmentObject var user: User
    @State private var navigateToQuiz = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top half - Image section
            Image("OnboardingWithText")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.65)
                .clipShape(
                    RoundedCorner(radius: 24, corners: [.bottomLeft, .bottomRight])
                )
            
            // Bottom half - Content section
            VStack() {
            
                
                // Welcome text
                
                
                Spacer()
                
                // Feature highlights
                VStack(spacing: DesignSystem.Spacing.lg) {
                    FeatureHighlight(
                        icon: "figure.walk",
                        title: "تتبع خطواتك",
                        description: "سجل نشاطك اليومي واطلع على إنجازاتك"
                    )
                    
                    FeatureHighlight(
                        icon: "camera.fill",
                        title: "تحديات تصوير",
                        description: "شارك في تحديات ممتعة ووثق رحلتك"
                    )
                    
                    FeatureHighlight(
                        icon: "trophy.fill",
                        title: "إنجازات وشارات",
                        description: "اكسب نقاط وإنجازات مع كل خطوة"
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                Spacer()
                
                // Action button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    navigateToQuiz = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Text("ابدأ رحلتك")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.35)
            .background(DesignSystem.Colors.background)
        }
        .ignoresSafeArea()
        .navigationDestination(isPresented: $navigateToQuiz) {
            QuizView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

// Simple feature highlight component
struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primaryLight)
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        Onboarding()
            .environmentObject(User())
    }
}

// Custom shape for rounded corners on specific sides
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

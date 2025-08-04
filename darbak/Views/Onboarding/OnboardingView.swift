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
    @State private var navigateToChallenge = false
    
    var body: some View {
        VStack {
            // Main Image
            Image("onboardingPicture")
                .resizable()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.75)
                .clipShape(
                    .rect(
                        bottomLeadingRadius: 80,
                        bottomTrailingRadius: 80
                    )
                )
                .overlay(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: 80,
                        bottomTrailingRadius: 80
                    )
                    .stroke(Color.black, lineWidth: 6)
                )
            
            // Title Text
            Text("المشي صار فعالية")
                .padding(.top, 30)
                .font(.system(size: 35, weight: .bold))
                .foregroundColor(Color(hex: "#1B5299"))
            
            
            
            // Action Button
            CustomButton(title: "عرفنا عليك") {
                navigateToChallenge = false
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)
            .padding(.bottom, 50)
        }
        .fontDesign(.rounded)
        .background(Color.white)
        .clipShape(
            .rect(
                bottomLeadingRadius: 30,
                bottomTrailingRadius: 30
            )
        )
        .ignoresSafeArea(.all, edges: .top)
    }
}

#Preview {
    NavigationStack {
        Onboarding()
            .environmentObject(User())
    }
}

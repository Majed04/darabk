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
        VStack(alignment: .center, spacing: 0) {
            // Main Image
            Image("onboardingPicture")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 630, height: 630)
                .clipShape(
                    .rect(
                        bottomLeadingRadius: 180,
                        bottomTrailingRadius: 180
                    )
                )
                .overlay(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: 180,
                        bottomTrailingRadius: 180
                    )
                    .stroke(Color.black, lineWidth: 6)
                )
            
            // Title Text
            Text("المشي صار فعالية")
                .padding(.top, 30)
                .font(.system(size: 35, weight: .bold))
                .foregroundColor(Color(hex: "#1B5299"))
            
            Spacer()
            
            // Action Button
            CustomButton(title: "عرفنا عليك") {
                navigateToChallenge = false
            }
            .padding(.horizontal, 24)
            .padding(.top, 50)
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
        .navigationDestination(isPresented: $navigateToChallenge) {
            Challenge()
        }
    }
}

#Preview {
    NavigationStack {
        Onboarding()
            .environmentObject(User())
    }
}

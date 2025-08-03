//
//  Welcome.swift
//  darbak
//
//  Created by Majed on 05/02/1447 AH.
//

import SwiftUI
import Lottie

struct Onboarding: View {
    @EnvironmentObject var user: User


        var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("onboardingPicture")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 630, height: 630)
            
            Text("المشي صار فعالية")
                .padding(.top, 30)
                .font(.system(size: 35, weight: .bold))
                .foregroundColor(Color(hex: "#1B5299"))
            Spacer()
                
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all, edges: .top)
            
    }
    
}


#Preview {
    Onboarding()
    
}



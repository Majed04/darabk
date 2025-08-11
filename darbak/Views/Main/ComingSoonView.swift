//
//  ComingSoonView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI

struct ComingSoonView: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(DesignSystem.Colors.primary)
            
            // Title
            Text(title)
                .font(DesignSystem.Typography.largeTitle)
                .primaryText()
                .multilineTextAlignment(.center)
            
            // Description
            Text(description)
                .font(DesignSystem.Typography.body)
                .secondaryText()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Coming Soon Badge
            VStack(spacing: 8) {
                Text("قريباً")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(20)
                
                Text("سيتم إطلاق هذه الميزة قريباً")
                    .font(DesignSystem.Typography.caption)
                    .secondaryText()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
    }
}

#Preview {
    ComingSoonView(
        title: "المتصدرين",
        description: "ستتمكن قريباً من رؤية المتصدرين والتنافس مع أصدقائك في Game Center",
        icon: "trophy.fill"
    )
}

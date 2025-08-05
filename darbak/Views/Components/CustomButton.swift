//
//  CustomButton.swift
//  darbak
//
//  Created by Majed on 05/02/1447 AH.
//

import SwiftUI
import UIKit

struct CustomButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            print("CustomButton action called for: \(title)")
            action()
        }) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundColor(.white)
                .frame(maxWidth: 300, maxHeight: 45)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#1B5299"))
                .cornerRadius(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black)
                        .offset(y: isPressed ? 2 : 4)
                )
                .offset(y: isPressed ? 2 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButton(title: "مشينا") {
            print("Button tapped!")
        }
        
        CustomButton(title: "عرفنا عليك") {
            print("Another button tapped!")
        }
    }
    .padding()
}

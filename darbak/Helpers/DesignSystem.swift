//
//  DesignSystem.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Brighter, more vibrant primary colors
        static let primary = Color(hex: "#3B82F6")  // Bright blue
        static let primaryLight = Color(hex: "#3B82F6").opacity(0.15)
        static let primaryMedium = Color(hex: "#3B82F6").opacity(0.4)
        
        // Brighter accent colors
        static let accent = Color(hex: "#F59E0B")    // Bright amber/orange
        static let success = Color(hex: "#10B981")   // Bright emerald green
        static let warning = Color(hex: "#F59E0B")   // Bright amber
        static let error = Color(hex: "#EF4444")     // Bright red
        
        // Darker backgrounds for dark mode
        static let background = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1) :  // Much darker background
            UIColor.systemBackground                                   // Light mode stays same
        })
        
        static let secondaryBackground = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1) :    // Lighter card background
            UIColor.systemGray6                                        // Light mode stays same
        })
        
        static let cardBackground = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? 
            UIColor(red: 0.18, green: 0.18, blue: 0.2, alpha: 1) :   // Lighter card background
            UIColor.systemBackground                                   // Light mode stays same
        })
        
        static let text = Color.primary
        static let secondaryText = Color.secondary
        static let invertedText = Color.white
        
        static let border = Color.gray.opacity(0.4)  // Slightly more visible border
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 35, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 15
        static let extraLarge: CGFloat = 20
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let light = Color.black.opacity(0.08)   // Slightly more visible
        static let medium = Color.black.opacity(0.15)  // More pronounced shadows
        static let heavy = Color.black.opacity(0.25)   // Stronger shadows for depth
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(DesignSystem.Colors.invertedText)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: DesignSystem.Shadows.medium, radius: 2, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundColor(DesignSystem.Colors.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DesignSystem.Colors.primaryLight)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Card Style
struct CardModifier: ViewModifier {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(
        backgroundColor: Color = DesignSystem.Colors.cardBackground,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.large,
        shadowRadius: CGFloat = 2
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: DesignSystem.Shadows.light,
                radius: shadowRadius,
                x: 0,
                y: 1
            )
    }
}

extension View {
    func cardStyle(
        backgroundColor: Color = DesignSystem.Colors.cardBackground,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.large,
        shadowRadius: CGFloat = 2
    ) -> some View {
        modifier(CardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius
        ))
    }
}

// MARK: - Custom Text Styles
extension View {
    func primaryText() -> some View {
        self.foregroundColor(DesignSystem.Colors.text)
    }
    
    func secondaryText() -> some View {
        self.foregroundColor(DesignSystem.Colors.secondaryText)
    }
    
    func accentText() -> some View {
        self.foregroundColor(DesignSystem.Colors.primary)
    }
}

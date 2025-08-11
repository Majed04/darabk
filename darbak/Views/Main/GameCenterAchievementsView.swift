//
//  GameCenterAchievementsView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI
import GameKit

struct GameCenterAchievementsView: View {
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @State private var showingGameCenter = false
    @State private var isAuthenticating = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("إنجازات Game Center")
                    .font(DesignSystem.Typography.largeTitle)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    showingGameCenter = true
                }) {
                    Image(systemName: "gamecontroller.fill")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            if !gameCenterManager.isAuthenticated {
                // Not authenticated
                VStack(spacing: 20) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("تسجيل الدخول إلى Game Center")
                        .font(DesignSystem.Typography.title2)
                        .primaryText()
                    
                    Text("سجل دخولك إلى Game Center لرؤية إنجازاتك")
                        .font(DesignSystem.Typography.body)
                        .secondaryText()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        authenticateWithGameCenter()
                    }) {
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(DesignSystem.Colors.invertedText)
                            }
                            Text(isAuthenticating ? "جاري التسجيل..." : "تسجيل الدخول")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.invertedText)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    .disabled(isAuthenticating)
                    
                    // Debug info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("معلومات التصحيح:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("GKLocalPlayer.isAuthenticated: \(GKLocalPlayer.local.isAuthenticated ? "نعم" : "لا")")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("GKLocalPlayer.isUnderage: \(GKLocalPlayer.local.isUnderage ? "نعم" : "لا")")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("Game Center Available: \(gameCenterManager.isGameCenterAvailable() ? "نعم" : "لا")")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Button("تصحيح Game Center") {
                            gameCenterManager.debugGameCenterStatus()
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.primary)
                        
                        Button("اختبار Game Center View") {
                            showingGameCenter = true
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding(.top, 20)
                }
                .padding(.top, 60)
            } else {
                // Authenticated - show achievements
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(gameCenterManager.achievements, id: \.identifier) { achievement in
                            GameCenterAchievementCard(achievement: achievement)
                        }
                        
                        if gameCenterManager.achievements.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "trophy")
                                    .font(.system(size: 50))
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                Text("لا توجد إنجازات بعد")
                                    .font(DesignSystem.Typography.title2)
                                    .secondaryText()
                                
                                Text("ابدأ بالمشي لفتح الإنجازات!")
                                    .font(DesignSystem.Typography.body)
                                    .secondaryText()
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
        }
        .background(DesignSystem.Colors.background)
        .sheet(isPresented: $showingGameCenter) {
            GameCenterView(state: .achievements)
        }
        .alert("خطأ في Game Center", isPresented: $showErrorAlert) {
            Button("حسناً") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if gameCenterManager.isAuthenticated {
                gameCenterManager.loadAchievements()
            }
        }
        .onChange(of: gameCenterManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                gameCenterManager.loadAchievements()
            }
        }
    }
    
    private func authenticateWithGameCenter() {
        print("=== Starting Game Center Authentication ===")
        isAuthenticating = true
        errorMessage = ""
        
        // Add a small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Calling GameCenterManager.presentGameCenterLogin()")
            self.gameCenterManager.presentGameCenterLogin()
            
            // Check authentication status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.isAuthenticating = false
                print("Authentication check completed")
                print("GKLocalPlayer.isAuthenticated: \(GKLocalPlayer.local.isAuthenticated)")
                print("Our isAuthenticated state: \(self.gameCenterManager.isAuthenticated)")
                
                if !self.gameCenterManager.isAuthenticated {
                    self.errorMessage = "فشل في تسجيل الدخول إلى Game Center. تأكد من أن Game Center مفعل في إعدادات الجهاز."
                    self.showErrorAlert = true
                    print("Authentication failed - showing error alert")
                } else {
                    print("Authentication successful!")
                }
            }
        }
    }
}

struct GameCenterAchievementCard: View {
    let achievement: GKAchievement
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isCompleted ? DesignSystem.Colors.primary : DesignSystem.Colors.border)
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievementIcon)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(achievement.isCompleted ? DesignSystem.Colors.invertedText : .gray)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.identifier)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(achievement.isCompleted ? DesignSystem.Colors.text : DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    if achievement.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
                
                Text("\(Int(achievement.percentComplete))% مكتمل")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                // Progress bar
                ProgressView(value: achievement.percentComplete, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                    .scaleEffect(y: 0.5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(achievement.isCompleted ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private var achievementIcon: String {
        // Map achievement IDs to icons
        switch achievement.identifier {
        case "first_5k_steps", "first_10k_steps", "first_15k_steps":
            return "figure.walk"
        case "week_streak", "month_streak", "century_streak":
            return "flame.fill"
        case "100k_total_steps", "500k_total_steps", "million_steps":
            return "infinity"
        default:
            return "trophy.fill"
        }
    }
}

#Preview {
    GameCenterAchievementsView()
}

//
//  MainTabView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var user: User
    @EnvironmentObject var challengeProgress: ChallengeProgress
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var streakManager = StreakManager()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var dataManager = DataManager()
    @StateObject private var notificationManager = NotificationManager()
    
    @State private var selectedTab = 0
    @State private var isInitialized = false
    
    var body: some View {
        Group {
            if isInitialized {
                TabView(selection: $selectedTab) {
                    // Home Tab
                    HomeView()
                        .environmentObject(healthKitManager)
                        .environmentObject(streakManager)
                        .environmentObject(achievementManager)
                        .environmentObject(dataManager)
                        .environmentObject(notificationManager)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("الرئيسية")
                        }
                        .tag(0)
                    
                    // Streak Tab
                    StreakView()
                        .environmentObject(streakManager)
                        .environmentObject(dataManager)
                        .environmentObject(healthKitManager)
                        .environmentObject(user)
                        .tabItem {
                            Image(systemName: "flame.fill")
                            Text("الصملة")
                        }
                        .tag(1)
                    
                    // Profile Tab
                    ProfileView()
                        .environmentObject(user)
                        .environmentObject(healthKitManager)
                        .environmentObject(achievementManager)
                        .environmentObject(notificationManager)
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("الملف الشخصي")
                        }
                        .tag(2)
                }
                .accentColor(DesignSystem.Colors.primary)
            } else {
                // Loading view while initializing
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("جاري التحميل...")
                        .font(DesignSystem.Typography.body)
                        .secondaryText()
                        .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignSystem.Colors.background)
            }
        }
        .onAppear {
            setupManagers()
        }
    }
    
    private func setupManagers() {
        // Ensure user has default values
        if user.name.isEmpty {
            user.name = "المستخدم"
        }
        if user.goalSteps == 0 {
            user.goalSteps = 10000
        }
        if user.age == 0 {
            user.age = 25
        }
        if user.weight == 0 {
            user.weight = 70
        }
        if user.height == 0 {
            user.height = 170
        }
        if user.sleepingHours == 0 {
            user.sleepingHours = 8
        }
        
        // Initialize managers with user data
        streakManager.setup(with: healthKitManager, user: user)
        dataManager.setup(with: healthKitManager, user: user)
        notificationManager.setup(with: user)
        achievementManager.setup(with: user, healthKit: healthKitManager, streak: streakManager)
        
        // Mark as initialized after a short delay to ensure everything is set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInitialized = true
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(User())
        .environmentObject(ChallengeProgress())
}

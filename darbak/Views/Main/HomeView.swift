//
//  Home.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var user: User
    @EnvironmentObject var challengeProgress: ChallengeProgress
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var randomChallenge: Challenge
    @State private var showingChallengeView = false
    @State private var lastGoalAchieved = false
    

    
    init() {
        // Initialize with a random challenge
        let challenges = ChallengesData.shared.challenges
        _randomChallenge = State(initialValue: challenges.randomElement() ?? challenges[0])
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("الرئيسية")
                    .font(DesignSystem.Typography.largeTitle)
                    .primaryText()
                    .padding(.leading, DesignSystem.Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                // Toolbar (streak only)
                HStack(spacing: 15) {
                    HStack(spacing: 2) {
                        Text(streakManager.currentStreak.englishFormatted)
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.accent)
                        Image(systemName: "flame.fill")
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 10)

            HStack {
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("مرحبا \(user.name.isEmpty ? "..." : user.name)")
                            .font(DesignSystem.Typography.title2)
                            .primaryText()
                            .multilineTextAlignment(.leading)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("خطواتك")
                                .font(DesignSystem.Typography.headline)
                                .secondaryText()
                            
                            if healthKitManager.isAuthorized {
                                Text(healthKitManager.currentSteps.englishFormatted)
                                    .font(DesignSystem.Typography.largeTitle)
                                    .accentText()
                                    .contentTransition(.numericText())
                                    .animation(.easeInOut(duration: 0.5), value: healthKitManager.currentSteps)
                            } else {
                                Text("--")
                                    .font(DesignSystem.Typography.largeTitle)
                                    .foregroundColor(.gray)
                            }
                            
                            
                        }
                        
                    }
                    .padding(.horizontal, 20)
                
                Spacer()
                }
                
                // Text area above the button
                VStack(alignment: .leading, spacing: 10) {
                    Text("تحدي اليوم")
                        .font(DesignSystem.Typography.headline)
                        .secondaryText()
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                // .padding(.bottom)
                
                // Large rectangular button
                Button(action: {
                    showingChallengeView = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(randomChallenge.fullTitle)
                                .font(DesignSystem.Typography.title2)
                                .foregroundColor(DesignSystem.Colors.invertedText)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 90) // Invisible border to prevent text overlap with image
                        
                        Spacer()
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.large)
                    .overlay(
                        Image("Star")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .offset(x: 20, y: -50)
                            .zIndex(1)
                        , alignment: .topTrailing
                    )
                }
                .padding(.horizontal, 20)
                
                // Weekly Progress Chart
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("أدائك الأسبوعي")
                            .font(DesignSystem.Typography.headline)
                            .secondaryText()
                        
                        Spacer()
                        
                        if let weeklyInsight = dataManager.weeklyInsight {
                            Text("متوسط: \(weeklyInsight.averageSteps.englishFormatted)")
                                .font(DesignSystem.Typography.caption)
                                .secondaryText()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    HStack(spacing: 15) {
                        let weeklyData = dataManager.getWeeklyChartData()
                        let maxSteps = max(weeklyData.max() ?? 10000, user.goalSteps)
                        
                        ForEach(0..<7, id: \.self) { day in
                            VStack(spacing: 8) {
                                // Progress bar
                                VStack {
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .fill(DesignSystem.Colors.primaryMedium)
                                        .frame(width: 30, height: 100)
                                        .overlay(
                                            VStack {
                                                Spacer()
                                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                                    .fill(weeklyData[day] >= user.goalSteps ? DesignSystem.Colors.primary : Color.gray)
                                                    .frame(width: 30, height: CGFloat(weeklyData[day]) / CGFloat(maxSteps) * 100)
                                            }
                                        )
                                }
                                .padding(.top, 20)
                                
                                // Day label
                                Text(["أحد", "اثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت"][day])
                                    .font(DesignSystem.Typography.caption)
                                    .secondaryText()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 50)
                
                Spacer()
        }
        .navigationDestination(isPresented: $showingChallengeView) {
            ChallengePage(selectedChallenge: randomChallenge)
                .environmentObject(challengeProgress)
        }
        .onAppear {
            setupDataTracking()
        }
        .onChange(of: healthKitManager.currentSteps) { _, newSteps in
            handleStepsUpdate(newSteps)
        }
    }
    
    private func setupDataTracking() {
        healthKitManager.fetchTodaySteps()
        dataManager.fetchHistoricalData()
        streakManager.calculateCurrentStreak()
        achievementManager.updateProgress()
    }
    
    private func handleStepsUpdate(_ newSteps: Int) {
        // Update data manager
        dataManager.updateTodaySteps(newSteps)
        
        // Update streak if goal achieved
        let goalAchieved = newSteps >= user.goalSteps
        if goalAchieved && !lastGoalAchieved {
            streakManager.updateStreakForToday()
            achievementManager.updateConsistencyForToday(true)
            // Send notification for goal achievement
            notificationManager.sendGoalAchievementNotification()
        }
        lastGoalAchieved = goalAchieved
        
        // Update achievements
        achievementManager.updateProgress()
        
        // Submit scores to Game Center
        GameCenterManager.shared.submitDailySteps(newSteps)
        GameCenterManager.shared.submitStreak(streakManager.currentStreak)
        
        // Check and unlock Game Center achievements
        let totalSteps = dataManager.totalDistance * 1000 // Approximate total steps
        GameCenterManager.shared.checkAndUnlockAchievements(
            steps: newSteps,
            streak: streakManager.currentStreak,
            totalSteps: Int(totalSteps)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(User())
        .environmentObject(ChallengeProgress())
        .environmentObject(HealthKitManager())
        .environmentObject(StreakManager())
        .environmentObject(AchievementManager())
        .environmentObject(DataManager())
        .environmentObject(NotificationManager())
}

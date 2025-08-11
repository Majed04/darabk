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
    @State private var selectedDay: Int? = nil
    @State private var showingDayDetails = false
    
    init() {
        // Initialize with a random challenge
        let challenges = ChallengesData.shared.challenges
        _randomChallenge = State(initialValue: challenges.randomElement() ?? challenges[0])
    }
    
    var body: some View {
        VStack(spacing: 25) {
            // Header with greeting and streak
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("مرحباً \(user.name.isEmpty ? "..." : user.name)")
                        .font(DesignSystem.Typography.title2)
                        .primaryText()
                    
                    Text("استمر في التقدم!")
                        .font(DesignSystem.Typography.body)
                        .secondaryText()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Streak indicator
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.accent)
                    
                    Text(streakManager.currentStreak.englishFormatted)
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.accent)
                        .bold()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(DesignSystem.Colors.accent.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Today's Steps Card
            VStack(spacing: 15) {
                HStack {
                    Text("خطواتك اليوم")
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                    
                    Spacer()
                    
                    if healthKitManager.isAuthorized {
                        Text("هدف: \(user.goalSteps.englishFormatted)")
                            .font(DesignSystem.Typography.caption)
                            .secondaryText()
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        if healthKitManager.isAuthorized {
                            Text(healthKitManager.currentSteps.englishFormatted)
                                .font(DesignSystem.Typography.largeTitle)
                                .accentText()
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.5), value: healthKitManager.currentSteps)
                            
                            // Progress bar
                            ProgressView(value: Double(healthKitManager.currentSteps), total: Double(user.goalSteps))
                                .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                        } else {
                            Text("--")
                                .font(DesignSystem.Typography.largeTitle)
                                .foregroundColor(.gray)
                            
                            Text("يرجى منح إذن الصحة")
                                .font(DesignSystem.Typography.caption)
                                .secondaryText()
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "figure.walk")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(20)
            .cardStyle()
            .padding(.horizontal, 20)
            
            // Daily Challenge Card
            VStack(spacing: 15) {
                HStack {
                    Text("تحدي اليوم")
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                    
                    Spacer()
                    
                    Image(systemName: "star.fill")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                
                Button(action: {
                    showingChallengeView = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(randomChallenge.fullTitle)
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(DesignSystem.Colors.invertedText)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(DesignSystem.Typography.caption)
                                Text("اضغط للبدء")
                                    .font(DesignSystem.Typography.caption)
                            }
                            .foregroundColor(DesignSystem.Colors.invertedText.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.left")
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(DesignSystem.Colors.invertedText.opacity(0.8))
                    }
                    .padding(20)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
            }
            .padding(20)
            .cardStyle()
            .padding(.horizontal, 20)
            
            // Weekly Progress Card
            VStack(spacing: 8) {
                HStack {
                    Text("أدائك الأسبوعي")
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                    
                    Spacer()
                    
                    if let weeklyInsight = dataManager.weeklyInsight {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("متوسط")
                                .font(DesignSystem.Typography.caption)
                                .secondaryText()
                            Text(weeklyInsight.averageSteps.englishFormatted)
                                .font(DesignSystem.Typography.body)
                                .accentText()
                                .bold()
                        }
                    }
                }
                
                let weeklyData = dataManager.getWeeklyChartData()
                let maxSteps = max(weeklyData.max() ?? 10000, user.goalSteps, 15000) // Ensure minimum scale
                
                // Weekly chart
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { day in
                        VStack(spacing: 3) {
                            // Steps count above bar
                            Text(weeklyData[day].englishFormatted)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(weeklyData[day] >= user.goalSteps ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            // Progress bar
                            VStack(spacing: 0) {
                                ZStack(alignment: .bottom) {
                                    // Background bar
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .fill(DesignSystem.Colors.primaryMedium)
                                        .frame(width: 24, height: 50)
                                    
                                    // Progress bar
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .fill(weeklyData[day] >= user.goalSteps ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.6))
                                        .frame(width: 24, height: max(2, CGFloat(weeklyData[day]) / CGFloat(maxSteps) * 50))
                                        .animation(.easeInOut(duration: 0.3), value: weeklyData[day])
                                }
                                
                                // Goal indicator line
                                if weeklyData[day] < user.goalSteps {
                                    Rectangle()
                                        .fill(DesignSystem.Colors.primary)
                                        .frame(width: 24, height: 1)
                                        .offset(y: -CGFloat(user.goalSteps) / CGFloat(maxSteps) * 50)
                                }
                            }
                            .onTapGesture {
                                selectedDay = day
                                showingDayDetails = true
                            }
                            
                            // Day label
                            Text(["أحد", "اثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت"][day])
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(weeklyData[day] >= user.goalSteps ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                                .fontWeight(weeklyData[day] >= user.goalSteps ? .semibold : .regular)
                        }
                    }
                }
                
                // Goal line explanation
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 20, height: 2)
                    
                    Text("خط الهدف")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 8, height: 8)
                        Text("تم التحقيق")
                            .font(DesignSystem.Typography.caption)
                            .secondaryText()
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
            .cardStyle()
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
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
        .sheet(isPresented: $showingDayDetails) {
            if let selectedDay = selectedDay {
                DayDetailsView(day: selectedDay, weeklyData: dataManager.getWeeklyChartData(), goalSteps: user.goalSteps)
            }
        }
    }
    
    private func setupDataTracking() {
        healthKitManager.fetchAllTodayData()
        dataManager.fetchHistoricalData()
        streakManager.calculateCurrentStreak()
        achievementManager.updateProgress()
    }
    
    private func handleStepsUpdate(_ newSteps: Int) {
        // Update data manager with all current health data
        dataManager.updateTodayData(
            steps: newSteps,
            distance: healthKitManager.currentDistance,
            calories: healthKitManager.currentCalories
        )
        
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
        let totalSteps = dataManager.monthlyHealthData.reduce(0) { $0 + $1.steps }
        GameCenterManager.shared.checkAndUnlockAchievements(
            steps: newSteps,
            streak: streakManager.currentStreak,
            totalSteps: totalSteps
        )
    }
}

// MARK: - Day Details View
struct DayDetailsView: View {
    let day: Int
    let weeklyData: [Int]
    let goalSteps: Int
    
    @Environment(\.dismiss) private var dismiss
    
    private var dayName: String {
        ["أحد", "اثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت"][day]
    }
    
    private var steps: Int {
        weeklyData[day]
    }
    
    private var progressPercentage: Double {
        guard goalSteps > 0 else { return 0 }
        return Double(steps) / Double(goalSteps) * 100
    }
    
    private var isGoalAchieved: Bool {
        steps >= goalSteps
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Text(dayName)
                        .font(DesignSystem.Typography.largeTitle)
                        .primaryText()
                    
                    Text("تفاصيل الخطوات")
                        .font(DesignSystem.Typography.body)
                        .secondaryText()
                }
                .padding(.top, 20)
                
                // Steps Card
                VStack(spacing: 20) {
                    // Steps count
                    VStack(spacing: 8) {
                        Text(steps.englishFormatted)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .accentText()
                        
                        Text("خطوة")
                            .font(DesignSystem.Typography.title3)
                            .secondaryText()
                    }
                    
                    // Progress bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("الهدف: \(goalSteps.englishFormatted)")
                                .font(DesignSystem.Typography.caption)
                                .secondaryText()
                            
                            Spacer()
                            
                            Text("\(Int(progressPercentage))%")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(isGoalAchieved ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                        }
                        
                        ProgressView(value: Double(steps), total: Double(goalSteps))
                            .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                    
                    // Status indicator
                    HStack(spacing: 8) {
                        Image(systemName: isGoalAchieved ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isGoalAchieved ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                        
                        Text(isGoalAchieved ? "تم تحقيق الهدف" : "لم يتم تحقيق الهدف بعد")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(isGoalAchieved ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                    }
                    .padding(.top, 10)
                }
                .padding(25)
                .cardStyle()
                .padding(.horizontal, 20)
                
                // Additional stats
                VStack(spacing: 15) {
                    HStack {
                        StatItem(
                            title: "المتبقي",
                            value: max(0, goalSteps - steps).englishFormatted,
                            icon: "figure.walk",
                            color: DesignSystem.Colors.primary
                        )
                        
                        StatItem(
                            title: "النسبة المئوية",
                            value: "\(Int(progressPercentage))%",
                            icon: "percent",
                            color: DesignSystem.Colors.accent
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(DesignSystem.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("إغلاق") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(DesignSystem.Typography.title2)
                    .primaryText()
                    .bold()
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .secondaryText()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardStyle()
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

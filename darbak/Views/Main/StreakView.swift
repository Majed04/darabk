//
//  StreakView.swift
//  darbak
//
//  Created by Ghina Alsubaie on 11/02/1447 AH.
//

import SwiftUI

struct StreakView: View {
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var user: User
    
    @State private var selectedWeek = 0
    @State private var weeklyData: [DayData] = []
    
    struct DayData: Identifiable {
        let id = UUID()
        let date: Date
        let steps: Int
        let isToday: Bool
        let achievedGoal: Bool
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 25) {
                    // Header
                    HStack {
                        Text("الصملة")
                            .font(DesignSystem.Typography.largeTitle)
                            .primaryText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Streak Stats Cards
                    VStack(spacing: 15) {
                        Text("إحصائياتك")
                            .font(DesignSystem.Typography.title2)
                            .accentText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                            StreakStatCard(
                                title: "الصملة الحالية",
                                value: streakManager.currentStreak.englishFormatted,
                                subtitle: "يوم متتالي",
                                icon: "flame.fill",
                                color: DesignSystem.Colors.accent
                            )
                            
                            StreakStatCard(
                                title: "أطول صملة",
                                value: streakManager.longestStreak.englishFormatted,
                                subtitle: "يوم",
                                icon: "trophy.fill",
                                color: DesignSystem.Colors.success
                            )
                            
                            StreakStatCard(
                                title: "خطوات اليوم",
                                value: getCurrentSteps().englishFormatted,
                                subtitle: "من \(user.goalSteps.englishFormatted)",
                                icon: "figure.walk",
                                color: DesignSystem.Colors.primary
                            )
                            
                            StreakStatCard(
                                title: "التقدم",
                                value: "\(getProgressPercentage().englishFormatted)%",
                                subtitle: "هدف اليوم",
                                icon: "target",
                                color: getProgressPercentage() >= 100 ? DesignSystem.Colors.success : DesignSystem.Colors.warning
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Weekly Progress
                    VStack(spacing: 15) {
                        HStack {
                            Text("التقدم الأسبوعي")
                                .font(DesignSystem.Typography.title2)
                                .accentText()
                            
                            Spacer()
                            
                            Button(action: {
                                // Previous week logic (right arrow in RTL)
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(DesignSystem.Typography.title3)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            
                            Button(action: {
                                // Next week logic (left arrow in RTL)
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(DesignSystem.Typography.title3)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 20) {
                            // Week days
                            HStack(spacing: 10) {
                                ForEach(weeklyData) { dayData in
                                    DayProgressView(
                                        dayData: dayData,
                                        dailyGoal: user.goalSteps
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Week summary
                            WeekSummaryCard(weeklyData: weeklyData, dailyGoal: user.goalSteps)
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        .cardStyle()
                        .padding(.horizontal, 20)
                    }
                    
                    // Motivation Section
                    VStack(spacing: 15) {
                        Text("حافز اليوم")
                            .font(DesignSystem.Typography.title2)
                            .accentText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        MotivationCard(
                            currentStreak: streakManager.currentStreak,
                            todayProgress: getProgressPercentage()
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
                }
            }
        }
        .onAppear {
            loadWeeklyData()
        }
        .refreshable {
            loadWeeklyData()
        }
    }
    
    private func getCurrentSteps() -> Int {
        return healthKitManager.currentSteps
    }
    
    private func getProgressPercentage() -> Int {
        let steps = getCurrentSteps()
        // Add safety check to prevent division by zero
        guard user.goalSteps > 0 else { return 0 }
        return min(Int((Double(steps) / Double(user.goalSteps)) * 100), 100)
    }
    
    private func loadWeeklyData() {
        // Add safety check for user goal steps
        guard user.goalSteps > 0 else {
            print("📈 StreakView: User goal steps not set, skipping data load")
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Get current week starting from Sunday
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return }
        
        weeklyData = (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }
            let isToday = calendar.isDateInToday(date)
            let steps = getStepsForDate(date)
            let achievedGoal = steps >= user.goalSteps
            
            return DayData(
                date: date,
                steps: steps,
                isToday: isToday,
                achievedGoal: achievedGoal
            )
        }
        
        // If we have HealthKit access, try to fetch historical data
        if healthKitManager.isAuthorized {
            fetchWeeklyDataFromHealthKit()
        }
    }
    
    private func fetchWeeklyDataFromHealthKit() {
        // Add safety check for user goal steps
        guard user.goalSteps > 0 else {
            print("📈 StreakView: User goal steps not set, skipping HealthKit fetch")
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { return }
        
        healthKitManager.fetchStepsForDateRange(from: weekStart, to: weekEnd) { stepsData in
            DispatchQueue.main.async {
                // Update weeklyData with real HealthKit data
                self.weeklyData = (0..<7).compactMap { dayOffset in
                    guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { return nil }
                    let isToday = calendar.isDateInToday(date)
                    let dayStart = calendar.startOfDay(for: date)
                    let steps = stepsData[dayStart] ?? self.getStepsForDate(date)
                    let achievedGoal = steps >= self.user.goalSteps
                    
                    // Store the data for future use
                    if steps > 0 {
                        self.streakManager.saveStepsForDate(date, steps: steps)
                    }
                    
                    return DayData(
                        date: date,
                        steps: steps,
                        isToday: isToday,
                        achievedGoal: achievedGoal
                    )
                }
            }
        }
    }
    
    private func getStepsForDate(_ date: Date) -> Int {
        if Calendar.current.isDateInToday(date) {
            return getCurrentSteps()
        } else {
            // Get historical data from StreakManager
            let key = "steps_\(date.timeIntervalSince1970)"
            let storedSteps = UserDefaults.standard.integer(forKey: key)
            return storedSteps > 0 ? storedSteps : 0
        }
    }
}

struct StreakStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(DesignSystem.Typography.title)
                    .primaryText()
                
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .primaryText()
                
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .secondaryText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
    }
}

struct DayProgressView: View {
    let dayData: StreakView.DayData
    let dailyGoal: Int
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "ar")
        let arabicName = formatter.string(from: dayData.date)
        
        // Ensure proper Arabic day names for RTL
        let dayMappings = [
            "Sun": "الأحد",
            "Mon": "الاثنين", 
            "Tue": "الثلاثاء",
            "Wed": "الأربعاء",
            "Thu": "الخميس",
            "Fri": "الجمعة",
            "Sat": "السبت"
        ]
        
        let englishFormatter = DateFormatter()
        englishFormatter.dateFormat = "EEE"
        englishFormatter.locale = Locale(identifier: "en")
        let englishName = englishFormatter.string(from: dayData.date)
        
        return dayMappings[englishName] ?? arabicName
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: dayData.date)
    }
    
    private var progress: Double {
        return min(Double(dayData.steps) / Double(dailyGoal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dayName)
                .font(DesignSystem.Typography.caption)
                .secondaryText()
            
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.border, lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        dayData.achievedGoal ? DesignSystem.Colors.success : DesignSystem.Colors.primary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text(dayNumber)
                    .font(DesignSystem.Typography.footnote)
                    .primaryText()
            }
            
            if dayData.achievedGoal {
                Image(systemName: "checkmark.circle.fill")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.success)
            } else {
                Text("\(Int(progress * 100).englishFormatted)%")
                    .font(DesignSystem.Typography.caption2)
                    .secondaryText()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeekSummaryCard: View {
    let weeklyData: [StreakView.DayData]
    let dailyGoal: Int
    
    private var totalSteps: Int {
        weeklyData.reduce(0) { $0 + $1.steps }
    }
    
    private var daysAchieved: Int {
        weeklyData.filter { $0.achievedGoal }.count
    }
    
    private var averageSteps: Int {
        weeklyData.isEmpty ? 0 : totalSteps / weeklyData.count
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("إجمالي الخطوات")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    Text(totalSteps.englishFormatted)
                        .font(DesignSystem.Typography.title2)
                        .primaryText()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("الأيام المنجزة")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    Text("\(daysAchieved.englishFormatted)/7")
                        .font(DesignSystem.Typography.title2)
                        .primaryText()
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("متوسط الخطوات")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    Text(averageSteps.englishFormatted)
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("الهدف الأسبوعي")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    Text((dailyGoal * 7).englishFormatted)
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.primaryLight.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct MotivationCard: View {
    let currentStreak: Int
    let todayProgress: Int
    
    private var motivationMessage: String {
        if todayProgress >= 100 {
            return "🎉 مبروك! حققت هدفك اليوم"
        } else if todayProgress >= 75 {
            return "💪 أنت قريب جداً من الهدف!"
        } else if todayProgress >= 50 {
            return "🚀 أنت في منتصف الطريق"
        } else if todayProgress >= 25 {
            return "⭐ بداية جيدة، استمر!"
        } else {
            return "🌟 ابدأ يومك بخطوة!"
        }
    }
    
    private var streakMessage: String {
        if currentStreak >= 30 {
            return "🔥 صملة رائعة! أنت ملتزم جداً"
        } else if currentStreak >= 7 {
            return "⚡ صملة ممتازة! استمر"
        } else if currentStreak >= 3 {
            return "🎯 صملة جيدة! لا تتوقف"
        } else {
            return "💫 ابدأ صملتك الجديدة"
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(motivationMessage)
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                    
                    Text(streakMessage)
                        .font(DesignSystem.Typography.subheadline)
                        .secondaryText()
                }
                
                Spacer()
                
                Image(systemName: todayProgress >= 100 ? "star.fill" : "star")
                    .font(.system(size: 40))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            
            if todayProgress < 100 {
                ProgressView(value: Double(todayProgress), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                    .scaleEffect(x: 1, y: 2)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .cardStyle(backgroundColor: DesignSystem.Colors.primaryLight.opacity(0.05))
    }
}

#Preview {
    StreakView()
        .environmentObject(StreakManager())
        .environmentObject(DataManager())
        .environmentObject(User())
}
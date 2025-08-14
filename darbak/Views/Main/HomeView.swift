//
//  Home.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI

// MARK: - Identifiable wrapper to avoid white sheet flash
private struct DaySelection: Identifiable, Hashable {
    let id: Int   // 0=Sunday ... 6=Saturday
}

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
    @State private var selectedDay: DaySelection? = nil
    
    init() {
        let challenges = ChallengesData.shared.challenges
        _randomChallenge = State(initialValue: challenges.randomElement() ?? challenges[0])
    }
    
    var body: some View {
        VStack(spacing: 25) {
         
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
                
                Button(action: { showingChallengeView = true }) {
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
            
        
            VStack(spacing: 12) {
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
                
                
                let (labels, stepsArr) = sundayFirstWeekly(labelsFrom: dataManager.getWeeklyChartData())
                let maxSteps = max(stepsArr.max() ?? 10000, user.goalSteps, 15000)
                
              
                let barWidth: CGFloat = 26
                let barHeight: CGFloat = 60
                let barSpacing: CGFloat = 12
                let valueAreaHeight: CGFloat = 16
               
                
                HStack(spacing: barSpacing) {
                    ForEach(0..<stepsArr.count, id: \.self) { i in
                        let steps = stepsArr[i]
                        let label = labels[i]
                        let reached = steps >= user.goalSteps
                        let h = max(3, CGFloat(steps) / CGFloat(maxSteps) * barHeight)
                        let goalY = CGFloat(user.goalSteps) / CGFloat(maxSteps) * barHeight
                        
                        VStack(spacing: 8) {
                      
                            Text(steps.englishFormatted)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(reached ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(height: valueAreaHeight)
                                .zIndex(1)
                            
                       
                            ZStack(alignment: .bottom) {
                               
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(DesignSystem.Colors.primaryMedium.opacity(0.6))
                                    .frame(width: barWidth, height: barHeight)
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                       
                                Rectangle()
                                    .fill(DesignSystem.Colors.primary)
                                    .frame(width: barWidth, height: 1)
                                    .offset(y: -(barHeight - goalY))
                                    .opacity(0.9)
                                
                                
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(reached ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.65))
                                    .frame(width: barWidth, height: h)
                                    .animation(.easeInOut(duration: 0.22), value: steps)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedDay = DaySelection(id: i) } // i = Sunday..Saturday
                            
                    
                            Text(label)
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(reached ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                                .fontWeight(reached ? .semibold : .regular)
                                .frame(width: barWidth + 8)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 2) // tiny buffer above the chart
                
              
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
            .padding(16)
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
        .onAppear { setupDataTracking() }
        .onChange(of: healthKitManager.currentSteps) { _, newSteps in
            handleStepsUpdate(newSteps)
        }
        .sheet(item: $selectedDay) { selection in
           
            let (_, stepsArr) = sundayFirstWeekly(labelsFrom: dataManager.getWeeklyChartData())
            DayDetailsView(
                day: selection.id,
                weeklyData: stepsArr,
                goalSteps: user.goalSteps
            )
        }
    }
    
    // MARK: - Helpers
    private func setupDataTracking() {
        healthKitManager.fetchAllTodayData()
        dataManager.fetchHistoricalData()
        streakManager.calculateCurrentStreak()
        achievementManager.updateProgress()
    }
    
    private func handleStepsUpdate(_ newSteps: Int) {
        dataManager.updateTodayData(
            steps: newSteps,
            distance: healthKitManager.currentDistance,
            calories: healthKitManager.currentCalories
        )
        let goalAchieved = newSteps >= user.goalSteps
        if goalAchieved && !lastGoalAchieved {
            streakManager.updateStreakForToday()
            achievementManager.updateConsistencyForToday(true)
            notificationManager.sendGoalAchievementNotification()
        }
        lastGoalAchieved = goalAchieved
        
        achievementManager.updateProgress()
        GameCenterManager.shared.submitDailySteps(newSteps)
        GameCenterManager.shared.submitStreak(streakManager.currentStreak)
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
    
    private var steps: Int { weeklyData[safe: day] ?? 0 }
    private var progressPercentage: Double {
        guard goalSteps > 0 else { return 0 }
        return Double(steps) / Double(goalSteps) * 100
    }
    private var isGoalAchieved: Bool { steps >= goalSteps }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                VStack(spacing: 10) {
                    Text(arabicLongWeekdayForSundayFirstIndex(day))
                        .font(DesignSystem.Typography.largeTitle)
                        .primaryText()
                    Text("تفاصيل الخطوات")
                        .font(DesignSystem.Typography.body)
                        .secondaryText()
                }
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text(steps.englishFormatted)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .accentText()
                        Text("خطوة")
                            .font(DesignSystem.Typography.title3)
                            .secondaryText()
                    }
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
                    Button("إغلاق") { dismiss() }
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

// MARK: - Utilities


private func sundayFirstWeekly(labelsFrom raw: [Int]) -> (labels: [String], steps: [Int]) {
    let cal = Calendar(identifier: .gregorian)
    let today = cal.startOfDay(for: Date())
    // Ensure exactly 7 entries; if fewer, pad front with zeros
    var trimmed = raw
    if trimmed.count > 7 { trimmed = Array(trimmed.suffix(7)) }
    if trimmed.count < 7 { trimmed = Array(repeating: 0, count: 7 - trimmed.count) + trimmed }
    

    let dates: [Date] = (0..<7).compactMap { i in
        cal.date(byAdding: .day, value: i - 6, to: today)
    }
    let pairs = Array(zip(dates, trimmed))
    
    func sundayIndex(_ d: Date) -> Int {
       
        cal.component(.weekday, from: d) - 1
    }
    let ordered = pairs.sorted { sundayIndex($0.0) < sundayIndex($1.0) }
    
    let labels = ordered.map { arabicShortWeekday(for: $0.0, calendar: cal) } // "أحد".."سبت"
    let steps  = ordered.map { $0.1 }
    return (labels, steps)
}


private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// Arabic short weekday from Date
private func arabicShortWeekday(for date: Date, calendar: Calendar) -> String {
    switch calendar.component(.weekday, from: date) { // 1=Sun … 7=Sat
    case 1: return "أحد"
    case 2: return "اثنين"
    case 3: return "ثلاثاء"
    case 4: return "أربعاء"
    case 5: return "خميس"
    case 6: return "جمعة"
    default: return "سبت"
    }
}

private func arabicLongWeekdayForSundayFirstIndex(_ index: Int) -> String {
    switch index {
    case 0: return "الأحد"
    case 1: return "الاثنين"
    case 2: return "الثلاثاء"
    case 3: return "الأربعاء"
    case 4: return "الخميس"
    case 5: return "الجمعة"
    default: return "السبت"
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


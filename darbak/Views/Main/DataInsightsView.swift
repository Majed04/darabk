//
//  DataInsightsView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI
import Charts

// MARK: - Period Enum
enum InsightPeriod: String, CaseIterable {
    case week  = "الأسبوع"
    case month = "الشهر"
    case year  = "السنة"
}

// MARK: - Main View
struct DataInsightsView: View {
    @EnvironmentObject var user: User
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var dataManager = DataManager()
    @State private var selectedPeriod: InsightPeriod = .week
    @State private var showingDetailChart = false

    private let englishFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en")
        return f
    }()

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        // Period Selector
                        HStack(spacing: 0) {
                            ForEach(InsightPeriod.allCases, id: \.self) { period in
                                Button { selectedPeriod = period } label: {
                                    Text(period.rawValue)
                                        .font(.caption)
                                        .foregroundColor(selectedPeriod == period ? .white : DesignSystem.Colors.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedPeriod == period ? DesignSystem.Colors.primary : .clear)
                                        )
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        // Period Header
                        PeriodHeaderView(selectedPeriod: selectedPeriod)
                            .padding(.horizontal, 20)

                        // Period-specific content
                        switch selectedPeriod {
                        case .week:
                            WeeklyView(dataManager: dataManager, user: user, healthKitManager: healthKitManager)
                        case .month:
                            MonthlyView(dataManager: dataManager, user: user, healthKitManager: healthKitManager)
                        case .year:
                            YearlyView(dataManager: dataManager, user: user, healthKitManager: healthKitManager)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("تحليل البيانات")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إغلاق") { dismiss() })
        }
        .onAppear {
            print("📊 DataInsightsView appeared - setting up data manager")
            dataManager.setup(with: healthKitManager, user: user)

            // Fetch today & then history
            healthKitManager.fetchAllTodayData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("📊 Force refreshing historical data")
                dataManager.fetchHistoricalData()

                // Give DataManager time to compute insights before first baseline attempt
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    updateImprovementBaselines()
                    debugLog()
                }
            }
        }
        // Update baselines once insights become non-zero (prevents rotating zeros)
        .onChange(of: dataManager.weeklyInsight?.averageSteps ?? 0) { newAvg in
            if newAvg > 0 {
                print("🔁 Weekly avg ready (\(newAvg)) → updating baselines")
                updateImprovementBaselines()
            }
        }
        .onChange(of: dataManager.monthlyInsight?.averageSteps ?? 0) { newAvg in
            if newAvg > 0 {
                print("🔁 Monthly avg ready (\(newAvg)) → updating baselines")
                updateImprovementBaselines()
            }
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ number: Int) -> String {
        englishFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    // MARK: - Shared Helpers
    
    static func formatPercent(_ value: Double?) -> String {
        guard let v = value else { return "—" }                 // no baseline yet
        let clamped = max(min(v, 999.9), -999.9)
        return String(format: "%.1f%%", clamped)                // one decimal
    }

    // Start-of-period helpers
    private func startOfCurrentWeek() -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start
    }
    private func startOfCurrentMonth() -> Date {
        Calendar.current.dateInterval(of: .month, for: Date())!.start
    }

    /// Persist current week/month averages and rotate baselines when period changes.
    private func updateImprovementBaselines() {
        let defaults = UserDefaults.standard

        // ---------- WEEK ----------
        let currentWeekStart = startOfCurrentWeek()
        let storedWeekStart = defaults.object(forKey: "baselineWeekStart") as? Date

        let currentWeekAvg = dataManager.weeklyInsight?.averageSteps ?? 0
        defaults.set(currentWeekAvg, forKey: "currentWeekAverage")

        if storedWeekStart == nil || !Calendar.current.isDate(storedWeekStart!, inSameDayAs: currentWeekStart) {
            let prevSaved = defaults.integer(forKey: "currentWeekAverage")
            defaults.set(prevSaved, forKey: "lastWeekAverage")
            defaults.set(currentWeekStart, forKey: "baselineWeekStart")
            print("✅ Rotated week baseline. lastWeekAverage=\(prevSaved)")
        }

        // ---------- MONTH ----------
        let currentMonthStart = startOfCurrentMonth()
        let storedMonthStart = defaults.object(forKey: "baselineMonthStart") as? Date

        let currentMonthAvg = dataManager.monthlyInsight?.averageSteps ?? 0
        defaults.set(currentMonthAvg, forKey: "currentMonthAverage")

        if storedMonthStart == nil || !Calendar.current.isDate(storedMonthStart!, inSameDayAs: currentMonthStart) {
            let prevSaved = defaults.integer(forKey: "currentMonthAverage")
            defaults.set(prevSaved, forKey: "lastMonthAverage")
            defaults.set(currentMonthStart, forKey: "baselineMonthStart")
            print("✅ Rotated month baseline. lastMonthAverage=\(prevSaved)")
        }
    }

    private func debugLog() {
        print("📊 Debug - Weekly avg: \(dataManager.weeklyInsight?.averageSteps ?? 0)")
        print("📊 Debug - Monthly avg: \(dataManager.monthlyInsight?.averageSteps ?? 0)")
        print("📊 Debug - goal: \(user.goalSteps)")
                 print("📊 Debug - lastWeekAverage (UD): \(UserDefaults.standard.integer(forKey: "lastWeekAverage"))")
         print("📊 Debug - lastMonthAverage (UD): \(UserDefaults.standard.integer(forKey: "lastMonthAverage"))")
    }
}

// MARK: - Weekly View
struct WeeklyView: View {
    let dataManager: DataManager
    let user: User
    let healthKitManager: HealthKitManager

    private let englishFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en")
        return f
    }()

    var body: some View {
        VStack(spacing: 25) {
            // Weekly Key Insights
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                InsightCard(
                    title: "متوسط الأسبوع",
                    value: formatNumber(dataManager.weeklyInsight?.averageSteps ?? 0),
                    subtitle: "خطوة يومياً",
                    icon: "figure.walk",
                    color: Color(hex: "#1B5299"),
                    isImprovement: false
                )
                InsightCard(
                    title: "أيام الهدف",
                    value: "\(dataManager.weeklyInsight?.daysGoalAchieved ?? 0)",
                    subtitle: "من 7 أيام",
                    icon: "target",
                    color: .orange,
                    isImprovement: false
                )
                InsightCard(
                    title: "أفضل يوم",
                    value: formatNumber(dataManager.weeklyInsight?.bestDay?.steps ?? 0),
                    subtitle: "خطوة",
                    icon: "trophy.fill",
                    color: .yellow,
                    isImprovement: false
                )

                let weeklyImprovement = getWeeklyImprovement()
                InsightCard(
                    title: "التحسن",
                    value: DataInsightsView.formatPercent(weeklyImprovement),
                    subtitle: "من الأسبوع الماضي",
                    icon: "chart.line.uptrend.xyaxis",
                    color: (weeklyImprovement ?? 0) >= 0 ? .green : .red,
                    isImprovement: true
                )
            }
            .padding(.horizontal, 20)

            WeeklyPersonalRecordsView(dataManager: dataManager, healthKitManager: healthKitManager)
                .padding(.horizontal, 20)
        }
    }

    private func formatNumber(_ number: Int) -> String {
        englishFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// Returns nil when there is no weekly baseline yet.
    private func getWeeklyImprovement() -> Double? {
        let current = dataManager.weeklyInsight?.averageSteps ?? 0
        let last = UserDefaults.standard.integer(forKey: "lastWeekAverage")
        print("📊 Weekly Improvement Debug: current=\(current), last=\(last)")
        guard last > 0 else { return nil }
        return (Double(current - last) / Double(last)) * 100.0
    }
}

// MARK: - Monthly View
struct MonthlyView: View {
    let dataManager: DataManager
    let user: User
    let healthKitManager: HealthKitManager

    private let englishFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en")
        return f
    }()

    var body: some View {
        VStack(spacing: 25) {
            // Monthly Key Insights
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                InsightCard(
                    title: "متوسط الشهر",
                    value: formatNumber(dataManager.monthlyInsight?.averageSteps ?? 0),
                    subtitle: "خطوة يومياً",
                    icon: "figure.walk",
                    color: Color(hex: "#1B5299"),
                    isImprovement: false
                )
                InsightCard(
                    title: "أيام الهدف",
                    value: "\(dataManager.monthlyInsight?.daysGoalAchieved ?? 0)",
                    subtitle: "من 30 يوم",
                    icon: "target",
                    color: .orange,
                    isImprovement: false
                )
                InsightCard(
                    title: "الرقم القياسي",
                    value: formatNumber(dataManager.monthlyInsight?.personalBest ?? 0),
                    subtitle: "خطوة في يوم",
                    icon: "trophy.fill",
                    color: .yellow,
                    isImprovement: false
                )

                let monthlyImprovement = getMonthlyImprovement()
                InsightCard(
                    title: "التحسن",
                    value: DataInsightsView.formatPercent(monthlyImprovement),
                    subtitle: "من الشهر الماضي",
                    icon: "chart.line.uptrend.xyaxis",
                    color: (monthlyImprovement ?? 0) >= 0 ? .green : .red,
                    isImprovement: true
                )
            }
            .padding(.horizontal, 20)

            MonthlyPersonalRecordsView(dataManager: dataManager, healthKitManager: healthKitManager)
                .padding(.horizontal, 20)
        }
    }

    private func formatNumber(_ number: Int) -> String {
        englishFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// Returns nil when there is no monthly baseline yet.
    private func getMonthlyImprovement() -> Double? {
        let current = dataManager.monthlyInsight?.averageSteps ?? 0
        let last = UserDefaults.standard.integer(forKey: "lastMonthAverage")
        print("📊 Monthly Improvement Debug: current=\(current), last=\(last)")
        guard last > 0 else { return nil }
        return (Double(current - last) / Double(last)) * 100.0
    }
}

// MARK: - Yearly View
struct YearlyView: View {
    let dataManager: DataManager
    let user: User
    let healthKitManager: HealthKitManager

    private let englishFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en")
        return f
    }()

    var body: some View {
        VStack(spacing: 25) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                InsightCard(
                    title: "إجمالي السنة",
                    value: formatNumber(getYearlyTotalSteps()),
                    subtitle: "خطوة",
                    icon: "figure.walk",
                    color: Color(hex: "#1B5299"),
                    isImprovement: false
                )
                InsightCard(
                    title: "أيام الهدف",
                    value: "\(getYearlyGoalDays())",
                    subtitle: "من \(getDaysElapsed()) يوم",
                    icon: "target",
                    color: .orange,
                    isImprovement: false
                )
                InsightCard(
                    title: "أفضل شهر",
                    value: getBestMonthName(),
                    subtitle: "أكثر نشاطاً",
                    icon: "trophy.fill",
                    color: .yellow,
                    isImprovement: false
                )
                InsightCard(
                    title: "الهدف السنوي",
                    value: "\(getYearlyGoalProgress())%",
                    subtitle: "معدل الإنجاز",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    isImprovement: false
                )
            }
            .padding(.horizontal, 20)

            PersonalRecordsView(dataManager: dataManager, healthKitManager: healthKitManager)
                .padding(.horizontal, 20)
        }
    }

    private func formatNumber(_ number: Int) -> String {
        englishFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func getYearlyTotalSteps() -> Int {
        let currentMonthSteps = dataManager.monthlyInsight?.totalSteps ?? 0
        if currentMonthSteps > 0 {
            let dailyAverage = currentMonthSteps / 30 // approx
            return dailyAverage * 365
        } else {
            return healthKitManager.currentSteps * 365
        }
    }

    private func getBestMonthName() -> String {
        let currentMonthSteps = dataManager.monthlyInsight?.totalSteps ?? 0
        let df = DateFormatter()
        df.locale = Locale(identifier: "ar")
        df.dateFormat = "MMMM"
        return currentMonthSteps > 0 ? df.string(from: Date()) : "غير محدد"
    }

    private func getYearlyGoalProgress() -> Int {
        let currentYearSteps = getYearlyTotalSteps()
        let cal = Calendar.current
        let now = Date()
        let startOfYear = cal.dateInterval(of: .year, for: now)?.start ?? now
        let daysElapsed = cal.dateComponents([.day], from: startOfYear, to: now).day ?? 1
        let expected = user.goalSteps * max(daysElapsed, 1)
        let pct = expected > 0 ? (Double(currentYearSteps) / Double(expected)) * 100 : 0
        return min(max(Int(pct.rounded()), 0), 100)
    }

    private func getYearlyGoalDays() -> Int {
        let currentMonthGoalDays = dataManager.monthlyInsight?.daysGoalAchieved ?? 0
        let daysElapsed = getDaysElapsed()
        if currentMonthGoalDays > 0 {
            let rate = Double(currentMonthGoalDays) / 30.0
            return Int((rate * Double(daysElapsed)).rounded())
        } else {
            return healthKitManager.currentSteps >= user.goalSteps ? 1 : 0
        }
    }

    private func getDaysElapsed() -> Int {
        let cal = Calendar.current
        let now = Date()
        let startOfYear = cal.dateInterval(of: .year, for: now)?.start ?? now
        return cal.dateComponents([.day], from: startOfYear, to: now).day ?? 1
    }
}

// MARK: - Supporting Views
struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let isImprovement: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primary)

            VStack(spacing: 2) {
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(isImprovement ? color : .primary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(DesignSystem.Colors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isImprovement ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption).bold().foregroundColor(.primary)
        }
    }
}

struct PersonalRecordsView: View {
    let dataManager: DataManager
    let healthKitManager: HealthKitManager

    private let englishFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("الأرقام القياسية").font(.title2).bold()

            VStack(spacing: 12) {
                let personalBestSteps = max(dataManager.personalBest, healthKitManager.currentSteps)
                let personalBestStepsString = englishFormatter.string(from: NSNumber(value: personalBestSteps)) ?? "\(personalBestSteps)"
                PersonalRecordRow(title: "أعلى خطوات في يوم", value: personalBestStepsString, emoji: "🏆")

                let bestDistance = getBestDistance()
                PersonalRecordRow(title: "أكبر مسافة", value: String(format: "%.1f كم", bestDistance), emoji: "📍")

                let bestCalories = getBestCalories()
                PersonalRecordRow(title: "أعلى سعرات محروقة", value: String(format: "%.0f سعرة", bestCalories), emoji: "🔥")

                let bestWeekSteps = getBestWeekSteps()
                let bestWeekStepsString = englishFormatter.string(from: NSNumber(value: bestWeekSteps)) ?? "\(bestWeekSteps) خطوة"
                PersonalRecordRow(title: "أفضل أسبوع", value: bestWeekStepsString, emoji: "⭐")
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func getBestDistance() -> Double {
        let monthlyBest = dataManager.monthlyHealthData.compactMap { $0.distance }.max() ?? 0.0
        return max(monthlyBest, healthKitManager.currentDistance)
    }
    private func getBestCalories() -> Double {
        let monthlyBest = dataManager.monthlyHealthData.compactMap { $0.calories }.max() ?? 0.0
        return max(monthlyBest, healthKitManager.currentCalories)
    }
    private func getBestWeekSteps() -> Int {
        guard let bestWeek = dataManager.monthlyInsight?.bestWeek, !bestWeek.isEmpty else {
            return dataManager.weeklyInsight?.totalSteps ?? healthKitManager.currentSteps
        }
        return bestWeek.reduce(0) { $0 + $1.steps }
    }
}

struct WeeklyPersonalRecordsView: View {
    let dataManager: DataManager
    let healthKitManager: HealthKitManager

    private let englishFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("أرقام قياسية الأسبوع").font(.title2).bold()

            VStack(spacing: 12) {
                let weeklyTotalDistance = max(dataManager.weeklyInsight?.totalDistance ?? 0.0, healthKitManager.currentDistance)
                PersonalRecordRow(title: "إجمالي المسافة", value: String(format: "%.1f كم", weeklyTotalDistance), emoji: "📍")

                let weeklyTotalSteps = dataManager.weeklyInsight?.totalSteps ?? 0
                let weeklyTotalStepsString = englishFormatter.string(from: NSNumber(value: weeklyTotalSteps)) ?? "0"
                PersonalRecordRow(title: "إجمالي خطوات الأسبوع", value: weeklyTotalStepsString, emoji: "📊")

                let weeklyTotalCalories = dataManager.weeklyInsight?.totalCalories ?? 0.0
                PersonalRecordRow(title: "إجمالي السعرات", value: String(format: "%.0f سعرة", weeklyTotalCalories), emoji: "🔥")

                let weeklyGoalDays = dataManager.weeklyInsight?.daysGoalAchieved ?? 0
                PersonalRecordRow(title: "أيام تحقيق الهدف", value: "\(weeklyGoalDays) من 7", emoji: "🎯")
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct MonthlyPersonalRecordsView: View {
    let dataManager: DataManager
    let healthKitManager: HealthKitManager

    private let englishFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en")
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("أرقام قياسية الشهر").font(.title2).bold()

            VStack(spacing: 12) {
                let monthlyTotalDistance = max(dataManager.monthlyInsight?.totalDistance ?? 0.0, healthKitManager.currentDistance)
                PersonalRecordRow(title: "إجمالي المسافة", value: String(format: "%.1f كم", monthlyTotalDistance), emoji: "📍")

                let monthlyTotalSteps = dataManager.monthlyInsight?.totalSteps ?? 0
                let monthlyTotalStepsString = englishFormatter.string(from: NSNumber(value: monthlyTotalSteps)) ?? "0"
                PersonalRecordRow(title: "إجمالي خطوات الشهر", value: monthlyTotalStepsString, emoji: "📊")

                let monthlyTotalCalories = dataManager.monthlyInsight?.totalCalories ?? 0.0
                PersonalRecordRow(title: "إجمالي السعرات", value: String(format: "%.0f سعرة", monthlyTotalCalories), emoji: "🔥")

                let monthlyGoalDays = dataManager.monthlyInsight?.daysGoalAchieved ?? 0
                PersonalRecordRow(title: "أيام تحقيق الهدف", value: "\(monthlyGoalDays) من 30", emoji: "🎯")
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PersonalRecordRow: View {
    let title: String
    let value: String
    let emoji: String

    var body: some View {
        HStack {
            Text(emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.headline).bold()
            }
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

struct PeriodHeaderView: View {
    let selectedPeriod: InsightPeriod

    var body: some View {
        VStack(spacing: 8) {
            Text(getPeriodTitle())
                .font(.title3)
                .bold()
                .foregroundColor(DesignSystem.Colors.text)

            Text(getPeriodSubtitle())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func getPeriodTitle() -> String {
        switch selectedPeriod {
        case .week:  return "الأسبوع الحالي"
        case .month: return "الشهر الحالي"
        case .year:  return "السنة الحالية"
        }
    }

    private func getPeriodSubtitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")

        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "d MMMM yyyy"
            let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
            let startString = formatter.string(from: interval.start)
            let endDate = Calendar.current.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            let endString = formatter.string(from: endDate)
            return "\(startString) - \(endString)"

        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: Date())

        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: Date())
        }
    }
}

// MARK: - Preview
#Preview {
    DataInsightsView()
        .environmentObject(User())
        .environmentObject(HealthKitManager())
        .environmentObject(DataManager())
}

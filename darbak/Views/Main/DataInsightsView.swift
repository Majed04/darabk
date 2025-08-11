//
//  DataInsightsView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI
import Charts

struct DataInsightsView: View {
    @EnvironmentObject var user: User
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var dataManager = DataManager()
    @State private var selectedPeriod: InsightPeriod = .week
    @State private var showingDetailChart = false
    
    enum InsightPeriod: String, CaseIterable {
        case week = "الأسبوع"
        case month = "الشهر"
        case year = "السنة"
    }
    
    private let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 25) {
                    // Period Selector
                    HStack(spacing: 0) {
                        ForEach(InsightPeriod.allCases, id: \.self) { period in
                            Button(action: {
                                selectedPeriod = period
                            }) {
                                Text(period.rawValue)
                                    .font(.caption)
                                    .foregroundColor(selectedPeriod == period ? .white : DesignSystem.Colors.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedPeriod == period ? DesignSystem.Colors.primary : Color.clear)
                                    )
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Key Insights Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                        InsightCard(
                            title: "متوسط الخطوات",
                            value: formatNumber(dataManager.averageStepsThisMonth),
                            subtitle: "خطوة يومياً",
                            icon: "figure.walk",
                            color: Color(hex: "#1B5299")
                        )
                        
                        InsightCard(
                            title: "أفضل يوم",
                            value: formatNumber(dataManager.personalBest),
                            subtitle: "خطوة",
                            icon: "crown.fill",
                            color: .orange
                        )
                        
                        InsightCard(
                            title: "المسافة الكلية",
                            value: String(format: "%.1f", healthKitManager.currentDistance),
                            subtitle: "كيلومتر",
                            icon: "location.fill",
                            color: .green
                        )
                        
                        InsightCard(
                            title: "السعرات المحروقة",
                            value: String(format: "%.0f", healthKitManager.currentCalories),
                            subtitle: "سعرة حرارية",
                            icon: "flame.fill",
                            color: .red
                        )
                        
                        InsightCard(
                            title: "أيام الهدف",
                            value: "\(dataManager.weeklyInsight?.daysGoalAchieved ?? 0)",
                            subtitle: "هذا الأسبوع",
                            icon: "target",
                            color: .purple
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Weekly Chart
                    if selectedPeriod == .week {
                        WeeklyChartView(data: dataManager.getWeeklyChartData(), goal: user.goalSteps)
                            .padding(.horizontal, 20)
                    }
                    
                    // Insights Summary
                    VStack(alignment: .leading, spacing: 15) {
                        Text("تحليل الأداء")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 20)
                        
                        if let weeklyInsight = dataManager.weeklyInsight {
                            InsightSummaryCard(insight: weeklyInsight)
                                .padding(.horizontal, 20)
                        }
                        
                        if let monthlyInsight = dataManager.monthlyInsight {
                            MonthlyInsightCard(insight: monthlyInsight)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    // Personal Records
                    VStack(alignment: .leading, spacing: 15) {
                        Text("الأرقام القياسية")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 20)
                        
                        PersonalRecordsView(dataManager: dataManager, healthKitManager: healthKitManager)
                            .padding(.horizontal, 20)
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
            // Fetch the latest data when the view appears
            healthKitManager.fetchAllTodayData()
            
            // Force a refresh of historical data
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("📊 Force refreshing historical data")
                dataManager.fetchHistoricalData()
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        return englishFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                
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
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(15)
    }
}

struct WeeklyChartView: View {
    let data: [Int]
    let goal: Int
    
    private let daysOfWeek = ["أحد", "اثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("أداء الأسبوع")
                .font(.title2)
                .bold()
            
            HStack(spacing: 10) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 8) {
                        // Bar
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignSystem.Colors.primary.opacity(0.2))
                                .frame(width: 30, height: 120)
                                .overlay(
                                    VStack {
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(data[index] >= goal ? DesignSystem.Colors.primary : Color.gray)
                                            .frame(width: 30, height: max(10, CGFloat(data[index]) / CGFloat(max(data.max() ?? goal, goal)) * 120))
                                    }
                                )
                        }
                        
                        // Day label
                        Text(daysOfWeek[index])
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // Steps
                        Text("\(data[index])")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct InsightSummaryCard: View {
    let insight: WeeklyInsight
    
    private let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("أداء هذا الأسبوع")
                .font(.headline)
                .bold()
            
            VStack(spacing: 8) {
                InsightRow(
                    title: "إجمالي الخطوات",
                    value: englishFormatter.string(from: NSNumber(value: insight.totalSteps)) ?? "\(insight.totalSteps)"
                )
                
                InsightRow(
                    title: "متوسط يومي",
                    value: englishFormatter.string(from: NSNumber(value: insight.averageSteps)) ?? "\(insight.averageSteps)"
                )
                
                InsightRow(
                    title: "أيام تحقيق الهدف",
                    value: "\(insight.daysGoalAchieved) من 7"
                )
                
                InsightRow(
                    title: "إجمالي المسافة",
                    value: String(format: "%.1f كم", insight.totalDistance)
                )
                
                InsightRow(
                    title: "إجمالي السعرات",
                    value: String(format: "%.0f سعرة", insight.totalCalories)
                )
                
                if insight.improvementFromLastWeek != 0 {
                    HStack {
                        Text("التحسن من الأسبوع الماضي")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: insight.improvementFromLastWeek > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                                .foregroundColor(insight.improvementFromLastWeek > 0 ? .green : .red)
                            
                            Text("\(Int(abs(insight.improvementFromLastWeek)))%")
                                .font(.caption)
                                .bold()
                                .foregroundColor(insight.improvementFromLastWeek > 0 ? .green : .red)
                        }
                    }
                }
                
                if let bestDay = insight.bestDay {
                    InsightRow(
                        title: "أفضل يوم",
                        value: englishFormatter.string(from: NSNumber(value: bestDay.steps)) ?? "\(bestDay.steps)"
                    )
                }
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct MonthlyInsightCard: View {
    let insight: MonthlyInsight
    
    private let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("أداء هذا الشهر")
                .font(.headline)
                .bold()
            
            VStack(spacing: 8) {
                InsightRow(
                    title: "إجمالي الخطوات",
                    value: englishFormatter.string(from: NSNumber(value: insight.totalSteps)) ?? "\(insight.totalSteps)"
                )
                
                InsightRow(
                    title: "متوسط يومي",
                    value: englishFormatter.string(from: NSNumber(value: insight.averageSteps)) ?? "\(insight.averageSteps)"
                )
                
                InsightRow(
                    title: "أيام تحقيق الهدف",
                    value: "\(insight.daysGoalAchieved)"
                )
                
                InsightRow(
                    title: "الرقم القياسي الشخصي",
                    value: englishFormatter.string(from: NSNumber(value: insight.personalBest)) ?? "\(insight.personalBest)"
                )
                
                InsightRow(
                    title: "إجمالي المسافة",
                    value: String(format: "%.1f كم", insight.totalDistance)
                )
                
                InsightRow(
                    title: "إجمالي السعرات",
                    value: String(format: "%.0f سعرة", insight.totalCalories)
                )
                
                if insight.improvementFromLastMonth != 0 {
                    HStack {
                        Text("التحسن من الشهر الماضي")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: insight.improvementFromLastMonth > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                                .foregroundColor(insight.improvementFromLastMonth > 0 ? .green : .red)
                            
                            Text("\(Int(abs(insight.improvementFromLastMonth)))%")
                                .font(.caption)
                                .bold()
                                .foregroundColor(insight.improvementFromLastMonth > 0 ? .green : .red)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .bold()
                .foregroundColor(.primary)
        }
    }
}

struct PersonalRecordsView: View {
    let dataManager: DataManager
    let healthKitManager: HealthKitManager
    
    private let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            // Personal Best Steps
            PersonalRecordRow(
                title: "أعلى خطوات في يوم",
                value: englishFormatter.string(from: NSNumber(value: max(dataManager.personalBest, healthKitManager.currentSteps))) ?? "\(max(dataManager.personalBest, healthKitManager.currentSteps))",
                emoji: "🏆"
            )
            
            // Best Distance (calculated from monthly data)
            PersonalRecordRow(
                title: "أكبر مسافة",
                value: String(format: "%.1f كم", getBestDistance()),
                emoji: "📍"
            )
            
            // Best Calories (calculated from monthly data)
            PersonalRecordRow(
                title: "أعلى سعرات محروقة",
                value: String(format: "%.0f سعرة", getBestCalories()),
                emoji: "🔥"
            )
            
            // Best Week Steps
            PersonalRecordRow(
                title: "أفضل أسبوع",
                value: englishFormatter.string(from: NSNumber(value: getBestWeekSteps())) ?? "\(getBestWeekSteps()) خطوة",
                emoji: "⭐"
            )
        }
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

struct PersonalRecordRow: View {
    let title: String
    let value: String
    let emoji: String
    
    var body: some View {
        HStack {
            Text(emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .bold()
            }
            
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(12)
    }
}

#Preview {
    DataInsightsView()
        .environmentObject(User())
        .environmentObject(HealthKitManager())
        .environmentObject(DataManager())
}

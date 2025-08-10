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
                                    .foregroundColor(selectedPeriod == period ? .white : Color(hex: "#1B5299"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedPeriod == period ? Color(hex: "#1B5299") : Color.clear)
                                    )
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#1B5299"), lineWidth: 1)
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
                            value: String(format: "%.1f", dataManager.totalDistance),
                            subtitle: "كيلومتر",
                            icon: "location.fill",
                            color: .green
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
                        
                        PersonalRecordsView()
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
            .navigationTitle("تحليل البيانات")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إغلاق") { dismiss() })
        }
        .onAppear {
            dataManager.setup(with: healthKitManager, user: user)
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
        .background(Color(.systemGray6))
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
                                .fill(Color(hex: "#1B5299").opacity(0.2))
                                .frame(width: 30, height: 120)
                                .overlay(
                                    VStack {
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(data[index] >= goal ? Color(hex: "#1B5299") : Color.gray)
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
        .background(Color(.systemBackground))
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
        .background(Color(.systemBackground))
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
        .background(Color(.systemBackground))
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
    private let records = [
        ("أعلى خطوات في يوم", "15,420", "🏆"),
        ("أطول سلسلة", "25 يوم", "🔥"),
        ("أكبر مسافة", "12.5 كم", "📍"),
        ("أفضل أسبوع", "98,250 خطوة", "⭐")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                HStack {
                    Text(record.2)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.0)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(record.1)
                            .font(.headline)
                            .bold()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    DataInsightsView()
        .environmentObject(User())
        .environmentObject(HealthKitManager())
}

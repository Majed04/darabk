//
//  DataManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import HealthKit

struct DailyStepData {
    let date: Date
    let steps: Int
    let goalAchieved: Bool
}

struct WeeklyInsight {
    let averageSteps: Int
    let totalSteps: Int
    let daysGoalAchieved: Int
    let improvementFromLastWeek: Double
    let bestDay: DailyStepData?
}

struct MonthlyInsight {
    let averageSteps: Int
    let totalSteps: Int
    let daysGoalAchieved: Int
    let improvementFromLastMonth: Double
    let bestWeek: [DailyStepData]
    let personalBest: Int
}

class DataManager: ObservableObject {
    @Published var weeklySteps: [DailyStepData] = []
    @Published var monthlySteps: [DailyStepData] = []
    @Published var weeklyInsight: WeeklyInsight?
    @Published var monthlyInsight: MonthlyInsight?
    @Published var personalBest: Int = 0
    @Published var totalDistance: Double = 0 // in kilometers
    @Published var averageStepsThisMonth: Int = 0
    
    private var healthKitManager: HealthKitManager?
    private var user: User?
    private let healthStore = HKHealthStore()
    
    init() {
        loadStoredData()
    }
    
    func setup(with healthKit: HealthKitManager, user: User) {
        self.healthKitManager = healthKit
        self.user = user
        
        if healthKit.isAuthorized {
            fetchHistoricalData()
        }
    }
    
    func fetchHistoricalData() {
        fetchLastWeekSteps()
        fetchLastMonthSteps()
        calculateInsights()
    }
    
    private func fetchLastWeekSteps() {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return }
        
        fetchStepsData(from: startDate, to: endDate) { [weak self] data in
            DispatchQueue.main.async {
                self?.weeklySteps = data
                self?.calculateWeeklyInsight()
            }
        }
    }
    
    private func fetchLastMonthSteps() {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else { return }
        
        fetchStepsData(from: startDate, to: endDate) { [weak self] data in
            DispatchQueue.main.async {
                self?.monthlySteps = data
                self?.calculateMonthlyInsight()
            }
        }
    }
    
    private func fetchStepsData(from startDate: Date, to endDate: Date, completion: @escaping ([DailyStepData]) -> Void) {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let user = user else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: calendar.startOfDay(for: startDate),
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { [weak self] _, results, error in
            guard let results = results else {
                print("Failed to fetch steps data: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            var stepData: [DailyStepData] = []
            
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                let date = statistics.startDate
                let goalAchieved = Int(steps) >= user.goalSteps
                
                let dailyData = DailyStepData(
                    date: date,
                    steps: Int(steps),
                    goalAchieved: goalAchieved
                )
                stepData.append(dailyData)
                
                // Update personal best
                if Int(steps) > self?.personalBest ?? 0 {
                    DispatchQueue.main.async {
                        self?.personalBest = Int(steps)
                        self?.savePersonalBest()
                    }
                }
            }
            
            completion(stepData.sorted { $0.date < $1.date })
        }
        
        healthStore.execute(query)
    }
    
    private func calculateWeeklyInsight() {
        guard !weeklySteps.isEmpty, let user = user else { return }
        
        let totalSteps = weeklySteps.reduce(0) { $0 + $1.steps }
        let averageSteps = totalSteps / weeklySteps.count
        let daysGoalAchieved = weeklySteps.filter { $0.goalAchieved }.count
        let bestDay = weeklySteps.max { $0.steps < $1.steps }
        
        // Calculate improvement from last week (simplified)
        let lastWeekAverage = getLastWeekAverage()
        let improvement = lastWeekAverage > 0 ? 
            Double(averageSteps - lastWeekAverage) / Double(lastWeekAverage) * 100 : 0
        
        weeklyInsight = WeeklyInsight(
            averageSteps: averageSteps,
            totalSteps: totalSteps,
            daysGoalAchieved: daysGoalAchieved,
            improvementFromLastWeek: improvement,
            bestDay: bestDay
        )
    }
    
    private func calculateMonthlyInsight() {
        guard !monthlySteps.isEmpty, let user = user else { return }
        
        let totalSteps = monthlySteps.reduce(0) { $0 + $1.steps }
        let averageSteps = totalSteps / monthlySteps.count
        let daysGoalAchieved = monthlySteps.filter { $0.goalAchieved }.count
        
        // Find best week (7-day period with highest average)
        let bestWeek = findBestWeek()
        
        // Calculate improvement from last month
        let lastMonthAverage = getLastMonthAverage()
        let improvement = lastMonthAverage > 0 ? 
            Double(averageSteps - lastMonthAverage) / Double(lastMonthAverage) * 100 : 0
        
        monthlyInsight = MonthlyInsight(
            averageSteps: averageSteps,
            totalSteps: totalSteps,
            daysGoalAchieved: daysGoalAchieved,
            improvementFromLastMonth: improvement,
            bestWeek: bestWeek,
            personalBest: personalBest
        )
        
        averageStepsThisMonth = averageSteps
    }
    
    private func findBestWeek() -> [DailyStepData] {
        guard monthlySteps.count >= 7 else { return [] }
        
        var bestWeekStart = 0
        var bestWeekAverage = 0
        
        for i in 0...(monthlySteps.count - 7) {
            let weekData = Array(monthlySteps[i..<(i + 7)])
            let weekAverage = weekData.reduce(0) { $0 + $1.steps } / 7
            
            if weekAverage > bestWeekAverage {
                bestWeekAverage = weekAverage
                bestWeekStart = i
            }
        }
        
        return Array(monthlySteps[bestWeekStart..<(bestWeekStart + 7)])
    }
    
    private func getLastWeekAverage() -> Int {
        // Simplified - you'd want to fetch actual last week's data
        return UserDefaults.standard.integer(forKey: "lastWeekAverage")
    }
    
    private func getLastMonthAverage() -> Int {
        // Simplified - you'd want to fetch actual last month's data
        return UserDefaults.standard.integer(forKey: "lastMonthAverage")
    }
    
    func updateTodaySteps(_ steps: Int) {
        guard let user = user else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let goalAchieved = steps >= user.goalSteps
        
        // Update today's data in weekly array
        if let index = weeklySteps.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            weeklySteps[index] = DailyStepData(date: today, steps: steps, goalAchieved: goalAchieved)
        } else {
            weeklySteps.append(DailyStepData(date: today, steps: steps, goalAchieved: goalAchieved))
        }
        
        // Update personal best
        if steps > personalBest {
            personalBest = steps
            savePersonalBest()
        }
        
        // Recalculate insights
        calculateWeeklyInsight()
    }
    
    private func calculateInsights() {
        calculateWeeklyInsight()
        calculateMonthlyInsight()
    }
    
    private func savePersonalBest() {
        UserDefaults.standard.set(personalBest, forKey: "personalBest")
    }
    
    private func loadStoredData() {
        personalBest = UserDefaults.standard.integer(forKey: "personalBest")
    }
    
    // Get formatted weekly data for charts
    func getWeeklyChartData() -> [Int] {
        let calendar = Calendar.current
        var chartData: [Int] = Array(repeating: 0, count: 7)
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: Date()) {
                let dayStart = calendar.startOfDay(for: date)
                if let stepData = weeklySteps.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
                    chartData[i] = stepData.steps
                }
            }
        }
        
        return chartData
    }
}

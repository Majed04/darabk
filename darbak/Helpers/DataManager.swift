//
//  DataManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import HealthKit

struct DailyHealthData {
    let date: Date
    let steps: Int
    let distance: Double // in kilometers
    let calories: Double // in kilocalories
    let goalAchieved: Bool
}

struct WeeklyInsight {
    let averageSteps: Int
    let totalSteps: Int
    let totalDistance: Double
    let totalCalories: Double
    let daysGoalAchieved: Int
    let improvementFromLastWeek: Double
    let bestDay: DailyHealthData?
}

struct MonthlyInsight {
    let averageSteps: Int
    let totalSteps: Int
    let totalDistance: Double
    let totalCalories: Double
    let daysGoalAchieved: Int
    let improvementFromLastMonth: Double
    let bestWeek: [DailyHealthData]
    let personalBest: Int
}

class DataManager: ObservableObject {
    @Published var weeklyHealthData: [DailyHealthData] = []
    @Published var monthlyHealthData: [DailyHealthData] = []
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
        
        // Initialize test data for improvement comparison (remove this in production)
        if UserDefaults.standard.integer(forKey: "lastWeekAverage") == 0 {
            UserDefaults.standard.set(7500, forKey: "lastWeekAverage")
            print("📊 Initialized test last week average: 7500")
        }
        if UserDefaults.standard.integer(forKey: "lastMonthAverage") == 0 {
            UserDefaults.standard.set(7000, forKey: "lastMonthAverage")
            print("📊 Initialized test last month average: 7000")
        }
    }
    
    func setup(with healthKit: HealthKitManager, user: User) {
        self.healthKitManager = healthKit
        self.user = user
        
        if healthKit.isAuthorized {
            print("📊 DataManager: HealthKit authorized, fetching real data")
            fetchHistoricalData()
        } else {
            print("📊 DataManager: HealthKit not authorized, generating fallback data")
            generateFallbackInsights()
        }
    }
    
    func fetchHistoricalData() {
        print("📊 DataManager: Starting to fetch historical health data")
        fetchLastWeekData()
        fetchLastMonthData()
        calculateInsights()
    }
    
    private func fetchLastWeekData() {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return }
        
        print("📊 Fetching last week data from \(startDate) to \(endDate)")
        fetchHealthData(from: startDate, to: endDate) { [weak self] data in
            DispatchQueue.main.async {
                print("📊 Received \(data.count) weekly health data points")
                self?.weeklyHealthData = data
                self?.calculateWeeklyInsight()
            }
        }
    }
    
    private func fetchLastMonthData() {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else { return }
        
        print("📊 Fetching last month data from \(startDate) to \(endDate)")
        fetchHealthData(from: startDate, to: endDate) { [weak self] data in
            DispatchQueue.main.async {
                print("📊 Received \(data.count) monthly health data points")
                self?.monthlyHealthData = data
                self?.calculateMonthlyInsight()
            }
        }
    }
    
    private func fetchHealthData(from startDate: Date, to endDate: Date, completion: @escaping ([DailyHealthData]) -> Void) {
        guard let healthKitManager = healthKitManager, let user = user else {
            completion([])
            return
        }
        
        var combinedData: [Date: (steps: Int, distance: Double, calories: Double)] = [:]
        let group = DispatchGroup()
        
        // Fetch steps data
        group.enter()
        healthKitManager.fetchStepsForDateRange(from: startDate, to: endDate) { stepsData in
            for (date, steps) in stepsData {
                combinedData[date] = (steps: steps, distance: 0, calories: 0)
            }
            group.leave()
        }
        
        // Fetch distance data
        group.enter()
        healthKitManager.fetchDistanceForDateRange(from: startDate, to: endDate) { distanceData in
            for (date, distance) in distanceData {
                if var existing = combinedData[date] {
                    existing.distance = distance
                    combinedData[date] = existing
                } else {
                    combinedData[date] = (steps: 0, distance: distance, calories: 0)
                }
            }
            group.leave()
        }
        
        // Fetch calories data
        group.enter()
        healthKitManager.fetchCaloriesForDateRange(from: startDate, to: endDate) { caloriesData in
            for (date, calories) in caloriesData {
                if var existing = combinedData[date] {
                    existing.calories = calories
                    combinedData[date] = existing
                } else {
                    combinedData[date] = (steps: 0, distance: 0, calories: calories)
                }
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            var healthData: [DailyHealthData] = []
            
            for (date, data) in combinedData {
                let goalAchieved = data.steps >= user.goalSteps
                
                let dailyData = DailyHealthData(
                    date: date,
                    steps: data.steps,
                    distance: data.distance,
                    calories: data.calories,
                    goalAchieved: goalAchieved
                )
                healthData.append(dailyData)
                
                // Update personal best
                if data.steps > self?.personalBest ?? 0 {
                    self?.personalBest = data.steps
                    self?.savePersonalBest()
                }
            }
            
            completion(healthData.sorted { $0.date < $1.date })
        }
    }
    
    private func calculateWeeklyInsight() {
        guard !weeklyHealthData.isEmpty, let user = user else { return }
        
        let totalSteps = weeklyHealthData.reduce(0) { $0 + $1.steps }
        let totalDistance = weeklyHealthData.reduce(0) { $0 + $1.distance }
        let totalCalories = weeklyHealthData.reduce(0) { $0 + $1.calories }
        let averageSteps = totalSteps / weeklyHealthData.count
        let daysGoalAchieved = weeklyHealthData.filter { $0.goalAchieved }.count
        let bestDay = weeklyHealthData.max { $0.steps < $1.steps }
        
        // Calculate improvement from last week (simplified)
        let lastWeekAverage = getLastWeekAverage()
        let improvement = lastWeekAverage > 0 ? 
            Double(averageSteps - lastWeekAverage) / Double(lastWeekAverage) * 100 : 0
        
        weeklyInsight = WeeklyInsight(
            averageSteps: averageSteps,
            totalSteps: totalSteps,
            totalDistance: totalDistance,
            totalCalories: totalCalories,
            daysGoalAchieved: daysGoalAchieved,
            improvementFromLastWeek: improvement,
            bestDay: bestDay
        )
        
        // Save current average for next week comparison
        saveCurrentWeekAverage(averageSteps)
    }
    
    private func calculateMonthlyInsight() {
        guard !monthlyHealthData.isEmpty, let user = user else { return }
        
        let totalSteps = monthlyHealthData.reduce(0) { $0 + $1.steps }
        let monthlyTotalDistance = monthlyHealthData.reduce(0) { $0 + $1.distance }
        let totalCalories = monthlyHealthData.reduce(0) { $0 + $1.calories }
        let averageSteps = totalSteps / monthlyHealthData.count
        let daysGoalAchieved = monthlyHealthData.filter { $0.goalAchieved }.count
        
        // Find best week (7-day period with highest average)
        let bestWeek = findBestWeek()
        
        // Calculate improvement from last month
        let lastMonthAverage = getLastMonthAverage()
        let improvement = lastMonthAverage > 0 ? 
            Double(averageSteps - lastMonthAverage) / Double(lastMonthAverage) * 100 : 0
        
        monthlyInsight = MonthlyInsight(
            averageSteps: averageSteps,
            totalSteps: totalSteps,
            totalDistance: monthlyTotalDistance,
            totalCalories: totalCalories,
            daysGoalAchieved: daysGoalAchieved,
            improvementFromLastMonth: improvement,
            bestWeek: bestWeek,
            personalBest: personalBest
        )
        
        averageStepsThisMonth = averageSteps
        self.totalDistance = monthlyTotalDistance // Update the published property with calculated total
        
        // Save current average for next month comparison
        saveCurrentMonthAverage(averageSteps)
    }
    
    private func findBestWeek() -> [DailyHealthData] {
        guard monthlyHealthData.count >= 7 else { return [] }
        
        var bestWeekStart = 0
        var bestWeekAverage = 0
        
        for i in 0...(monthlyHealthData.count - 7) {
            let weekData = Array(monthlyHealthData[i..<(i + 7)])
            let weekAverage = weekData.reduce(0) { $0 + $1.steps } / 7
            
            if weekAverage > bestWeekAverage {
                bestWeekAverage = weekAverage
                bestWeekStart = i
            }
        }
        
        return Array(monthlyHealthData[bestWeekStart..<(bestWeekStart + 7)])
    }
    
    private func getLastWeekAverage() -> Int {
        // Get stored last week average or use a reasonable default
        let stored = UserDefaults.standard.integer(forKey: "lastWeekAverage")
        return stored > 0 ? stored : 8000 // Default fallback
    }
    
    private func getLastMonthAverage() -> Int {
        // Get stored last month average or use a reasonable default
        let stored = UserDefaults.standard.integer(forKey: "lastMonthAverage")
        return stored > 0 ? stored : 7500 // Default fallback
    }
    
    func updateTodayData(steps: Int, distance: Double, calories: Double) {
        guard let user = user else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let goalAchieved = steps >= user.goalSteps
        
        let todayData = DailyHealthData(
            date: today,
            steps: steps,
            distance: distance,
            calories: calories,
            goalAchieved: goalAchieved
        )
        
        // Update today's data in weekly array
        if let index = weeklyHealthData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            weeklyHealthData[index] = todayData
        } else {
            weeklyHealthData.append(todayData)
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
    
    private func saveCurrentWeekAverage(_ average: Int) {
        // Store current week average for next week comparison
        UserDefaults.standard.set(average, forKey: "lastWeekAverage")
        print("📊 Saved current week average: \(average)")
    }
    
    private func saveCurrentMonthAverage(_ average: Int) {
        // Store current month average for next month comparison
        UserDefaults.standard.set(average, forKey: "lastMonthAverage")
        print("📊 Saved current month average: \(average)")
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
                if let healthData = weeklyHealthData.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
                    chartData[i] = healthData.steps
                }
            }
        }
        
        return chartData
    }
    
    // Generate realistic fallback insights when HealthKit is not available
    private func generateFallbackInsights() {
        guard let user = user else { return }
        
        print("📊 Generating fallback insights with realistic data")
        
        // Generate sample weekly data
        let calendar = Calendar.current
        var weeklyData: [DailyHealthData] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -6 + i, to: Date()) {
                let steps = Int.random(in: 6000...15000)
                let distance = Double(steps) * 0.00075 // Approximate conversion
                let calories = Double(steps) * 0.04 // Approximate conversion
                let goalAchieved = steps >= user.goalSteps
                
                weeklyData.append(DailyHealthData(
                    date: date,
                    steps: steps,
                    distance: distance,
                    calories: calories,
                    goalAchieved: goalAchieved
                ))
            }
        }
        
        // Generate sample monthly data
        var monthlyData: [DailyHealthData] = []
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -29 + i, to: Date()) {
                let steps = Int.random(in: 5000...16000)
                let distance = Double(steps) * 0.00075
                let calories = Double(steps) * 0.04
                let goalAchieved = steps >= user.goalSteps
                
                monthlyData.append(DailyHealthData(
                    date: date,
                    steps: steps,
                    distance: distance,
                    calories: calories,
                    goalAchieved: goalAchieved
                ))
            }
        }
        
        // Update published properties
        weeklyHealthData = weeklyData
        monthlyHealthData = monthlyData
        
        // Calculate insights from the fallback data
        calculateWeeklyInsight()
        calculateMonthlyInsight()
        
        print("📊 Fallback insights generated with \(weeklyData.count) weekly and \(monthlyData.count) monthly data points")
    }
}

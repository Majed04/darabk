//
//  StreakManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import HealthKit

class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastStreakDate: Date?
    @Published var streakHistory: [Date: Bool] = [:]
    
    private var healthKitManager: HealthKitManager?
    private var user: User?
    
    init() {
        print("📈 StreakManager initializing...")
        loadStreakData()
        print("📈 StreakManager initialization complete")
    }
    
    func setup(with healthKit: HealthKitManager, user: User) {
        self.healthKitManager = healthKit
        self.user = user
        calculateCurrentStreak()
    }
    
    func calculateCurrentStreak() {
        guard let user = user else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        
        // Check backwards from today to find consecutive days with goal achievement
        while true {
            if let steps = getStepsForDate(checkDate) {
                if steps >= user.goalSteps {
                    streak += 1
                    streakHistory[checkDate] = true
                } else {
                    streakHistory[checkDate] = false
                    break
                }
            } else {
                break
            }
            
            // Move to previous day
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }
        
        DispatchQueue.main.async {
            self.currentStreak = streak
            if streak > self.longestStreak {
                self.longestStreak = streak
            }
            self.lastStreakDate = streak > 0 ? today : nil
            self.saveStreakData()
        }
    }
    
    func updateStreakForToday() {
        guard let user = user else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        if let todaySteps = getStepsForDate(today) {
            let goalAchieved = todaySteps >= user.goalSteps
            
            // Update today's streak status
            streakHistory[today] = goalAchieved
            
            // Recalculate current streak
            calculateCurrentStreak()
        }
    }
    
    private func getStepsForDate(_ date: Date) -> Int? {
        guard let healthKitManager = healthKitManager else { return nil }
        
        // For today, we can use the current steps
        if Calendar.current.isDateInToday(date) {
            return healthKitManager.currentSteps
        }
        
        // For historical dates, check stored data first
        return getHistoricalSteps(for: date)
    }
    
    private func getHistoricalSteps(for date: Date) -> Int? {
        // Check if we have stored data for this date
        let key = "steps_\(date.timeIntervalSince1970)"
        let steps = UserDefaults.standard.integer(forKey: key)
        return steps > 0 ? steps : nil
    }
    
    func fetchHistoricalDataAndCalculateStreak() {
        guard let healthKitManager = healthKitManager else { return }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else { return }
        
        healthKitManager.fetchStepsForDateRange(from: startDate, to: endDate) { [weak self] stepsData in
            // Store the fetched data
            for (date, steps) in stepsData {
                self?.saveStepsForDate(date, steps: steps)
            }
            
            // Recalculate streak with new data
            self?.calculateCurrentStreak()
        }
    }
    
    func saveStepsForDate(_ date: Date, steps: Int) {
        let key = "steps_\(date.timeIntervalSince1970)"
        UserDefaults.standard.set(steps, forKey: key)
    }
    
    func isStreakDay(_ date: Date) -> Bool {
        let dayStart = Calendar.current.startOfDay(for: date)
        return streakHistory[dayStart] ?? false
    }
    
    func getStreakDays() -> [Date] {
        return streakHistory.compactMap { key, value in
            return value ? key : nil
        }.sorted()
    }
    
    private func saveStreakData() {
        UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
        UserDefaults.standard.set(longestStreak, forKey: "longestStreak")
        
        if let lastStreakDate = lastStreakDate {
            UserDefaults.standard.set(lastStreakDate, forKey: "lastStreakDate")
        }
        
        // Save streak history - convert Date keys to TimeInterval
        var timeIntervalHistory: [String: Bool] = [:]
        for (date, value) in streakHistory {
            timeIntervalHistory[String(date.timeIntervalSince1970)] = value
        }
        
        if let historyData = try? JSONSerialization.data(withJSONObject: timeIntervalHistory) {
            UserDefaults.standard.set(historyData, forKey: "streakHistory")
        }
    }
    
    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        longestStreak = UserDefaults.standard.integer(forKey: "longestStreak")
        
        if let lastDate = UserDefaults.standard.object(forKey: "lastStreakDate") as? Date {
            lastStreakDate = lastDate
        }
        
        // Load streak history - convert back from String keys to Date keys
        if let historyData = UserDefaults.standard.data(forKey: "streakHistory") {
            do {
                if let historyDict = try JSONSerialization.jsonObject(with: historyData) as? [String: Bool] {
                    streakHistory = [:]
                    for (timeIntervalString, value) in historyDict {
                        if let timeInterval = Double(timeIntervalString) {
                            let date = Date(timeIntervalSince1970: timeInterval)
                            streakHistory[date] = value
                        }
                    }
                    print("📈 Successfully loaded streak history with \(streakHistory.count) entries")
                } else {
                    print("📈 Failed to parse streak history, starting fresh")
                    streakHistory = [:]
                    // Clear the corrupted data
                    UserDefaults.standard.removeObject(forKey: "streakHistory")
                }
            } catch {
                print("📈 Error loading streak history: \(error.localizedDescription)")
                streakHistory = [:]
                // Clear the corrupted data
                UserDefaults.standard.removeObject(forKey: "streakHistory")
            }
        }
    }
}

//
//  AchievementManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import SwiftUI

enum AchievementType: Codable {
    case steps(Int)
    case streak(Int)
    case challenges(Int)
    case distance(Double)
    case consistency(Int) // days in a month
    case milestone(Int)
    case badge // Added for badge achievements
}

struct Achievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let type: AchievementType
    var isUnlocked: Bool
    var unlockedDate: Date?
    let progress: Double // 0.0 to 1.0
    let currentValue: Int
    let targetValue: Int
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description, icon, type, isUnlocked, unlockedDate, progress, currentValue, targetValue
    }
    
    init(title: String, description: String, icon: String, type: AchievementType, isUnlocked: Bool = false, unlockedDate: Date? = nil, progress: Double = 0.0, currentValue: Int = 0, targetValue: Int) {
        self.title = title
        self.description = description
        self.icon = icon
        self.type = type
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
        self.currentValue = currentValue
        self.targetValue = targetValue
    }
}

struct Badge: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: String
    let earnedDate: Date
    let associatedAchievement: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, icon, color, earnedDate, associatedAchievement
    }
}

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var badges: [Badge] = []
    @Published var recentUnlocks: [Achievement] = []
    @Published var showingAchievementAlert = false
    @Published var latestAchievement: Achievement?
    
    private var user: User?
    private var healthKitManager: HealthKitManager?
    private var streakManager: StreakManager?
    
    init() {
        initializeAchievements()
        loadProgress()
    }
    
    func setup(with user: User, healthKit: HealthKitManager, streak: StreakManager) {
        self.user = user
        self.healthKitManager = healthKit
        self.streakManager = streak
        updateProgress()
    }
    
    private func initializeAchievements() {
        achievements = [
            // Step Achievements
            Achievement(
                title: "الخطوة الأولى",
                description: "أكمل 1000 خطوة في يوم واحد",
                icon: "figure.walk",
                type: .steps(1000),
                targetValue: 1000
            ),
            Achievement(
                title: "شاد حيلك",
                description: "أكمل 5000 خطوة في يوم واحد",
                icon: "figure.walk.circle",
                type: .steps(5000),
                targetValue: 5000
            ),
            Achievement(
                title: "ماراثوني",
                description: "أكمل 10000 خطوة في يوم واحد",
                icon: "figure.run",
                type: .steps(10000),
                targetValue: 10000
            ),
            Achievement(
                title: "مدير الماراثون",
                description: "أكمل 15000 خطوة في يوم واحد",
                icon: "figure.run.circle",
                type: .steps(15000),
                targetValue: 15000
            ),
            Achievement(
                title: "الأسطورة",
                description: "أكمل 20000 خطوة في يوم واحد",
                icon: "crown.fill",
                type: .steps(20000),
                targetValue: 20000
            ),
            
            // Streak Achievements
            Achievement(
                title: "البداية القوية",
                description: "حافظ على سلسلة لمدة 3 أيام",
                icon: "flame",
                type: .streak(3),
                targetValue: 3
            ),
            Achievement(
                title: "أسبوع من الالتزام",
                description: "حافظ على سلسلة لمدة 7 أيام",
                icon: "flame.fill",
                type: .streak(7),
                targetValue: 7
            ),
            Achievement(
                title: "الصامل",
                description: "حافظ على سلسلة لمدة 30 يوم",
                icon: "flame.circle.fill",
                type: .streak(30),
                targetValue: 30
            ),
            Achievement(
                title: "مدير الصملة",
                description: "حافظ على سلسلة لمدة 100 يوم",
                icon: "star.circle.fill",
                type: .streak(100),
                targetValue: 100
            ),
            
            // Challenge Achievements
            Achievement(
                title: "المتحدي",
                description: "أكمل تحدي واحد",
                icon: "target",
                type: .challenges(1),
                targetValue: 1
            ),
            Achievement(
                title: "جامع التحديات",
                description: "أكمل 5 تحديات",
                icon: "checkmark.circle.fill",
                type: .challenges(5),
                targetValue: 5
            ),
            Achievement(
                title: "مدير التحديات",
                description: "أكمل 10 تحديات",
                icon: "star.fill",
                type: .challenges(10),
                targetValue: 10
            ),
            
            // Distance Achievements
            Achievement(
                title: "أول كيلو",
                description: "امش مسافة كيلومتر واحد",
                icon: "location.fill",
                type: .distance(1.0),
                targetValue: 1
            ),
            Achievement(
                title: "المسافات الطويلة",
                description: "امش مسافة 5 كيلومترات",
                icon: "map.fill",
                type: .distance(5.0),
                targetValue: 5
            ),
            
            // Consistency Achievements
            Achievement(
                title: "الثبات الأسبوعي",
                description: "حقق هدفك 5 أيام في الأسبوع",
                icon: "calendar",
                type: .consistency(5),
                targetValue: 5
            ),
            Achievement(
                title: "الثبات الشهري",
                description: "حقق هدفك 20 يوم في الشهر",
                icon: "calendar.circle.fill",
                type: .consistency(20),
                targetValue: 20
            )
        ]
    }
    
    func updateProgress() {
        guard let user = user,
              let healthKit = healthKitManager,
              let streak = streakManager else { return }
        
        for i in 0..<achievements.count {
            let achievement = achievements[i]
            var newProgress = achievement.progress
            var currentValue = achievement.currentValue
            var isUnlocked = achievement.isUnlocked
            var unlockedDate = achievement.unlockedDate
            
            switch achievement.type {
            case .steps(let target):
                currentValue = healthKit.currentSteps
                newProgress = min(Double(currentValue) / Double(target), 1.0)
                if currentValue >= target && !isUnlocked {
                    isUnlocked = true
                    unlockedDate = Date()
                    unlockAchievement(achievement)
                }
                
            case .streak(let target):
                currentValue = streak.currentStreak
                newProgress = min(Double(currentValue) / Double(target), 1.0)
                if currentValue >= target && !isUnlocked {
                    isUnlocked = true
                    unlockedDate = Date()
                    unlockAchievement(achievement)
                }
                
            case .challenges(let target):
                currentValue = getCompletedChallengesCount()
                newProgress = min(Double(currentValue) / Double(target), 1.0)
                if currentValue >= target && !isUnlocked {
                    isUnlocked = true
                    unlockedDate = Date()
                    unlockAchievement(achievement)
                }
                
            case .distance(let target):
                let distance = calculateDistanceFromSteps(healthKit.currentSteps)
                currentValue = Int(distance)
                newProgress = min(distance / target, 1.0)
                if distance >= target && !isUnlocked {
                    isUnlocked = true
                    unlockedDate = Date()
                    unlockAchievement(achievement)
                }
                
            case .consistency(let target):
                currentValue = getConsistencyDaysThisMonth()
                newProgress = min(Double(currentValue) / Double(target), 1.0)
                if currentValue >= target && !isUnlocked {
                    isUnlocked = true
                    unlockedDate = Date()
                    unlockAchievement(achievement)
                }
                
            case .milestone(let target):
                // Handle milestone achievements
                break
            case .badge:
                // Handle badge achievements
                break
            }
            
            achievements[i] = Achievement(
                title: achievement.title,
                description: achievement.description,
                icon: achievement.icon,
                type: achievement.type,
                isUnlocked: isUnlocked,
                unlockedDate: unlockedDate,
                progress: newProgress,
                currentValue: currentValue,
                targetValue: achievement.targetValue
            )
        }
        
        saveProgress()
    }
    
    func unlockAchievement(_ achievement: Achievement) {
        guard !achievement.isUnlocked else { return }
        
        // Find the achievement in the array and update it
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            achievements[index].isUnlocked = true
            achievements[index].unlockedDate = Date()
            
            // Save to UserDefaults
            saveProgress()
            
            // Show achievement alert
            latestAchievement = achievements[index]
            showingAchievementAlert = true
            
            // Sync with Game Center
            GameCenterManager.shared.unlockAchievement(achievement.title)
            
            // Add to badges if it's a badge achievement
            if case .badge = achievement.type {
                let badge = Badge(
                    name: achievement.title,
                    description: achievement.description,
                    icon: achievement.icon,
                    color: "#1B5299",
                    earnedDate: Date(),
                    associatedAchievement: achievement.title
                )
                badges.append(badge)
                saveProgress() // Use saveProgress instead of saveBadges
            }
        }
    }
    
    func getCompletedChallengesCount() -> Int {
        return UserDefaults.standard.integer(forKey: "completedChallengesCount")
    }
    
    func incrementCompletedChallenges() {
        let current = getCompletedChallengesCount()
        UserDefaults.standard.set(current + 1, forKey: "completedChallengesCount")
        updateProgress()
    }
    
    private func calculateDistanceFromSteps(_ steps: Int) -> Double {
        // Average step length is about 0.762 meters
        let meters = Double(steps) * 0.762
        return meters / 1000.0 // Convert to kilometers
    }
    
    private func getConsistencyDaysThisMonth() -> Int {
        // This would calculate how many days this month the user achieved their goal
        // For now, return a placeholder
        return UserDefaults.standard.integer(forKey: "consistencyDaysThisMonth")
    }
    
    func updateConsistencyForToday(_ achieved: Bool) {
        if achieved {
            let current = getConsistencyDaysThisMonth()
            UserDefaults.standard.set(current + 1, forKey: "consistencyDaysThisMonth")
            updateProgress()
        }
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        return achievements.filter { $0.isUnlocked }
    }
    
    func getInProgressAchievements() -> [Achievement] {
        return achievements.filter { !$0.isUnlocked && $0.progress > 0 }
    }
    
    func getLockedAchievements() -> [Achievement] {
        return achievements.filter { !$0.isUnlocked && $0.progress == 0 }
    }
    
    private func saveProgress() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }
        
        if let badgeData = try? JSONEncoder().encode(badges) {
            UserDefaults.standard.set(badgeData, forKey: "badges")
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let savedAchievements = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Merge saved progress with current achievements
            for (index, achievement) in achievements.enumerated() {
                if let saved = savedAchievements.first(where: { $0.title == achievement.title }) {
                    achievements[index] = saved
                }
            }
        }
        
        if let badgeData = UserDefaults.standard.data(forKey: "badges"),
           let savedBadges = try? JSONDecoder().decode([Badge].self, from: badgeData) {
            badges = savedBadges
        }
    }
}

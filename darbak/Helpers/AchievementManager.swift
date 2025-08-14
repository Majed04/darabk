//
//  AchievementManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import SwiftUI

// MARK: - Types

enum AchievementType: Codable {
    case steps(Int)
    case streak(Int)
    case challenges(Int)
    case distance(Double)
    case consistency(Int) // days in a month
    case milestone(Int)
    case badge
}

struct Achievement: Identifiable, Codable {
    // Keep a stable id so UI selections/snapping don't break
    let id: UUID

    let title: String
    let description: String
    let icon: String
    let imageName: String? // custom image asset name
    let type: AchievementType

    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Double    // 0.0 ... 1.0
    var currentValue: Int
    let targetValue: Int

    private enum CodingKeys: String, CodingKey {
        case id, title, description, icon, imageName, type, isUnlocked, unlockedDate, progress, currentValue, targetValue
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        imageName: String? = nil,
        type: AchievementType,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        progress: Double = 0.0,
        currentValue: Int = 0,
        targetValue: Int
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.imageName = imageName
        self.type = type
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
        self.currentValue = currentValue
        self.targetValue = targetValue
    }

    /// Returns a copy with only mutable fields changed (leaves id/title/imageName/etc. intact)
    func updating(
        isUnlocked: Bool? = nil,
        unlockedDate: Date?? = nil,
        progress: Double? = nil,
        currentValue: Int? = nil
    ) -> Achievement {
        Achievement(
            id: id,
            title: title,
            description: description,
            icon: icon,
            imageName: imageName,
            type: type,
            isUnlocked: isUnlocked ?? self.isUnlocked,
            unlockedDate: unlockedDate ?? self.unlockedDate,
            progress: progress ?? self.progress,
            currentValue: currentValue ?? self.currentValue,
            targetValue: targetValue
        )
    }
}

struct Badge: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let color: String
    let earnedDate: Date
    let associatedAchievement: String

    private enum CodingKeys: String, CodingKey {
        case id, name, description, icon, color, earnedDate, associatedAchievement
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        icon: String,
        color: String,
        earnedDate: Date,
        associatedAchievement: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.earnedDate = earnedDate
        self.associatedAchievement = associatedAchievement
    }
}

// MARK: - Manager

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var badges: [Badge] = []
    @Published var recentUnlocks: [Achievement] = []
    @Published var showingAchievementAlert = false
    @Published var latestAchievement: Achievement?

    private var user: User?
    private var healthKitManager: HealthKitManager?
    private var streakManager: StreakManager?

    /// Template (source of truth for static fields like `imageName`)
    private lazy var templateAchievements: [Achievement] = Self.makeTemplate()

    init() {
        // Start from template, then load saved progress and backfill missing fields
        achievements = templateAchievements
        loadProgressAndMigrate()
        
        // Clear saved data to reset for testing
        UserDefaults.standard.removeObject(forKey: "achievements")
        UserDefaults.standard.removeObject(forKey: "badges")
        
        // Reset all achievements to locked state
        for i in achievements.indices {
            achievements[i].isUnlocked = false
            achievements[i].unlockedDate = nil
            achievements[i].progress = 0.0
            achievements[i].currentValue = 0
        }
        
                        // Reset all achievements to locked state (no test values)
                for (index, _) in achievements.enumerated() {
                    achievements[index].isUnlocked = false
                    achievements[index].unlockedDate = nil
                    achievements[index].progress = 0.0
                    achievements[index].currentValue = 0
                }
        
        saveProgress()
    }

    func setup(with user: User, healthKit: HealthKitManager, streak: StreakManager) {
        self.user = user
        self.healthKitManager = healthKit
        self.streakManager = streak
        updateProgress()
    }

    // MARK: - Template

    private static func makeTemplate() -> [Achievement] {
        return [
            // Step Achievements
            Achievement(
                title: "الخطوة الأولى",
                description: "أكمل 1000 خطوة في يوم واحد",
                icon: "",
                imageName: "1000Steps",
                type: .steps(1000),
                targetValue: 1000
            ),
            Achievement(
                title: "شاد حيلك",
                description: "أكمل 5000 خطوة في يوم واحد",
                icon: "",
                imageName: "5000Steps",
                type: .steps(5000),
                targetValue: 5000
            ),
            Achievement(
                title: "ماراثوني",
                description: "أكمل 10000 خطوة في يوم واحد",
                icon: "",
                imageName: "10kSteps",
                type: .steps(10000),
                targetValue: 10000
            ),
            Achievement(
                title: "مدير الماراثون",
                description: "أكمل 15000 خطوة في يوم واحد",
                icon: "",
                imageName: "15kSteps",
                type: .steps(15000),
                targetValue: 15000
            ),
            Achievement(
                title: "الأسطورة",
                description: "أكمل 20000 خطوة في يوم واحد",
                icon: "",
                imageName: "20kSteps",
                type: .steps(20000),
                targetValue: 20000
            ),

            // Streak Achievements
            Achievement(
                title: "البداية القوية",
                description: "حافظ على سلسلة لمدة 3 أيام",
                icon: "",
                imageName: "3days",
                type: .streak(3),
                targetValue: 3
            ),
            Achievement(
                title: "أسبوع من الالتزام",
                description: "حافظ على سلسلة لمدة 7 أيام",
                icon: "",
                imageName: "7days",
                type: .streak(7),
                targetValue: 7
            ),
            Achievement(
                title: "الصامل",
                description: "حافظ على سلسلة لمدة 30 يوم",
                icon: "",
                imageName: "30days",
                type: .streak(30),
                targetValue: 30
            ),
            Achievement(
                title: "مدير الصملة",
                description: "حافظ على سلسلة لمدة 100 يوم",
                icon: "",
                imageName: "100days",
                type: .streak(100),
                targetValue: 100
            ),

            // Challenge Achievements
            Achievement(
                title: "المتحدي",
                description: "أكمل تحدي واحد",
                icon: "",
                imageName: "1challenge",
                type: .challenges(1),
                targetValue: 1
            ),
            Achievement(
                title: "جامع التحديات",
                description: "أكمل 5 تحديات",
                icon: "",
                imageName: "5challenges",
                type: .challenges(5),
                targetValue: 5
            ),
            Achievement(
                title: "مدير التحديات",
                description: "أكمل 10 تحديات",
                icon: "",
                imageName: "10challenges",
                type: .challenges(10),
                targetValue: 10
            ),

            // Distance Achievements
            Achievement(
                title: "أول كيلو",
                description: "امش مسافة كيلومتر واحد",
                icon: "",
                imageName: "1km",
                type: .distance(1.0),
                targetValue: 1
            ),
            Achievement(
                title: "المسافات الطويلة",
                description: "امش مسافة 5 كيلومترات",
                icon: "",
                imageName: "5km",
                type: .distance(5.0),
                targetValue: 5
            ),

            // Consistency Achievements
            Achievement(
                title: "الثبات الأسبوعي",
                description: "حقق هدفك 5 أيام في الأسبوع",
                icon: "",
                imageName: "5outof7",
                type: .consistency(5),
                targetValue: 5
            ),
            Achievement(
                title: "الثبات الشهري",
                description: "حقق هدفك 20 يوم في الشهر",
                icon: "",
                imageName: "20outof30",
                type: .consistency(20),
                targetValue: 20
            )
        ]
    }

    // MARK: - Progress

    func updateProgress() {
        guard let healthKit = healthKitManager,
              let streak = streakManager else { return }

        for i in achievements.indices {
            var a = achievements[i]

            switch a.type {
            case .steps(let target):
                a.currentValue = healthKit.currentSteps
                a.progress = min(Double(a.currentValue) / Double(target), 1.0)
                if a.currentValue >= target && !a.isUnlocked {
                    a.isUnlocked = true
                    a.unlockedDate = Date()
                    unlockAchievement(a)
                }

            case .streak(let target):
                a.currentValue = streak.currentStreak
                a.progress = min(Double(a.currentValue) / Double(target), 1.0)
                if a.currentValue >= target && !a.isUnlocked {
                    a.isUnlocked = true
                    a.unlockedDate = Date()
                    unlockAchievement(a)
                }

            case .challenges(let target):
                a.currentValue = getCompletedChallengesCount()
                a.progress = min(Double(a.currentValue) / Double(target), 1.0)
                if a.currentValue >= target && !a.isUnlocked {
                    a.isUnlocked = true
                    a.unlockedDate = Date()
                    unlockAchievement(a)
                }

            case .distance(let target):
                let distanceKm = calculateDistanceFromSteps(healthKit.currentSteps)
                a.currentValue = Int(distanceKm)
                a.progress = min(distanceKm / target, 1.0)
                if distanceKm >= target && !a.isUnlocked {
                    a.isUnlocked = true
                    a.unlockedDate = Date()
                    unlockAchievement(a)
                }

            case .consistency(let target):
                a.currentValue = getConsistencyDaysThisMonth()
                a.progress = min(Double(a.currentValue) / Double(target), 1.0)
                if a.currentValue >= target && !a.isUnlocked {
                    a.isUnlocked = true
                    a.unlockedDate = Date()
                    unlockAchievement(a)
                }

            case .milestone, .badge:
                break
            }

            achievements[i] = a // <- preserves imageName and id
        }

        saveProgress()
    }

    func unlockAchievement(_ achievement: Achievement) {
        guard !achievement.isUnlocked else { return }
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            achievements[index].isUnlocked = true
            achievements[index].unlockedDate = Date()

            saveProgress()

            latestAchievement = achievements[index]
            showingAchievementAlert = true

            GameCenterManager.shared.unlockAchievement(achievement.title)

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
                saveProgress()
            }
        }
    }

    // MARK: - Helpers

    func getCompletedChallengesCount() -> Int {
        UserDefaults.standard.integer(forKey: "completedChallengesCount")
    }

    func incrementCompletedChallenges() {
        let current = getCompletedChallengesCount()
        UserDefaults.standard.set(current + 1, forKey: "completedChallengesCount")
        updateProgress()
    }

    private func calculateDistanceFromSteps(_ steps: Int) -> Double {
        // Average step length ≈ 0.762m
        let meters = Double(steps) * 0.762
        return meters / 1000.0 // km
    }

    private func getConsistencyDaysThisMonth() -> Int {
        UserDefaults.standard.integer(forKey: "consistencyDaysThisMonth")
    }

    func updateConsistencyForToday(_ achieved: Bool) {
        if achieved {
            let current = getConsistencyDaysThisMonth()
            UserDefaults.standard.set(current + 1, forKey: "consistencyDaysThisMonth")
            updateProgress()
        }
    }

    func getUnlockedAchievements() -> [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    func getInProgressAchievements() -> [Achievement] {
        achievements.filter { !$0.isUnlocked && $0.progress > 0 }
    }

    func getLockedAchievements() -> [Achievement] {
        achievements.filter { !$0.isUnlocked && $0.progress == 0 }
    }

    // MARK: - Persistence

    private func saveProgress() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }

        if let badgeData = try? JSONEncoder().encode(badges) {
            UserDefaults.standard.set(badgeData, forKey: "badges")
        }
    }

    /// Loads saved progress and backfills missing static fields (like imageName) from the template.
    private func loadProgressAndMigrate() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {

            // Merge by title (your existing logic) but preserve static fields from template if missing in saved
            var merged: [Achievement] = templateAchievements

            for (i, base) in templateAchievements.enumerated() {
                if let s = saved.first(where: { $0.title == base.title }) {
                    // Backfill missing imageName from template if nil in saved
                    let img = s.imageName ?? base.imageName
                    merged[i] = Achievement(
                        id: s.id,                      // keep saved id
                        title: s.title,                // same
                        description: s.description,
                        icon: s.icon,
                        imageName: img,                // <— key: keep or backfill
                        type: s.type,
                        isUnlocked: s.isUnlocked,
                        unlockedDate: s.unlockedDate,
                        progress: s.progress,
                        currentValue: s.currentValue,
                        targetValue: s.targetValue
                    )
                }
            }

            achievements = merged
        }

        if let badgeData = UserDefaults.standard.data(forKey: "badges"),
           let savedBadges = try? JSONDecoder().decode([Badge].self, from: badgeData) {
            badges = savedBadges
        }
    }
}

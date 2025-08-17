//
//  NotificationManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var dailyReminderEnabled = true
    @Published var goalAchievementEnabled = true
    @Published var streakReminderEnabled = true
    @Published var challengeNotificationsEnabled = true
    
    private var user: User?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        loadSettings()
        requestAuthorization()
    }
    
    func setup(with user: User) {
        self.user = user
        scheduleNotifications()
    }
    
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.scheduleNotifications()
                }
            }
        }
    }
    
    func scheduleNotifications() {
        guard isAuthorized else { return }
        
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        if dailyReminderEnabled {
            scheduleDailyReminder()
        }
        
        if streakReminderEnabled {
            scheduleStreakReminder()
        }
        
        if goalAchievementEnabled {
            scheduleGoalCheckReminder()
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "وقت المشي! 🚶‍♂️"
        content.body = "شد حيلك و كمل هدفك اليوم"
        content.sound = .default
   
        
        // Schedule for 9 AM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleStreakReminder() {
        let content = UNMutableNotificationContent()
        content.title = "لا تقطع الصملة! 🔥"
        content.body = "شد حيلك و كمل هدفك اليوم"
        content.sound = .default
        
        // Schedule for 8 PM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleGoalCheckReminder() {
        let content = UNMutableNotificationContent()
        content.title = "فحص الهدف 📊"
        content.body = "مساء الخير، لا تنسى تكمل الهدف"
        content.sound = .default
        
        // Schedule for 6 PM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "goalCheck", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendGoalAchievementNotification() {
        guard goalAchievementEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "مبروك! 🎉"
        content.body = "لقد حققت هدفك اليومي من الخطوات!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "goalAchieved_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendChallengeCompletionNotification(_ challengeTitle: String) {
        guard challengeNotificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "تحدي مكتمل! 🏆"
        content.body = "رائع! لقد أكملت تحدي: \(challengeTitle)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "challengeCompleted_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendAchievementUnlockedNotification(_ achievementTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "إنجاز جديد! 🌟"
        content.body = "تهانينا! لقد حصلت على: \(achievementTitle)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendStreakMilestoneNotification(_ days: Int) {
        guard streakReminderEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "صملة تاريخية! 🔥"
        content.body = "واو! لقد وصلت إلى \(days) يوم متتالي!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func toggleDailyReminder(_ enabled: Bool) {
        dailyReminderEnabled = enabled
        saveSettings()
        scheduleNotifications()
    }
    
    func toggleGoalAchievement(_ enabled: Bool) {
        goalAchievementEnabled = enabled
        saveSettings()
    }
    
    func toggleStreakReminder(_ enabled: Bool) {
        streakReminderEnabled = enabled
        saveSettings()
        scheduleNotifications()
    }
    
    func toggleChallengeNotifications(_ enabled: Bool) {
        challengeNotificationsEnabled = enabled
        saveSettings()
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(dailyReminderEnabled, forKey: "dailyReminderEnabled")
        UserDefaults.standard.set(goalAchievementEnabled, forKey: "goalAchievementEnabled")
        UserDefaults.standard.set(streakReminderEnabled, forKey: "streakReminderEnabled")
        UserDefaults.standard.set(challengeNotificationsEnabled, forKey: "challengeNotificationsEnabled")
    }
    
    private func loadSettings() {
        dailyReminderEnabled = UserDefaults.standard.bool(forKey: "dailyReminderEnabled")
        goalAchievementEnabled = UserDefaults.standard.bool(forKey: "goalAchievementEnabled")
        streakReminderEnabled = UserDefaults.standard.bool(forKey: "streakReminderEnabled")
        challengeNotificationsEnabled = UserDefaults.standard.bool(forKey: "challengeNotificationsEnabled")
        
        // Set defaults if first time
        if !UserDefaults.standard.bool(forKey: "notificationSettingsInitialized") {
            dailyReminderEnabled = true
            goalAchievementEnabled = true
            streakReminderEnabled = true
            challengeNotificationsEnabled = true
            UserDefaults.standard.set(true, forKey: "notificationSettingsInitialized")
            saveSettings()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let identifier = response.notification.request.identifier
        
        // You can handle different notification types here
        if identifier.starts(with: "goalAchieved") {
            // Navigate to home or stats view
        } else if identifier.starts(with: "challengeCompleted") {
            // Navigate to challenges view
        } else if identifier.starts(with: "achievement") {
            // Navigate to achievements view
        }
        
        completionHandler()
    }
}

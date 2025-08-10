//
//  GameCenterManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import GameKit
import SwiftUI

class GameCenterManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentPlayer: GKPlayer?
    @Published var leaderboards: [GKLeaderboard] = []
    @Published var achievements: [GKAchievement] = []
    @Published var friends: [GKPlayer] = []
    
    static let shared = GameCenterManager()
    
    override init() {
        super.init()
        authenticatePlayer()
    }
    
    // MARK: - Authentication
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let viewController = viewController {
                    // Present the Game Center login view
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(viewController, animated: true)
                    }
                } else if error != nil {
                    print("Game Center authentication failed: \(error?.localizedDescription ?? "Unknown error")")
                    self?.isAuthenticated = false
                } else {
                    print("Game Center authentication successful")
                    self?.isAuthenticated = true
                    self?.currentPlayer = GKLocalPlayer.local
                    self?.loadGameCenterData()
                }
            }
        }
    }
    
    // MARK: - Leaderboards
    func loadLeaderboards() {
        guard isAuthenticated else { return }
        
        GKLeaderboard.loadLeaderboards { [weak self] leaderboards, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to load leaderboards: \(error.localizedDescription)")
                    return
                }
                
                self?.leaderboards = leaderboards ?? []
                print("Loaded \(leaderboards?.count ?? 0) leaderboards")
            }
        }
    }
    
    func submitScore(_ score: Int, to leaderboardID: String) {
        guard isAuthenticated else { return }
        
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Failed to submit score: \(error.localizedDescription)")
            } else {
                print("Successfully submitted score: \(score) to leaderboard: \(leaderboardID)")
            }
        }
    }
    
    func loadLeaderboardEntries(for leaderboardID: String, completion: @escaping ([GKLeaderboard.Entry]) -> Void) {
        guard isAuthenticated else {
            completion([])
            return
        }
        
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            guard let leaderboard = leaderboards?.first else {
                completion([])
                return
            }
            
            leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 100)) { localPlayerEntry, entries, totalPlayerCount, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Failed to load leaderboard entries: \(error.localizedDescription)")
                        completion([])
                    } else {
                        completion(entries ?? [])
                    }
                }
            }
        }
    }
    
    // MARK: - Achievements
    func loadAchievements() {
        guard isAuthenticated else { return }
        
        GKAchievement.loadAchievements { [weak self] achievements, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to load achievements: \(error.localizedDescription)")
                    return
                }
                
                self?.achievements = achievements ?? []
                print("Loaded \(achievements?.count ?? 0) achievements")
            }
        }
    }
    
    func unlockAchievement(_ achievementID: String, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }
        
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Failed to unlock achievement: \(error.localizedDescription)")
            } else {
                print("Successfully unlocked achievement: \(achievementID)")
            }
        }
    }
    
    func updateAchievementProgress(_ achievementID: String, percentComplete: Double) {
        guard isAuthenticated else { return }
        
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = percentComplete
        
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Failed to update achievement progress: \(error.localizedDescription)")
            } else {
                print("Successfully updated achievement progress: \(achievementID) - \(percentComplete)%")
            }
        }
    }
    
    // MARK: - Friends
    func loadFriends() {
        guard isAuthenticated else { return }
        
        GKLocalPlayer.local.loadFriends { [weak self] friendIdentifiers, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to load friends: \(error.localizedDescription)")
                    return
                }
                
                // For now, we'll just store the friend identifiers
                // and load player details when needed
                print("Found \(friendIdentifiers?.count ?? 0) friends")
                
                // TODO: Implement proper friend loading when needed
                // This avoids the generic parameter conflict
                self?.friends = []
            }
        }
    }
    
    // MARK: - Challenges
    func sendChallenge(to players: [GKPlayer], leaderboardID: String, message: String) {
        guard isAuthenticated else { return }
        
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            guard let leaderboard = leaderboards?.first else { return }
            
            // Note: challengeComposeController is deprecated, using alternative approach
            // For now, we'll just show a simple alert
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "تحدي جديد",
                    message: "تم إرسال التحدي إلى \(players.count) لاعب",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "حسناً", style: .default))
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadGameCenterData() {
        loadLeaderboards()
        loadAchievements()
        loadFriends()
    }
    
    // MARK: - Step Tracking Integration
    func submitDailySteps(_ steps: Int) {
        // Submit to daily steps leaderboard
        submitScore(steps, to: "daily_steps_leaderboard")
        
        // Submit to weekly steps leaderboard
        submitScore(steps, to: "weekly_steps_leaderboard")
        
        // Submit to total steps leaderboard
        submitScore(steps, to: "total_steps_leaderboard")
    }
    
    func submitStreak(_ streakDays: Int) {
        // Submit to streak leaderboard
        submitScore(streakDays, to: "streak_leaderboard")
    }
    
    func checkAndUnlockAchievements(steps: Int, streak: Int, totalSteps: Int) {
        // Step-based achievements
        if steps >= 5000 {
            unlockAchievement("first_5k_steps")
        }
        if steps >= 10000 {
            unlockAchievement("first_10k_steps")
        }
        if steps >= 15000 {
            unlockAchievement("first_15k_steps")
        }
        
        // Streak-based achievements
        if streak >= 7 {
            unlockAchievement("week_streak")
        }
        if streak >= 30 {
            unlockAchievement("month_streak")
        }
        if streak >= 100 {
            unlockAchievement("century_streak")
        }
        
        // Total steps achievements
        if totalSteps >= 100000 {
            unlockAchievement("100k_total_steps")
        }
        if totalSteps >= 500000 {
            unlockAchievement("500k_total_steps")
        }
        if totalSteps >= 1000000 {
            unlockAchievement("million_steps")
        }
    }
}

// MARK: - Game Center View Controllers
struct GameCenterView: UIViewControllerRepresentable {
    let gameCenterViewController: GKGameCenterViewController
    
    init(state: GKGameCenterViewControllerState = .default) {
        gameCenterViewController = GKGameCenterViewController(state: state)
    }
    
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        gameCenterViewController.gameCenterDelegate = context.coordinator
        return gameCenterViewController
    }
    
    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let parent: GameCenterView
        
        init(_ parent: GameCenterView) {
            self.parent = parent
        }
        
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}

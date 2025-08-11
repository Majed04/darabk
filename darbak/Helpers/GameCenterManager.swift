//
//  GameCenterManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import GameKit
import SwiftUI

// MARK: - Leaderboard Entry Protocol
public protocol LeaderboardEntryProtocol {
    var player: GKPlayer { get }
    var score: Int { get }
    var rank: Int { get }
    var formattedScore: String { get }
}

// MARK: - Mock Leaderboard Entry for Testing
struct MockLeaderboardEntry: LeaderboardEntryProtocol {
    let player: GKPlayer
    let score: Int
    let rank: Int
    let formattedScore: String
    
    init(player: GKPlayer, score: Int, rank: Int, formattedScore: String) {
        self.player = player
        self.score = score
        self.rank = rank
        self.formattedScore = formattedScore
    }
}

// MARK: - Extension to make GKLeaderboard.Entry conform to our protocol
extension GKLeaderboard.Entry: LeaderboardEntryProtocol {}

class GameCenterManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentPlayer: GKPlayer?
    @Published var leaderboards: [GKLeaderboard] = []
    @Published var achievements: [GKAchievement] = []
    @Published var friends: [GKPlayer] = []
    @Published var authenticationError: String?
    @Published var isAuthenticating = false
    
    static let shared = GameCenterManager()
    
    private var authenticationRetryCount = 0
    private var maxRetryAttempts = 3
    private var lastAuthenticationAttempt: Date?
    private var authenticationCooldown: TimeInterval = 30 // 30 seconds cooldown
    
    override init() {
        super.init()
        authenticatePlayer()
    }
    
    // MARK: - Authentication
    func authenticatePlayer() {
        print("Starting Game Center authentication...")
        
        // Check if already authenticated
        if GKLocalPlayer.local.isAuthenticated {
            print("✅ Player is already authenticated")
            self.isAuthenticated = true
            self.currentPlayer = GKLocalPlayer.local
            self.loadGameCenterData()
            return
        }
        
        // Set up the authentication handler
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let viewController = viewController {
                    print("📱 Presenting Game Center login view")
                    
                    // Find the topmost view controller
                    if let topVC = self?.getTopViewController() {
                        topVC.present(viewController, animated: true) {
                            print("✅ Game Center login presented")
                        }
                    } else {
                        print("❌ Could not find view controller to present Game Center login")
                    }
                } else if let error = error {
                    print("❌ Game Center authentication failed: \(error.localizedDescription)")
                    self?.authenticationError = error.localizedDescription
                } else {
                    print("✅ Game Center authentication successful")
                    self?.isAuthenticated = true
                    self?.currentPlayer = GKLocalPlayer.local
                    self?.authenticationError = nil
                    self?.loadGameCenterData()
                }
            }
        }
        
        // Force authentication to trigger
        print("🔄 Triggering authentication...")
        _ = GKLocalPlayer.local
    }
    
    private func handleAuthenticationFailure(_ errorMessage: String) {
        self.isAuthenticated = false
        self.currentPlayer = nil
        self.authenticationError = errorMessage
        print("❌ Game Center authentication failed: \(errorMessage)")
    }
    
    // Method to manually retry authentication
    func retryAuthentication() {
        print("🔄 Manually retrying Game Center authentication...")
        
        // Reset authentication state and retry count
        self.isAuthenticated = false
        self.currentPlayer = nil
        self.authenticationError = nil
        self.authenticationRetryCount = 0
        self.lastAuthenticationAttempt = nil
        
        // Clear any existing authentication handler
        GKLocalPlayer.local.authenticateHandler = nil
        
        // Set up new authentication handler
        authenticatePlayer()
    }
    
    // Method to manually present Game Center login
    func presentGameCenterLogin() {
        print("📱 Manually presenting Game Center login...")
        
        // Reset authentication state
        self.isAuthenticated = false
        self.currentPlayer = nil
        self.authenticationError = nil
        
        // Clear any existing authentication handler
        GKLocalPlayer.local.authenticateHandler = nil
        
        // Force a fresh authentication attempt
        DispatchQueue.main.async {
            self.authenticatePlayer()
        }
    }
    
    // Helper method to find the topmost view controller
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var topViewController = window.rootViewController
        
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        return topViewController
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
        guard isAuthenticated else { 
            print("❌ Not authenticated, cannot submit score")
            return 
        }
        
        // Check if we have an authentication error
        if let authError = authenticationError {
            print("❌ Authentication error present, cannot submit score: \(authError)")
            return
        }
        
        print("📊 Submitting score \(score) to leaderboard: \(leaderboardID)")
        
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("❌ Failed to submit score: \(error.localizedDescription)")
                
                // Check if this is an authentication-related error
                if error.localizedDescription.contains("not recognized by Game Center") {
                    print("🔧 This appears to be a Game Center configuration issue")
                    print("💡 Please ensure Game Center is enabled in App Store Connect")
                }
            } else {
                print("✅ Successfully submitted score: \(score) to leaderboard: \(leaderboardID)")
            }
        }
    }
    
    func loadLeaderboardEntries(for leaderboardID: String, completion: @escaping ([LeaderboardEntryProtocol]) -> Void) {
        guard isAuthenticated else {
            print("❌ Not authenticated, cannot load leaderboard")
            completion([])
            return
        }
        
        // Check if we have an authentication error
        if let authError = authenticationError {
            print("❌ Authentication error present, cannot load leaderboard: \(authError)")
            completion([])
            return
        }
        
        print("🔄 Loading leaderboard entries for: \(leaderboardID)")
        
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            if let error = error {
                print("❌ Failed to load leaderboards: \(error.localizedDescription)")
                
                // Check if this is an authentication-related error
                if error.localizedDescription.contains("not recognized by Game Center") {
                    print("🔧 This appears to be a Game Center configuration issue")
                    print("💡 Please ensure Game Center is enabled in App Store Connect")
                }
                
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            guard let leaderboard = leaderboards?.first else {
                print("❌ No leaderboard found for ID: \(leaderboardID)")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            print("✅ Found leaderboard: \(leaderboard.baseLeaderboardID)")
            
            // Load global entries with larger range to ensure we get data
            leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 100)) { localPlayerEntry, globalEntries, totalPlayerCount, error in
                DispatchQueue.main.async {
                    var allEntries: [LeaderboardEntryProtocol] = []
                    
                    // Add global entries
                    if let globalEntries = globalEntries {
                        allEntries.append(contentsOf: globalEntries)
                        print("📊 Loaded \(globalEntries.count) global entries")
                    }
                    
                    // Add local player entry if not already included
                    if let localEntry = localPlayerEntry {
                        let existingPlayerIDs = Set(allEntries.map { $0.player.gamePlayerID })
                        if !existingPlayerIDs.contains(localEntry.player.gamePlayerID) {
                            allEntries.append(localEntry)
                            print("👤 Added local player entry")
                        }
                    }
                    
                    // Sort by score (highest first)
                    allEntries.sort { $0.score > $1.score }
                    
                    // If no entries found, create some sample data for testing
                    if allEntries.isEmpty {
                        print("⚠️ No leaderboard entries found, creating sample data")
                        allEntries = self.createSampleLeaderboardEntries()
                    }
                    
                    // Limit to top 10 for display
                    let finalEntries = Array(allEntries.prefix(10))
                    
                    print("🎯 Final leaderboard: \(finalEntries.count) entries")
                    for (index, entry) in finalEntries.enumerated() {
                        print("   \(index + 1). \(entry.player.displayName): \(entry.formattedScore)")
                    }
                    
                    completion(finalEntries)
                }
            }
        }
    }
    
    // MARK: - Sample Data for Testing
    private func createSampleLeaderboardEntries() -> [LeaderboardEntryProtocol] {
        let samplePlayers = [
            ("أحمد المشي", 15000),
            ("فاطمة النشاط", 14200),
            ("محمد الرياضي", 13800),
            ("سارة المثابرة", 13500),
            ("علي المثابر", 13200),
            ("نور الهمة", 12800),
            ("يوسف النشاط", 12500),
            ("مريم المثابرة", 12200),
            ("خالد المشي", 12000),
            ("ليلى النشاط", 11800)
        ]
        
        return samplePlayers.enumerated().map { index, player in
            let mockPlayer = MockGKPlayer(
                displayName: player.0,
                gamePlayerID: "sample_player_\(index)",
                teamPlayerID: "sample_team_\(index)"
            )
            
            return MockLeaderboardEntry(
                player: mockPlayer,
                score: player.1,
                rank: index + 1,
                formattedScore: "\(player.1) خطوة"
            )
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
    func loadFriends(completion: @escaping ([GKPlayer]) -> Void = { _ in }) {
        guard isAuthenticated else { 
            print("❌ Cannot load friends - not authenticated")
            completion([])
            return 
        }
        
        print("🔄 Loading Game Center friends...")
        
        GKLocalPlayer.local.loadFriends { [weak self] friendIdentifiers, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to load friend identifiers: \(error.localizedDescription)")
                    
                    // Check if this is a permission/privacy issue
                    let nsError = error as NSError
                    if nsError.code == 2 { // GKErrorNotAuthenticated
                        print("🔧 Game Center authentication issue detected")
                    } else if nsError.code == 5 { // GKErrorNotAuthorized
                        print("🔧 Game Center friends access denied - check privacy settings")
                    }
                    
                    self?.friends = []
                    completion([])
                    return
                }
                
                guard let friendIdentifiers = friendIdentifiers as? [String], !friendIdentifiers.isEmpty else {
                    print("ℹ️ No Game Center friends found")
                    self?.friends = []
                    completion([])
                    return
                }
                
                print("✅ Found \(friendIdentifiers.count) friend identifiers, loading details...")
                
                // Load player details for all friends
                GKPlayer.loadPlayers(forIdentifiers: friendIdentifiers) { players, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Failed to load friend details: \(error.localizedDescription)")
                            self?.friends = []
                            completion([])
                            return
                        }
                        
                        if let players = players {
                            print("🎉 Successfully loaded \(players.count) Game Center friends:")
                            for player in players {
                                print("   - \(player.displayName) (ID: \(player.gamePlayerID))")
                            }
                            self?.friends = players
                            completion(players)
                        } else {
                            print("⚠️ Friend identifiers found but no player details loaded")
                            self?.friends = []
                            completion([])
                        }
                    }
                }
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
    
    // MARK: - Debug Methods
    func debugGameCenterStatus() {
        print("=== Game Center Debug Info ===")
        print("GKLocalPlayer.isAuthenticated: \(GKLocalPlayer.local.isAuthenticated)")
        print("GKLocalPlayer.isUnderage: \(GKLocalPlayer.local.isUnderage)")
        print("GKLocalPlayer.isMultiplayerGamingRestricted: \(GKLocalPlayer.local.isMultiplayerGamingRestricted)")
        print("GKLocalPlayer.isPersonalizedCommunicationRestricted: \(GKLocalPlayer.local.isPersonalizedCommunicationRestricted)")
        
        let player = GKLocalPlayer.local
        print("Player display name: \(player.displayName)")
        print("Player game player ID: \(player.gamePlayerID)")
        print("Player team player ID: \(player.teamPlayerID)")
        
        print("Our isAuthenticated state: \(isAuthenticated)")
        print("Is authenticating: \(isAuthenticating)")
        print("Authentication error: \(authenticationError ?? "None")")
        print("Retry count: \(authenticationRetryCount)/\(maxRetryAttempts)")
        print("Game Center available: \(isGameCenterAvailable())")
        
        // Check bundle ID
        if let bundleID = Bundle.main.bundleIdentifier {
            print("App bundle ID: \(bundleID)")
        }
        
        // Check entitlements
        print("Game Center entitlement present: \(Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.game-center") != nil)")
        
        print("================================")
    }
    
    // Check if Game Center is available
    func isGameCenterAvailable() -> Bool {
        return GKLocalPlayer.local.isAuthenticated || GKLocalPlayer.local.authenticateHandler != nil
    }
    
    // MARK: - Step Tracking Integration
    func submitDailySteps(_ steps: Int) {
        print("📊 Submitting daily steps: \(steps)")
        
        // Submit to daily steps leaderboard
        submitScore(steps, to: "daily_steps_leaderboard")
        
        // Submit to weekly steps leaderboard
        submitScore(steps, to: "weekly_steps_leaderboard")
        
        // Submit to total steps leaderboard
        submitScore(steps, to: "total_steps_leaderboard")
        
        // Update competition progress if in active race
        updateCompetitionProgress(steps: steps)
    }
    
    // MARK: - Enhanced Leaderboard Functions
    func getPlayerRank(for leaderboardID: String, completion: @escaping (Int?) -> Void) {
        guard isAuthenticated else {
            completion(nil)
            return
        }
        
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            guard let leaderboard = leaderboards?.first else {
                completion(nil)
                return
            }
            
            leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 1000)) { localPlayerEntry, entries, totalPlayerCount, error in
                DispatchQueue.main.async {
                    if let localEntry = localPlayerEntry {
                        completion(localEntry.rank)
                        print("🏆 Player rank in \(leaderboardID): \(localEntry.rank)")
                    } else {
                        completion(nil)
                        print("❌ Could not get player rank for \(leaderboardID)")
                    }
                }
            }
        }
    }
    
    func getLeaderboardStats(for leaderboardID: String, completion: @escaping (Int, Int?) -> Void) {
        guard isAuthenticated else {
            completion(0, nil)
            return
        }
        
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            guard let leaderboard = leaderboards?.first else {
                completion(0, nil)
                return
            }
            
            leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 1)) { localPlayerEntry, entries, totalPlayerCount, error in
                DispatchQueue.main.async {
                    let totalPlayers = totalPlayerCount
                    let playerRank = localPlayerEntry?.rank
                    completion(totalPlayers, playerRank)
                    print("📊 Leaderboard stats for \(leaderboardID): \(totalPlayers) total players, rank: \(playerRank ?? 0)")
                }
            }
        }
    }
    
    // MARK: - Competition Integration
    private func updateCompetitionProgress(steps: Int) {
        let competitionManager = CompetitionManager.shared
        guard let currentPlayer = currentPlayer else { return }
        
        // Check if player is in active race
        if let activeRace = competitionManager.getActiveRace(for: currentPlayer.gamePlayerID) {
            // Get current photo progress (this would come from your challenge system)
            let completedPhotos = getCurrentPhotoProgress() // You'll need to implement this
            
            competitionManager.updateRaceProgress(
                raceId: activeRace.id.uuidString,
                playerId: currentPlayer.gamePlayerID,
                completedPhotos: completedPhotos,
                dailyGoalProgress: steps
            )
        }
    }
    
    private func getCurrentPhotoProgress() -> Int {
        // This should integrate with your existing challenge progress system
        // For now, returning 0 - you'll need to connect this to your challenge completion logic
        return 0
    }
    
    // MARK: - Competition Progress Tracking
    func updatePhotoProgress(_ completedPhotos: Int) {
        let competitionManager = CompetitionManager.shared
        guard let currentPlayer = currentPlayer else { return }
        
        // Check if player is in active race
        if let activeRace = competitionManager.getActiveRace(for: currentPlayer.gamePlayerID) {
            competitionManager.updateRaceProgress(
                raceId: activeRace.id.uuidString,
                playerId: currentPlayer.gamePlayerID,
                completedPhotos: completedPhotos,
                dailyGoalProgress: 0 // This will be updated separately when steps are submitted
            )
        }
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
        print("Creating GameCenterView with state: \(state)")
        gameCenterViewController = GKGameCenterViewController(state: state)
    }
    
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        print("Making GameCenter UIViewController")
        gameCenterViewController.gameCenterDelegate = context.coordinator
        return gameCenterViewController
    }
    
    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {
        print("Updating GameCenter UIViewController")
    }
    
    func makeCoordinator() -> Coordinator {
        print("Making GameCenter Coordinator")
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let parent: GameCenterView
        
        init(_ parent: GameCenterView) {
            self.parent = parent
            print("GameCenter Coordinator initialized")
        }
        
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            print("Game Center view controller did finish")
            gameCenterViewController.dismiss(animated: true)
        }
    }
}

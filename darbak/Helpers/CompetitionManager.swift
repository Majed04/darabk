//
//  CompetitionManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import GameKit
import SwiftUI

// MARK: - Mock GKPlayer for Testing
class MockGKPlayer: GKPlayer {
    private let mockDisplayName: String
    private let mockGamePlayerID: String
    private let mockTeamPlayerID: String
    
    init(displayName: String, gamePlayerID: String, teamPlayerID: String) {
        self.mockDisplayName = displayName
        self.mockGamePlayerID = gamePlayerID
        self.mockTeamPlayerID = teamPlayerID
        super.init()
    }
    
    override var displayName: String {
        return mockDisplayName
    }
    
    override var gamePlayerID: String {
        return mockGamePlayerID
    }
    
    override var teamPlayerID: String {
        return mockTeamPlayerID
    }
}

class CompetitionManager: NSObject, ObservableObject {
    @Published var activeRaces: [PhotoChallengeRace] = []
    @Published var raceProgress: [String: RaceProgress] = [:] // raceId -> progress
    @Published var availablePlayers: [GKPlayer] = []
    
    static let shared = CompetitionManager()
    private let gameCenterManager = GameCenterManager.shared
    
    override init() {
        super.init()
        setupAppStateNotifications()
        loadAvailablePlayers()
        
        // Load saved races after a short delay to ensure Game Center is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadSavedRaces()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAppStateNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // Refresh friends list when app becomes active
        // This handles cases where user added friends while app was in background
        if gameCenterManager.isAuthenticated {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.forceRefreshFriends()
            }
        }
    }
    
    // MARK: - Player Management
    func loadAvailablePlayers() {
        guard gameCenterManager.isAuthenticated else { 
            // If not authenticated, clear players and show helpful message
            print("❌ Cannot load friends - Game Center not authenticated")
            DispatchQueue.main.async {
                self.availablePlayers = []
            }
            return 
        }
        
        print("🔄 Loading Game Center friends...")
        
        // Load friends using the Game Center manager
        gameCenterManager.loadFriends { [weak self] friends in
            DispatchQueue.main.async {
                if !friends.isEmpty {
                    // Use real Game Center friends
                    print("✅ Found \(friends.count) real Game Center friends")
                    self?.availablePlayers = friends
                } else {
                    // Check if this is due to privacy restrictions
                    print("ℹ️ No real friends found")
                    
                    // For development/testing, still provide fake friends
                    // In production, you might want to remove this
                    if self?.shouldUseFakeFriendsForTesting() == true {
                        print("⚠️ Using fake friends for testing purposes")
                        self?.availablePlayers = self?.createFakeFriends() ?? []
                    } else {
                        self?.availablePlayers = []
                    }
                }
            }
        }
    }
    
    private func shouldUseFakeFriendsForTesting() -> Bool {
        // Only use fake friends in debug builds or specific testing scenarios
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Fake Friends for Testing
    private func createFakeFriends() -> [GKPlayer] {
        return [
            MockGKPlayer(
                displayName: "أحمد التست",
                gamePlayerID: "fake_player_ahmed",
                teamPlayerID: "fake_team_ahmed"
            ),
            MockGKPlayer(
                displayName: "فاطمة الرياضية",
                gamePlayerID: "fake_player_fatima",
                teamPlayerID: "fake_team_fatima"
            ),
            MockGKPlayer(
                displayName: "محمد المشي",
                gamePlayerID: "fake_player_mohammed",
                teamPlayerID: "fake_team_mohammed"
            ),
            MockGKPlayer(
                displayName: "سارة النشاط",
                gamePlayerID: "fake_player_sara",
                teamPlayerID: "fake_team_sara"
            )
        ]
    }
    
    // MARK: - Race Creation
    func createPhotoChallengeRace(
        with player: GKPlayer,
        challenge: Challenge,
        dailyGoal: Int,
        duration: TimeInterval = 24 * 60 * 60 // 24 hours default
    ) -> PhotoChallengeRace? {
        guard gameCenterManager.isAuthenticated,
              let currentPlayer = gameCenterManager.currentPlayer else { return nil }
        
        let race = PhotoChallengeRace(
            challengeId: challenge.id,
            player1Id: currentPlayer.gamePlayerID,
            player2Id: player.gamePlayerID,
            player1Name: currentPlayer.displayName,
            player2Name: player.displayName,
            dailyGoal: dailyGoal,
            startDate: Date(),
            endDate: Date().addingTimeInterval(duration),
            status: .active,
            winnerId: nil
        )
        
        // Initialize progress for both players
        let player1Progress = RaceProgress(
            playerId: currentPlayer.gamePlayerID,
            playerName: currentPlayer.displayName,
            completedPhotos: 0,
            dailyGoalProgress: 0,
            lastUpdate: Date(),
            isCompleted: false
        )
        
        let player2Progress = RaceProgress(
            playerId: player.gamePlayerID,
            playerName: player.displayName,
            completedPhotos: 0,
            dailyGoalProgress: 0,
            lastUpdate: Date(),
            isCompleted: false
        )
        
        DispatchQueue.main.async {
            self.activeRaces.append(race)
            self.raceProgress[race.id.uuidString] = player1Progress
            self.raceProgress[race.id.uuidString + "_player2"] = player2Progress
            

            
            // Save the race to persistent storage
            self.saveRaces()
        }
        
        // Send challenge invitation via Game Center
        sendRaceInvitation(race: race, to: player)
        
        return race
    }
    
    // MARK: - Race Progress Updates
    func updateRaceProgress(
        raceId: String,
        playerId: String,
        completedPhotos: Int,
        dailyGoalProgress: Int
    ) {
        guard let currentProgress = raceProgress[raceId] else { return }
        
        let newProgress = RaceProgress(
            playerId: playerId,
            playerName: currentProgress.playerName,
            completedPhotos: completedPhotos,
            dailyGoalProgress: dailyGoalProgress,
            lastUpdate: Date(),
            isCompleted: completedPhotos >= 4 && dailyGoalProgress >= 10000 // Assuming 4 photos and 10k steps
        )
        
        DispatchQueue.main.async {
            self.raceProgress[raceId] = newProgress
            self.checkRaceCompletion(raceId: raceId)
            
            // Save updated progress
            self.saveRaces()
        }
    }
    
    private func checkRaceCompletion(raceId: String) {
        guard let race = activeRaces.first(where: { $0.id.uuidString == raceId }),
              let player1Progress = raceProgress[raceId],
              let player2Progress = raceProgress[raceId + "_player2"] else { return }
        
        // Check if either player has completed the race
        if player1Progress.isCompleted || player2Progress.isCompleted {
            let winnerId = player1Progress.isCompleted ? player1Progress.playerId : player2Progress.playerId
            let winnerName = player1Progress.isCompleted ? player1Progress.playerName : player2Progress.playerName
            
            // Update race status
            if let index = activeRaces.firstIndex(where: { $0.id.uuidString == raceId }) {
                activeRaces[index] = PhotoChallengeRace(
                    challengeId: race.challengeId,
                    player1Id: race.player1Id,
                    player2Id: race.player2Id,
                    player1Name: race.player1Name,
                    player2Name: race.player2Name,
                    dailyGoal: race.dailyGoal,
                    startDate: race.startDate,
                    endDate: race.endDate,
                    status: .completed,
                    winnerId: winnerId
                )
            }
            
            // Show completion notification
            showRaceCompletionNotification(winnerName: winnerName)
            
            // Submit to Game Center leaderboard
            gameCenterManager.submitScore(1, to: "photo_challenge_wins")
        }
    }
    
    // MARK: - Game Center Integration
    private func sendRaceInvitation(race: PhotoChallengeRace, to player: GKPlayer) {
        // Create a custom challenge message
        let challengeMessage = """
        🏁 تحدي جديد!
        
        \(race.player1Name) يتحداك في:
        📸 \(getChallengeName(for: race.challengeId))
        🎯 الهدف اليومي: \(race.dailyGoal) خطوة
        ⏰ المدة: 24 ساعة
        
        هل تقبل التحدي؟
        """
        
        // Store the race invitation for the invited player
        storeRaceInvitation(race: race, for: player)
        
        // Show confirmation to the sender
        showInvitationSentAlert(to: player.displayName)
    }
    
    private func storeRaceInvitation(race: PhotoChallengeRace, for player: GKPlayer) {
        // Store invitation in UserDefaults for the invited player
        let invitationKey = "race_invitation_\(player.gamePlayerID)"
        let invitationData = RaceInvitation(
            raceId: race.id.uuidString,
            challengeId: race.challengeId.uuidString,
            challengerName: race.player1Name,
            challengeName: getChallengeName(for: race.challengeId),
            dailyGoal: race.dailyGoal,
            sentDate: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(invitationData) {
            UserDefaults.standard.set(encoded, forKey: invitationKey)
        }
    }
    
    private func showInvitationSentAlert(to playerName: String) {
        DispatchQueue.main.async {
            // Check if there's already a presented view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Find the topmost presented view controller
                var topViewController = rootViewController
                while let presentedViewController = topViewController.presentedViewController {
                    topViewController = presentedViewController
                }
                
                // Only present if not already presenting
                if topViewController.presentedViewController == nil {
                    let alert = UIAlertController(
                        title: "تم إرسال التحدي",
                        message: "تم إرسال التحدي إلى \(playerName). سيتلقى إشعاراً عند فتح التطبيق.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "حسناً", style: .default))
                    topViewController.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Invitation Handling
    func checkForIncomingInvitations() -> [RaceInvitation] {
        guard let currentPlayer = gameCenterManager.currentPlayer else { return [] }
        
        let invitationKey = "race_invitation_\(currentPlayer.gamePlayerID)"
        guard let data = UserDefaults.standard.data(forKey: invitationKey),
              let invitation = try? JSONDecoder().decode(RaceInvitation.self, from: data) else {
            return []
        }
        
        // Clear the invitation after reading it
        UserDefaults.standard.removeObject(forKey: invitationKey)
        
        return [invitation]
    }
    
    func acceptInvitation(_ invitation: RaceInvitation) {
        guard let currentPlayer = gameCenterManager.currentPlayer,
              let challenge = ChallengesData.shared.challenges.first(where: { $0.id.uuidString == invitation.challengeId }) else {
            return
        }
        
        // Create the race with the current player as player2
        let race = PhotoChallengeRace(
            challengeId: challenge.id,
            player1Id: "", // We don't have the challenger's ID, but we can work around this
            player2Id: currentPlayer.gamePlayerID,
            player1Name: invitation.challengerName,
            player2Name: currentPlayer.displayName,
            dailyGoal: invitation.dailyGoal,
            startDate: Date(),
            endDate: Date().addingTimeInterval(24 * 60 * 60),
            status: .active,
            winnerId: nil
        )
        
        // Initialize progress for both players
        let player2Progress = RaceProgress(
            playerId: currentPlayer.gamePlayerID,
            playerName: currentPlayer.displayName,
            completedPhotos: 0,
            dailyGoalProgress: 0,
            lastUpdate: Date(),
            isCompleted: false
        )
        
        DispatchQueue.main.async {
            self.activeRaces.append(race)
            self.raceProgress[race.id.uuidString + "_player2"] = player2Progress
            
            // Save the race to persistent storage
            self.saveRaces()
        }
        
        showInvitationAcceptedAlert(challengerName: invitation.challengerName)
    }
    
    private func showInvitationAcceptedAlert(challengerName: String) {
        DispatchQueue.main.async {
            // Check if there's already a presented view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Find the topmost presented view controller
                var topViewController = rootViewController
                while let presentedViewController = topViewController.presentedViewController {
                    topViewController = presentedViewController
                }
                
                // Only present if not already presenting
                if topViewController.presentedViewController == nil {
                    let alert = UIAlertController(
                        title: "تم قبول التحدي!",
                        message: "أنت الآن في سباق مع \(challengerName). ابدأ بالتصوير والخطوات!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "حسناً", style: .default))
                    topViewController.present(alert, animated: true)
                }
            }
        }
    }
    
    private func getChallengeName(for challengeId: UUID) -> String {
        if let challenge = ChallengesData.shared.challenges.first(where: { $0.id == challengeId }) {
            return challenge.prompt
        }
        return "تحدي الصور"
    }
    
    // MARK: - UI Helpers
    private func showRaceCompletionNotification(winnerName: String) {
        DispatchQueue.main.async {
            // Check if there's already a presented view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Find the topmost presented view controller
                var topViewController = rootViewController
                while let presentedViewController = topViewController.presentedViewController {
                    topViewController = presentedViewController
                }
                
                // Only present if not already presenting
                if topViewController.presentedViewController == nil {
                    let alert = UIAlertController(
                        title: "🏆 انتهى السباق!",
                        message: "مبروك! \(winnerName) فاز بالسباق!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "حسناً", style: .default))
                    topViewController.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Race Management
    func getActiveRace(for playerId: String) -> PhotoChallengeRace? {
        return activeRaces.first { race in
            race.isActive && (race.player1Id == playerId || race.player2Id == playerId)
        }
    }
    
    func getRaceProgress(for raceId: String, playerId: String) -> RaceProgress? {
        if playerId == activeRaces.first(where: { $0.id.uuidString == raceId })?.player1Id {
            return raceProgress[raceId]
        } else {
            return raceProgress[raceId + "_player2"]
        }
    }
    
    func cancelRace(raceId: String) {
        if let index = activeRaces.firstIndex(where: { $0.id.uuidString == raceId }) {
            activeRaces[index] = PhotoChallengeRace(
                challengeId: activeRaces[index].challengeId,
                player1Id: activeRaces[index].player1Id,
                player2Id: activeRaces[index].player2Id,
                player1Name: activeRaces[index].player1Name,
                player2Name: activeRaces[index].player2Name,
                dailyGoal: activeRaces[index].dailyGoal,
                startDate: activeRaces[index].startDate,
                endDate: activeRaces[index].endDate,
                status: .cancelled,
                winnerId: nil
            )
            
            // Save updated races
            saveRaces()
        }
    }
    
    // MARK: - Persistence
    private func saveRaces() {
        let racesData = PersistedRacesData(
            races: activeRaces,
            progress: raceProgress
        )
        
        if let encoded = try? JSONEncoder().encode(racesData) {
            UserDefaults.standard.set(encoded, forKey: "saved_races")
            UserDefaults.standard.synchronize() // Force immediate save
        }
    }
    
    private func loadSavedRaces() {
        guard let data = UserDefaults.standard.data(forKey: "saved_races") else {
            return
        }
        
        do {
            let racesData = try JSONDecoder().decode(PersistedRacesData.self, from: data)
            
            // For now, let's load ALL races without filtering to see what's happening
            let allRaces = racesData.races
            
            DispatchQueue.main.async {
                // Load ALL races for now to debug
                self.activeRaces = allRaces
                self.raceProgress = racesData.progress
            }
        } catch {
            // Handle error silently
        }
    }
    
    func clearExpiredRaces() {
        let currentDate = Date()
        activeRaces = activeRaces.filter { race in
            race.endDate > currentDate && race.status == .active
        }
        saveRaces()
    }
    
    // MARK: - Public Methods for UI
    func refreshRaces() {
        loadSavedRaces()
    }
    
    func forceLoadRaces() {
        loadSavedRaces()
    }
    
    func forceRefreshFriends() {
        print("🔄 CompetitionManager: Force refreshing friends...")
        loadAvailablePlayers()
    }
    
    func getCurrentPlayerRaces() -> [PhotoChallengeRace] {
        guard let currentPlayer = gameCenterManager.currentPlayer else { 
            return [] 
        }
        
        let playerRaces = activeRaces.filter { race in
            let isPlayerInRace = race.player1Id == currentPlayer.gamePlayerID || race.player2Id == currentPlayer.gamePlayerID
            return isPlayerInRace
        }
        
        return playerRaces
    }
    

}

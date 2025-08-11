//
//  PhotoChallengeRaceView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI
import GameKit

struct PhotoChallengeRaceView: View {
    @StateObject private var competitionManager = CompetitionManager.shared
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @State private var selectedPlayer: GKPlayer?
    @State private var selectedChallenge: Challenge?
    @State private var dailyGoal: Int = 10000
    @State private var showingPlayerSelection = false
    @State private var showingChallengeSelection = false
    @State private var showingActiveRace = false
    @State private var activeRace: PhotoChallengeRace?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [DesignSystem.Colors.primary.opacity(0.1), DesignSystem.Colors.accent.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Check for incoming invitations and refresh races
                .onAppear {
                    // Add a small delay to prevent alert conflicts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        checkForIncomingInvitations()
                        competitionManager.refreshRaces()
                        
                        // Force reload of Game Center friends
                        refreshGameCenterFriends()
                    }
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "flag.filled.and.flag.crossed")
                                .font(.system(size: 60))
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Text("سباق تحدي الصور")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.primary)
                            
                            Text("تحدى صديقك في إكمال تحدي الصور والهدف اليومي")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Active Race Section
                        if let race = getCurrentActiveRace() {
                            ActiveRaceCard(race: race)
                                .padding(.horizontal)
                        }
                        
                        // Create New Race Section
                        VStack(spacing: 15) {
                            Text("إنشاء سباق جديد")
                                .font(.title2)
                                .bold()
                            
                            // Player Selection
                            Button(action: {
                                showingPlayerSelection = true
                            }) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                    Text(selectedPlayer?.displayName ?? "اختر اللاعب")
                                        .foregroundColor(selectedPlayer == nil ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.text)
                                    Spacer()
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                .padding()
                                .background(DesignSystem.Colors.secondaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                            
                            // Challenge Selection
                            Button(action: {
                                showingChallengeSelection = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(DesignSystem.Colors.success)
                                    Text(selectedChallenge?.prompt ?? "اختر التحدي")
                                        .foregroundColor(selectedChallenge == nil ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.text)
                                    Spacer()
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                .padding()
                                .background(DesignSystem.Colors.secondaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                            
                            // Daily Goal Slider
                            VStack(alignment: .leading, spacing: 10) {
                                Text("الهدف اليومي: \(dailyGoal) خطوة")
                                    .font(.headline)
                                
                                Slider(value: Binding(
                                    get: { Double(dailyGoal) },
                                    set: { dailyGoal = Int($0) }
                                ), in: 5000...20000, step: 500)
                                .accentColor(DesignSystem.Colors.primary)
                                
                                HStack {
                                    Text("5,000")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("20,000")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            // Start Race Button
                            Button(action: startRace) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("ابدأ السباق")
                                        .bold()
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canStartRace ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                            }
                            .disabled(!canStartRace)
                        }
                        .padding(.horizontal)
                        
                        // Available Players
                        if !competitionManager.availablePlayers.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("الأصدقاء المتاحون")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    // Show refresh button
                                    Button(action: refreshGameCenterFriends) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.accent)
                                    }
                                    
                                    // Show indicator for real vs fake friends
                                    if competitionManager.availablePlayers.contains(where: { $0.gamePlayerID.hasPrefix("fake_player") }) {
                                        Text("(وضع التست)")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.warning)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(DesignSystem.Colors.warning.opacity(0.2))
                                            .cornerRadius(6)
                                    } else {
                                        Text("(أصدقاء حقيقيون)")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.success)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(DesignSystem.Colors.success.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(competitionManager.availablePlayers, id: \.gamePlayerID) { player in
                                            PlayerCard(player: player) {
                                                selectedPlayer = player
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // No friends message
                        if competitionManager.availablePlayers.isEmpty && gameCenterManager.isAuthenticated {
                            VStack(spacing: 15) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("لا يوجد أصدقاء")
                                    .font(.title2)
                                    .bold()
                                
                                Text("أضف أصدقاء في Game Center للمنافسة معهم")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 15) {
                                    Button("تحديث") {
                                        refreshGameCenterFriends()
                                    }
                                    .foregroundColor(DesignSystem.Colors.accent)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(DesignSystem.Colors.accent.opacity(0.1))
                                    .cornerRadius(8)
                                    
                                    Button("فتح Game Center") {
                                        openGameCenter()
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(DesignSystem.Colors.secondaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("سباق التحدي")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingPlayerSelection) {
            PlayerSelectionView(selectedPlayer: $selectedPlayer)
        }
        .sheet(isPresented: $showingChallengeSelection) {
            ChallengeSelectionView(selectedChallenge: $selectedChallenge)
        }
        .sheet(isPresented: $showingActiveRace) {
            if let race = activeRace {
                ActiveRaceDetailView(race: race)
            }
        }
    }
    
    private var canStartRace: Bool {
        return selectedPlayer != nil && selectedChallenge != nil && gameCenterManager.isAuthenticated
    }
    
    private func startRace() {
        guard let player = selectedPlayer,
              let challenge = selectedChallenge else { return }
        
        if let race = competitionManager.createPhotoChallengeRace(
            with: player,
            challenge: challenge,
            dailyGoal: dailyGoal
        ) {
            activeRace = race
            showingActiveRace = true
            
            // Reset selection
            selectedPlayer = nil
            selectedChallenge = nil
            dailyGoal = 10000
        }
    }
    
    private func getCurrentActiveRace() -> PhotoChallengeRace? {
        let currentRaces = competitionManager.getCurrentPlayerRaces()
        return currentRaces.first
    }
    
    private func checkForIncomingInvitations() {
        let invitations = competitionManager.checkForIncomingInvitations()
        
        if let invitation = invitations.first {
            showInvitationAlert(invitation: invitation)
        }
    }
    
    private func showInvitationAlert(invitation: RaceInvitation) {
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
                    title: "🏁 تحدي جديد!",
                    message: """
                    \(invitation.challengerName) يتحداك في:
                    
                    📸 \(invitation.challengeName)
                    🎯 الهدف اليومي: \(invitation.dailyGoal) خطوة
                    ⏰ المدة: 24 ساعة
                    
                    هل تقبل التحدي؟
                    """,
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "قبول", style: .default) { _ in
                    competitionManager.acceptInvitation(invitation)
                })
                
                alert.addAction(UIAlertAction(title: "رفض", style: .cancel))
                
                topViewController.present(alert, animated: true)
            }
        }
    }
    
    private func refreshGameCenterFriends() {
        #if DEBUG
        print("🔄 Manually refreshing Game Center friends...")
        #endif
        competitionManager.forceRefreshFriends()
    }
    
    private func openGameCenter() {
        if let url = URL(string: "gamecenter://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views
struct PlayerCard: View {
    let player: GKPlayer
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text(player.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct ActiveRaceCard: View {
    let race: PhotoChallengeRace
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "flag.filled.and.flag.crossed")
                    .foregroundColor(DesignSystem.Colors.accent)
                Text("سباق نشط")
                    .font(.headline)
                    .bold()
                Spacer()
                Text(formatTimeRemaining(race.timeRemaining))
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(race.player1Name)
                        .font(.subheadline)
                        .bold()
                    Text("اللاعب الأول")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("VS")
                    .font(.title2)
                    .bold()
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(race.player2Name)
                        .font(.subheadline)
                        .bold()
                    Text("اللاعب الثاني")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("الهدف: \(race.dailyGoal) خطوة")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding()
        .cardStyle()
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

struct PlayerSelectionView: View {
    @Binding var selectedPlayer: GKPlayer?
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var competitionManager = CompetitionManager.shared
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("جاري تحميل الأصدقاء...")
                            .font(.headline)
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if competitionManager.availablePlayers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("لا يوجد أصدقاء")
                            .font(.title2)
                            .bold()
                        
                        Text("أضف أصدقاء في Game Center للمنافسة معهم")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 15) {
                            Button("تحديث") {
                                loadFriends()
                            }
                            .foregroundColor(DesignSystem.Colors.accent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(DesignSystem.Colors.accent.opacity(0.1))
                            .cornerRadius(8)
                            
                            Button("فتح Game Center") {
                                openGameCenter()
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(competitionManager.availablePlayers, id: \.gamePlayerID) { player in
                        Button(action: {
                            selectedPlayer = player
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(player.displayName)
                                            .font(.headline)
                                        
                                        // Show test indicator for fake friends
                                        if player.gamePlayerID.hasPrefix("fake_player") {
                                            Text("(تست)")
                                                .font(.caption2)
                                                .foregroundColor(DesignSystem.Colors.warning)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(DesignSystem.Colors.warning.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text("متاح للمنافسة")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedPlayer?.gamePlayerID == player.gamePlayerID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("اختر اللاعب")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إلغاء") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                loadFriends()
            }
        }
    }
    
    private func loadFriends() {
        isLoading = true
        #if DEBUG
        print("🔄 PlayerSelectionView: Loading friends...")
        #endif
        
        // Force reload Game Center friends first
        GameCenterManager.shared.loadFriends { friends in
            DispatchQueue.main.async {
                #if DEBUG
                print("✅ PlayerSelectionView: Received \(friends.count) friends from Game Center")
                #endif
                
                // Then update the competition manager
                competitionManager.loadAvailablePlayers()
                
                // Stop loading after a brief delay to ensure UI updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                }
            }
        }
    }
    
    private func openGameCenter() {
        if let url = URL(string: "gamecenter://") {
            UIApplication.shared.open(url)
        }
    }
}

struct ChallengeSelectionView: View {
    @Binding var selectedChallenge: Challenge?
    @Environment(\.presentationMode) private var presentationMode
    private let challenges = ChallengesData.shared.challenges
    
    var body: some View {
        NavigationView {
            List(challenges, id: \.id) { challenge in
                Button(action: {
                    selectedChallenge = challenge
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(challenge.imageName)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            Text(challenge.prompt)
                                .font(.headline)
                            Text("\(challenge.totalPhotos) صور")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedChallenge?.id == challenge.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("اختر التحدي")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إلغاء") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ActiveRaceDetailView: View {
    let race: PhotoChallengeRace
    @StateObject private var competitionManager = CompetitionManager.shared
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Race Info
                    VStack(spacing: 15) {
                        Text("🏁 سباق نشط")
                            .font(.title)
                            .bold()
                        
                        HStack {
                            VStack {
                                Text(race.player1Name)
                                    .font(.headline)
                                Text("اللاعب الأول")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("VS")
                                .font(.title)
                                .bold()
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Spacer()
                            
                            VStack {
                                Text(race.player2Name)
                                    .font(.headline)
                                Text("اللاعب الثاني")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Progress Section
                    if let player1Progress = competitionManager.getRaceProgress(for: race.id.uuidString, playerId: race.player1Id),
                       let player2Progress = competitionManager.getRaceProgress(for: race.id.uuidString, playerId: race.player2Id) {
                        
                        VStack(spacing: 15) {
                            Text("التقدم")
                                .font(.title2)
                                .bold()
                            
                            // Player 1 Progress
                            ProgressCard(
                                playerName: player1Progress.playerName,
                                completedPhotos: player1Progress.completedPhotos,
                                dailyGoalProgress: player1Progress.dailyGoalProgress,
                                isCompleted: player1Progress.isCompleted
                            )
                            
                            // Player 2 Progress
                            ProgressCard(
                                playerName: player2Progress.playerName,
                                completedPhotos: player2Progress.completedPhotos,
                                dailyGoalProgress: player2Progress.dailyGoalProgress,
                                isCompleted: player2Progress.isCompleted
                            )
                        }
                    }
                    
                    // Time Remaining
                    VStack(spacing: 10) {
                        Text("الوقت المتبقي")
                            .font(.headline)
                        
                        Text(formatTimeRemaining(race.timeRemaining))
                            .font(.title)
                            .bold()
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    .padding()
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .padding()
            }
            .navigationTitle("تفاصيل السباق")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إغلاق") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

struct ProgressCard: View {
    let playerName: String
    let completedPhotos: Int
    let dailyGoalProgress: Int
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(playerName)
                    .font(.headline)
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.success)
                }
            }
            
            // Photo Progress
            VStack(alignment: .leading, spacing: 5) {
                Text("الصور المكتملة: \(completedPhotos)/4")
                    .font(.subheadline)
                
                ProgressView(value: Double(completedPhotos), total: 4)
                    .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
            }
            
            // Daily Goal Progress
            VStack(alignment: .leading, spacing: 5) {
                Text("الهدف اليومي: \(dailyGoalProgress)/10,000")
                    .font(.subheadline)
                
                ProgressView(value: Double(dailyGoalProgress), total: 10000)
                    .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.success))
            }
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    PhotoChallengeRaceView()
}



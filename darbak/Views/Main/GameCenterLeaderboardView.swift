//
//  GameCenterLeaderboardView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI
import GameKit



struct GameCenterLeaderboardView: View {
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @State private var selectedLeaderboard: String = "daily_steps_leaderboard"
    @State private var leaderboardEntries: [LeaderboardEntryProtocol] = []
    @State private var isLoading = false
    @State private var showingGameCenter = false
    @State private var playerRank: Int?
    @State private var totalPlayers: Int = 0
    @State private var showingStats = false
    
    private let leaderboards = [
        ("daily_steps_leaderboard", "خطوات اليوم", "figure.walk"),
        ("weekly_steps_leaderboard", "خطوات الأسبوع", "calendar"),
        ("total_steps_leaderboard", "إجمالي الخطوات", "infinity"),
        ("streak_leaderboard", "أطول سلسلة", "flame.fill")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("المتصدرين")
                    .font(DesignSystem.Typography.largeTitle)
                    .primaryText()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 15) {
                    Button(action: {
                        showingStats = true
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    Button(action: {
                        showingGameCenter = true
                    }) {
                        Image(systemName: "gamecontroller.fill")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            if !gameCenterManager.isAuthenticated {
                // Not authenticated
                VStack(spacing: 20) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text("تسجيل الدخول إلى Game Center")
                        .font(DesignSystem.Typography.title2)
                        .primaryText()
                    
                    Text("سجل دخولك إلى Game Center لرؤية المتصدرين والتنافس مع أصدقائك")
                        .font(DesignSystem.Typography.body)
                        .secondaryText()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        gameCenterManager.authenticatePlayer()
                    }) {
                        Text("تسجيل الدخول")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.invertedText)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                }
                .padding(.top, 60)
            } else {
                // Authenticated - show leaderboards
                VStack(spacing: 20) {
                    // Leaderboard Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(leaderboards, id: \.0) { leaderboard in
                                LeaderboardTabButton(
                                    title: leaderboard.1,
                                    icon: leaderboard.2,
                                    isSelected: selectedLeaderboard == leaderboard.0
                                ) {
                                    selectedLeaderboard = leaderboard.0
                                    loadLeaderboardData()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Leaderboard Content
                    if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("جاري التحميل...")
                                .font(DesignSystem.Typography.body)
                                .secondaryText()
                                .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    } else if leaderboardEntries.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "trophy")
                                .font(.system(size: 50))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            Text("جاري تحميل المتصدرين...")
                                .font(DesignSystem.Typography.title2)
                                .secondaryText()
                            
                            Text("إذا لم تظهر البيانات، تأكد من أن لديك اتصال بالإنترنت وأن Game Center يعمل بشكل صحيح")
                                .font(DesignSystem.Typography.body)
                                .secondaryText()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Button("إعادة المحاولة") {
                                loadLeaderboardData()
                            }
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.invertedText)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    } else {
                        // Player Rank Card (only show if not in top 10)
                        if let playerRank = playerRank, playerRank > 10 {
                            PlayerRankCard(
                                rank: playerRank,
                                totalPlayers: totalPlayers,
                                leaderboardName: getLeaderboardDisplayName(for: selectedLeaderboard)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Leaderboard Entries
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(leaderboardEntries.enumerated()), id: \.element.player.gamePlayerID) { index, entry in
                                    LeaderboardEntryRow(
                                        entry: entry,
                                        rank: index + 1,
                                        isCurrentUser: entry.player.gamePlayerID == gameCenterManager.currentPlayer?.gamePlayerID
                                    )
                                }
                                
                                // Show "Your Ranking" section if you're in top 10
                                if let playerRank = playerRank, playerRank <= 10 {
                                    YourRankingSection(
                                        rank: playerRank,
                                        totalPlayers: totalPlayers,
                                        leaderboardName: getLeaderboardDisplayName(for: selectedLeaderboard)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(DesignSystem.Colors.background)
        .sheet(isPresented: $showingGameCenter) {
            GameCenterView()
        }
        .sheet(isPresented: $showingStats) {
            LeaderboardStatsView(
                leaderboardID: selectedLeaderboard,
                leaderboardName: getLeaderboardDisplayName(for: selectedLeaderboard)
            )
        }
        .onAppear {
            if gameCenterManager.isAuthenticated {
                loadLeaderboardData()
            }
        }
        .onChange(of: gameCenterManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                loadLeaderboardData()
            }
        }
    }
    
    private func loadLeaderboardData() {
        isLoading = true
        
        // Load leaderboard entries
        gameCenterManager.loadLeaderboardEntries(for: selectedLeaderboard) { entries in
            DispatchQueue.main.async {
                self.leaderboardEntries = entries
                self.isLoading = false
            }
        }
        
        // Load player rank and stats
        gameCenterManager.getLeaderboardStats(for: selectedLeaderboard) { totalPlayers, rank in
            DispatchQueue.main.async {
                self.totalPlayers = totalPlayers
                self.playerRank = rank
            }
        }
    }
    
    private func getLeaderboardDisplayName(for id: String) -> String {
        switch id {
        case "daily_steps_leaderboard": return "خطوات اليوم"
        case "weekly_steps_leaderboard": return "خطوات الأسبوع"
        case "total_steps_leaderboard": return "إجمالي الخطوات"
        case "streak_leaderboard": return "أطول سلسلة"
        default: return "المتصدرين"
        }
    }
}

struct LeaderboardTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.caption)
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.invertedText : DesignSystem.Colors.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? DesignSystem.Colors.primary : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                    )
            )
        }
    }
}

struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntryProtocol
    let rank: Int
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.white)
                    .bold()
            }
            
            // Player Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.player.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(isCurrentUser ? DesignSystem.Colors.primary : DesignSystem.Colors.text)
                    
                    if isCurrentUser {
                        Text("(أنت)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                
                Text("\(entry.formattedScore)")
                    .font(DesignSystem.Typography.subheadline)
                    .secondaryText()
            }
            
            Spacer()
            
            // Trophy icon for top 3
            if rank <= 3 {
                Image(systemName: trophyIcon)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(trophyColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(isCurrentUser ? DesignSystem.Colors.primaryLight.opacity(0.1) : DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .stroke(isCurrentUser ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return DesignSystem.Colors.primary
        }
    }
    
    private var trophyIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "trophy.fill"
        default: return ""
        }
    }
    
    private var trophyColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .clear
        }
    }
}

#Preview {
    GameCenterLeaderboardView()
}

// MARK: - Player Rank Card
struct PlayerRankCard: View {
    let rank: Int
    let totalPlayers: Int
    let leaderboardName: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Text("رتبتك في \(leaderboardName)")
                    .font(DesignSystem.Typography.headline)
                    .primaryText()
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("الرتبة")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    
                    Text("\(rank)")
                        .font(DesignSystem.Typography.largeTitle)
                        .bold()
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("من إجمالي")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    
                    Text("\(totalPlayers)")
                        .font(DesignSystem.Typography.title2)
                        .bold()
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            // Progress bar
            ProgressView(value: Double(totalPlayers - rank + 1), total: Double(totalPlayers))
                .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
        }
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Leaderboard Stats View
struct LeaderboardStatsView: View {
    let leaderboardID: String
    let leaderboardName: String
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @State private var stats: [String: Any] = [:]
    @State private var isLoading = true
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("جاري تحميل الإحصائيات...")
                            .font(DesignSystem.Typography.body)
                            .secondaryText()
                            .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Top Players Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("أفضل اللاعبين")
                                    .font(DesignSystem.Typography.title2)
                                    .bold()
                                    .primaryText()
                                
                                ForEach(Array(stats["topPlayers"] as? [String] ?? []).enumerated(), id: \.offset) { index, player in
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(DesignSystem.Typography.headline)
                                            .foregroundColor(rankColor(for: index + 1))
                                            .frame(width: 30)
                                        
                                        Text(player)
                                            .font(DesignSystem.Typography.body)
                                            .primaryText()
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .cardStyle()
                            
                            // Statistics Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("إحصائيات \(leaderboardName)")
                                    .font(DesignSystem.Typography.title2)
                                    .bold()
                                    .primaryText()
                                
                                StatRow(title: "إجمالي اللاعبين", value: "\(stats["totalPlayers"] as? Int ?? 0)")
                                StatRow(title: "متوسط النقاط", value: "\(stats["averageScore"] as? Int ?? 0)")
                                StatRow(title: "أعلى نقاط", value: "\(stats["highestScore"] as? Int ?? 0)")
                                StatRow(title: "أدنى نقاط", value: "\(stats["lowestScore"] as? Int ?? 0)")
                            }
                            .padding()
                            .cardStyle()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("إحصائيات \(leaderboardName)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إغلاق") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        gameCenterManager.loadLeaderboardEntries(for: leaderboardID) { entries in
            DispatchQueue.main.async {
                let scores = entries.map { $0.score }
                let playerNames = entries.map { $0.player.displayName }
                
                self.stats = [
                    "totalPlayers": entries.count,
                    "averageScore": scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count,
                    "highestScore": scores.max() ?? 0,
                    "lowestScore": scores.min() ?? 0,
                    "topPlayers": Array(playerNames.prefix(10))
                ]
                
                self.isLoading = false
            }
        }
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return DesignSystem.Colors.primary
        }
    }
}

// MARK: - Your Ranking Section
struct YourRankingSection: View {
    let rank: Int
    let totalPlayers: Int
    let leaderboardName: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.accent)
                
                Text("رتبتك في \(leaderboardName)")
                    .font(DesignSystem.Typography.headline)
                    .primaryText()
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("الرتبة")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    
                    Text("\(rank)")
                        .font(DesignSystem.Typography.largeTitle)
                        .bold()
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("من إجمالي")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    
                    Text("\(totalPlayers)")
                        .font(DesignSystem.Typography.title2)
                        .bold()
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            // Progress bar
            ProgressView(value: Double(totalPlayers - rank + 1), total: Double(totalPlayers))
                .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
        }
        .padding(16)
        .cardStyle()
        .padding(.top, 20)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.body)
                .secondaryText()
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.headline)
                .primaryText()
        }
        .padding(.vertical, 4)
    }
}

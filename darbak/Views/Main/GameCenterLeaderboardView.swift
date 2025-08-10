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
    @State private var leaderboardEntries: [GKLeaderboard.Entry] = []
    @State private var isLoading = false
    @State private var showingGameCenter = false
    
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
                
                Button(action: {
                    showingGameCenter = true
                }) {
                    Image(systemName: "gamecontroller.fill")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.primary)
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
                            
                            Text("لا توجد بيانات بعد")
                                .font(DesignSystem.Typography.title2)
                                .secondaryText()
                            
                            Text("ابدأ بالمشي لترى اسمك في المتصدرين!")
                                .font(DesignSystem.Typography.body)
                                .secondaryText()
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 60)
                    } else {
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
        gameCenterManager.loadLeaderboardEntries(for: selectedLeaderboard) { entries in
            DispatchQueue.main.async {
                self.leaderboardEntries = entries
                self.isLoading = false
            }
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
    let entry: GKLeaderboard.Entry
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

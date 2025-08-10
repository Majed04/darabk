//
//  LeaderboardView.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI

struct LeaderboardUser: Identifiable {
    let id = UUID()
    let name: String
    let steps: Int
    let streak: Int
    let rank: Int
    let isCurrentUser: Bool
    let profileImage: String?
}

struct LeaderboardView: View {
    @EnvironmentObject var user: User
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedPeriod: LeaderboardPeriod = .weekly
    @State private var leaderboardUsers: [LeaderboardUser] = []
    @State private var currentUserRank: Int = 0
    @State private var showingFriendRequests = false
    
    enum LeaderboardPeriod: String, CaseIterable {
        case daily = "اليوم"
        case weekly = "هذا الأسبوع"
        case monthly = "هذا الشهر"
        case allTime = "كل الأوقات"
    }
    
    private let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 15) {
                    HStack {
                        Text("المتصدرين")
                            .font(DesignSystem.Typography.largeTitle)
                            .primaryText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            showingFriendRequests = true
                        }) {
                            Image(systemName: "person.badge.plus")
                                .font(DesignSystem.Typography.title2)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Period Selector
                    HStack(spacing: 0) {
                        ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                            Button(action: {
                                selectedPeriod = period
                                loadLeaderboardData()
                            }) {
                                Text(period.rawValue)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(selectedPeriod == period ? DesignSystem.Colors.invertedText : DesignSystem.Colors.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                            .fill(selectedPeriod == period ? DesignSystem.Colors.primary : Color.clear)
                                    )
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                }
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                // Leaderboard Content
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Top 3 Podium
                        if leaderboardUsers.count >= 3 {
                            PodiumView(users: Array(leaderboardUsers.prefix(3)))
                                .padding(.top, 20)
                                .padding(.horizontal, 20)
                        }
                        
                        // Rest of the leaderboard
                        ForEach(Array(leaderboardUsers.dropFirst(3).enumerated()), id: \.element.id) { index, leaderUser in
                            LeaderboardRowView(
                                user: leaderUser,
                                rank: index + 4
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Current user position if not in top visible
                        if currentUserRank > 10 {
                            VStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                
                                LeaderboardRowView(
                                    user: LeaderboardUser(
                                        name: user.name.isEmpty ? "أنت" : user.name,
                                        steps: healthKitManager.currentSteps,
                                        streak: 0, // Would get from streak manager
                                        rank: currentUserRank,
                                        isCurrentUser: true,
                                        profileImage: nil
                                    ),
                                    rank: currentUserRank
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFriendRequests) {
            FriendRequestsView()
        }
        .onAppear {
            loadLeaderboardData()
        }
    }
    
    private func loadLeaderboardData() {
        // This would typically fetch from a server
        // For now, we'll create mock data
        leaderboardUsers = generateMockLeaderboardData()
        
        // Find current user rank
        if let userIndex = leaderboardUsers.firstIndex(where: { $0.isCurrentUser }) {
            currentUserRank = userIndex + 1
        } else {
            currentUserRank = leaderboardUsers.count + 1
        }
    }
    
    private func generateMockLeaderboardData() -> [LeaderboardUser] {
        let mockUsers = [
            ("أحمد محمد", 15420, 25),
            ("فاطمة علي", 14850, 23),
            ("محمد سعد", 14200, 20),
            ("نورا حسن", 13800, 18),
            ("عبدالله أحمد", 13500, 22),
            ("مريم خالد", 13200, 15),
            ("سارة محمد", 12900, 17),
            ("علي حسن", 12600, 19),
            ("رنا عبدالله", 12300, 14),
            ("خالد سعد", 12000, 16)
        ]
        
        var users: [LeaderboardUser] = []
        
        for (index, (name, steps, streak)) in mockUsers.enumerated() {
            users.append(LeaderboardUser(
                name: name,
                steps: steps,
                streak: streak,
                rank: index + 1,
                isCurrentUser: false,
                profileImage: nil
            ))
        }
        
        // Add current user
        users.append(LeaderboardUser(
            name: user.name.isEmpty ? "أنت" : user.name,
            steps: healthKitManager.currentSteps,
            streak: 0, // Would get from streak manager
            rank: users.count + 1,
            isCurrentUser: true,
            profileImage: nil
        ))
        
        // Sort by steps (descending)
        users.sort { $0.steps > $1.steps }
        
        // Update ranks
        for i in 0..<users.count {
            users[i] = LeaderboardUser(
                name: users[i].name,
                steps: users[i].steps,
                streak: users[i].streak,
                rank: i + 1,
                isCurrentUser: users[i].isCurrentUser,
                profileImage: users[i].profileImage
            )
        }
        
        return users
    }
}

struct PodiumView: View {
    let users: [LeaderboardUser]
    
    private let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 15) {
            // Second place
            if users.count > 1 {
                PodiumUserView(
                    user: users[1],
                    rank: 2,
                    height: 80,
                    color: Color.gray
                )
            }
            
            // First place
            PodiumUserView(
                user: users[0],
                rank: 1,
                height: 100,
                color: Color.yellow
            )
            
            // Third place
            if users.count > 2 {
                PodiumUserView(
                    user: users[2],
                    rank: 3,
                    height: 60,
                    color: Color.orange
                )
            }
        }
        .padding(.bottom, 20)
    }
}

struct PodiumUserView: View {
    let user: LeaderboardUser
    let rank: Int
    let height: CGFloat
    let color: Color
    
    private let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    if rank == 1 {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .offset(y: -25)
                    }
                }
                
                Text(user.name)
                    .font(.caption)
                    .bold()
                    .lineLimit(1)
                
                Text(englishFormatter.string(from: NSNumber(value: user.steps)) ?? "\(user.steps)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Podium
            RoundedRectangle(cornerRadius: 8)
                .fill(color.gradient)
                .frame(width: 60, height: height)
                .overlay(
                    Text("\(rank)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                )
        }
    }
}

struct LeaderboardRowView: View {
    let user: LeaderboardUser
    let rank: Int
    
    private let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .bold()
                .foregroundColor(user.isCurrentUser ? Color(hex: "#1B5299") : .primary)
                .frame(width: 30)
            
            // Profile
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.headline)
                    .bold()
                    .foregroundColor(user.isCurrentUser ? Color(hex: "#1B5299") : .primary)
                
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("\(user.streak) يوم")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Steps
            VStack(alignment: .trailing, spacing: 2) {
                Text(englishFormatter.string(from: NSNumber(value: user.steps)) ?? "\(user.steps)")
                    .font(.headline)
                    .bold()
                    .foregroundColor(user.isCurrentUser ? Color(hex: "#1B5299") : .primary)
                
                Text("خطوة")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(user.isCurrentUser ? Color(hex: "#1B5299").opacity(0.1) : Color(.systemGray6))
        )
    }
}

struct FriendRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("طلبات الأصدقاء")
                    .font(.title2)
                    .bold()
                    .padding()
                
                Text("هذه الميزة ستكون متوفرة قريباً")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إغلاق") { dismiss() })
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(User())
        .environmentObject(HealthKitManager())
}

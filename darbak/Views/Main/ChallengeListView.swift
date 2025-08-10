//
//  ChallengeListView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI

struct ChallengeListView: View {
    @EnvironmentObject var challengeProgress: ChallengeProgress
    @EnvironmentObject var achievementManager: AchievementManager
    @State private var selectedChallenge: Challenge?
    @State private var showingChallengeDetail = false
    @State private var completedChallenges: Set<String> = []
    @State private var dailyChallenge: Challenge?
    
    private let challenges = ChallengesData.shared.challenges
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("التحديات")
                            .font(DesignSystem.Typography.largeTitle)
                            .primaryText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Daily Challenge Section
                    if let dailyChallenge = dailyChallenge {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("تحدي اليوم")
                                .font(DesignSystem.Typography.title2)
                                .accentText()
                                .padding(.horizontal, 20)
                            
                            DailyChallengeCard(
                                challenge: dailyChallenge,
                                isCompleted: completedChallenges.contains(dailyChallenge.prompt),
                                onTap: {
                                    selectedChallenge = dailyChallenge
                                    showingChallengeDetail = true
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // All Challenges Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("جميع التحديات")
                            .font(DesignSystem.Typography.title2)
                            .accentText()
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                            ForEach(challenges) { challenge in
                                ChallengeCard(
                                    challenge: challenge,
                                    isCompleted: completedChallenges.contains(challenge.prompt),
                                    isDailyChallenge: challenge.id == dailyChallenge?.id,
                                    onTap: {
                                        selectedChallenge = challenge
                                        showingChallengeDetail = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationDestination(isPresented: $showingChallengeDetail) {
            if let selectedChallenge = selectedChallenge {
                ChallengePage(selectedChallenge: selectedChallenge)
                    .environmentObject(challengeProgress)
            }
        }
        .onAppear {
            loadChallengeData()
            setDailyChallenge()
        }
    }
    
    private func loadChallengeData() {
        // Load completed challenges from UserDefaults
        if let saved = UserDefaults.standard.array(forKey: "completedChallenges") as? [String] {
            completedChallenges = Set(saved)
        }
    }
    
    private func setDailyChallenge() {
        // Set daily challenge based on current date
        let today = Calendar.current.startOfDay(for: Date())
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: today) ?? 1
        let challengeIndex = dayOfYear % challenges.count
        dailyChallenge = challenges[challengeIndex]
    }
    
    private func markChallengeCompleted(_ challenge: Challenge) {
        completedChallenges.insert(challenge.prompt)
        let array = Array(completedChallenges)
        UserDefaults.standard.set(array, forKey: "completedChallenges")
        
        // Update achievement manager
        achievementManager.incrementCompletedChallenges()
    }
}

struct DailyChallengeCard: View {
    let challenge: Challenge
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("⭐")
                            .font(.title2)
                        Text("تحدي اليوم")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    
                    Text(challenge.fullTitle)
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.invertedText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("صور: \(challenge.totalPhotos)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.invertedText.opacity(0.8))
                        
                        Spacer()
                        
                        if isCompleted {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("مكتمل")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.success)
                            }
                        } else {
                            Text("ابدأ الآن")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.invertedText)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(DesignSystem.Colors.invertedText.opacity(0.2))
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.trailing, 90)
                
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                LinearGradient(
                    colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primary.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.large)
            .overlay(
                Image("Star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .offset(x: 15, y: -40)
                    .zIndex(1)
                , alignment: .topTrailing
            )
        }
    }
}

struct ChallengeCard: View {
    let challenge: Challenge
    let isCompleted: Bool
    let isDailyChallenge: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Challenge Image/Icon
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(DesignSystem.Colors.primaryLight)
                        .frame(height: 100)
                    
                    if !challenge.imageName.isEmpty {
                        Image(challenge.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(DesignSystem.Typography.title)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    // Daily challenge badge
                    if isDailyChallenge {
                        VStack {
                            HStack {
                                Spacer()
                                Text("⭐")
                                    .font(DesignSystem.Typography.caption)
                                    .padding(4)
                                    .background(DesignSystem.Colors.accent)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                    
                    // Completion badge
                    if isCompleted {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(DesignSystem.Typography.title2)
                                    .foregroundColor(DesignSystem.Colors.success)
                                    .background(DesignSystem.Colors.background)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(8)
                    }
                }
                
                // Challenge Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.prompt)
                        .font(DesignSystem.Typography.headline)
                        .primaryText()
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text("\(challenge.totalPhotos) صور مطلوبة")
                        .font(DesignSystem.Typography.caption)
                        .secondaryText()
                    
                    // Emojis
                    HStack {
                        ForEach(challenge.emojis.prefix(3), id: \.self) { emoji in
                            Text(emoji)
                                .font(DesignSystem.Typography.caption)
                        }
                        if challenge.emojis.count > 3 {
                            Text("...")
                                .font(DesignSystem.Typography.caption)
                                .secondaryText()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .cardStyle()
            .scaleEffect(isCompleted ? 0.95 : 1.0)
            .opacity(isCompleted ? 0.7 : 1.0)
        }
        .disabled(isCompleted)
    }
}

#Preview {
    ChallengeListView()
        .environmentObject(ChallengeProgress())
        .environmentObject(AchievementManager())
}

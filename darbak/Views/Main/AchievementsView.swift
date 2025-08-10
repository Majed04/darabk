//
//  AchievementsView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var achievementManager: AchievementManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: AchievementCategory = .all
    @StateObject private var socialManager = SocialManager()
    
    enum AchievementCategory: String, CaseIterable {
        case all = "الكل"
        case unlocked = "مفتوح"
        case inProgress = "قيد التقدم"
        case locked = "مقفل"
    }
    
    var filteredAchievements: [Achievement] {
        switch selectedCategory {
        case .all:
            return achievementManager.achievements
        case .unlocked:
            return achievementManager.getUnlockedAchievements()
        case .inProgress:
            return achievementManager.getInProgressAchievements()
        case .locked:
            return achievementManager.getLockedAchievements()
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Stats
                VStack(spacing: 15) {
                    HStack {
                        StatCard(
                            value: achievementManager.getUnlockedAchievements().count,
                            total: achievementManager.achievements.count,
                            title: "الإنجازات المفتوحة",
                            color: .green
                        )
                        
                        StatCard(
                            value: achievementManager.badges.count,
                            total: nil,
                            title: "الشارات المكتسبة",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Category Filter
                    HStack(spacing: 0) {
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category.rawValue)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(selectedCategory == category ? DesignSystem.Colors.invertedText : DesignSystem.Colors.primary)
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                    .padding(.vertical, DesignSystem.Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                            .fill(selectedCategory == category ? DesignSystem.Colors.primary : Color.clear)
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
                .padding(.vertical, 15)
                .background(Color(.systemGray6))
                
                // Achievements List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                onShare: achievement.isUnlocked ? {
                                    socialManager.shareAchievement(achievement)
                                } : nil
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        if filteredAchievements.isEmpty {
                            EmptyStateView(category: selectedCategory)
                                .padding(.top, 50)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("الإنجازات")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إغلاق") { dismiss() })
        }
        .shareSheet(isPresented: $socialManager.showingShareSheet, items: [socialManager.shareText])
        .alert("إنجاز جديد!", isPresented: $achievementManager.showingAchievementAlert) {
            Button("رائع!") { }
        } message: {
            if let achievement = achievementManager.latestAchievement {
                Text("مبروك! لقد حصلت على: \(achievement.title)")
            }
        }
    }
}

struct StatCard: View {
    let value: Int
    let total: Int?
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(value)")
                    .font(.title)
                    .bold()
                    .foregroundColor(color)
                
                if let total = total {
                    Text("/\(total)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let onShare: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? DesignSystem.Colors.primary : DesignSystem.Colors.border)
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.icon)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(achievement.isUnlocked ? DesignSystem.Colors.invertedText : .gray)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(achievement.isUnlocked ? DesignSystem.Colors.text : DesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    HStack {
                        if achievement.isUnlocked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            if let onShare = onShare {
                                Button(action: onShare) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        } else if achievement.progress > 0 {
                            Text("\(Int(achievement.progress * 100))%")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                
                Text(achievement.description)
                    .font(DesignSystem.Typography.caption)
                    .secondaryText()
                    .lineLimit(2)
                
                // Progress bar for in-progress achievements
                if !achievement.isUnlocked && achievement.progress > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: achievement.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                            .scaleEffect(y: 0.5)
                        
                        Text("\(achievement.currentValue) / \(achievement.targetValue)")
                            .font(DesignSystem.Typography.caption2)
                            .secondaryText()
                    }
                }
                
                // Unlock date for completed achievements
                if achievement.isUnlocked, let unlockedDate = achievement.unlockedDate {
                    Text("تم فتحه في \(unlockedDate, style: .date)")
                        .font(DesignSystem.Typography.caption2)
                        .secondaryText()
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

struct EmptyStateView: View {
    let category: AchievementsView.AchievementCategory
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(emptyStateTitle)
                .font(.headline)
                .bold()
                .foregroundColor(.secondary)
            
            Text(emptyStateMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
    
    private var emptyStateIcon: String {
        switch category {
        case .all:
            return "trophy"
        case .unlocked:
            return "checkmark.circle"
        case .inProgress:
            return "clock"
        case .locked:
            return "lock"
        }
    }
    
    private var emptyStateTitle: String {
        switch category {
        case .all:
            return "لا توجد إنجازات"
        case .unlocked:
            return "لا توجد إنجازات مفتوحة"
        case .inProgress:
            return "لا توجد إنجازات قيد التقدم"
        case .locked:
            return "جميع الإنجازات مفتوحة!"
        }
    }
    
    private var emptyStateMessage: String {
        switch category {
        case .all:
            return "ابدأ في المشي لفتح إنجازاتك الأولى"
        case .unlocked:
            return "ابدأ في إنجاز أهدافك لفتح الإنجازات"
        case .inProgress:
            return "واصل التقدم لفتح إنجازات جديدة"
        case .locked:
            return "مبروك! لقد فتحت جميع الإنجازات المتاحة"
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AchievementManager())
}

//
//  AchievementsView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI

// Collect each item's horizontal center (midX) inside the carousel
private struct ItemCenterPrefKey: PreferenceKey {
    static var defaultValue: [UUID: CGFloat] = [:]
    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct AchievementsView: View {
    @EnvironmentObject var achievementManager: AchievementManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingBadgeDetail = false
    @State private var selectedBadge: Achievement?

    // Holds the latest measured centers for all visible items (for snapping)
    @State private var itemCenters: [UUID: CGFloat] = [:]

    // Picks 6 most recent unlocked badges; falls back to empty array for testing
    var recentBadges: [Achievement] {
        let unlocked = achievementManager.getUnlockedAchievements()
        print("🔍 Unlocked achievements count: \(unlocked.count)")
        print("🔍 All achievements count: \(achievementManager.achievements.count)")
        
        if !unlocked.isEmpty {
            let recent = Array(
                unlocked
                    .sorted { ($0.unlockedDate ?? .distantPast) > ($1.unlockedDate ?? .distantPast) }
            )
            print("🔍 Recent badges count: \(recent.count)")
            return recent
        } else {
            print("🔍 No unlocked achievements, showing empty state")
            return [] // Return empty array to show empty state
        }
    }
    

    var body: some View {
        NavigationView {
            ScrollView {
                // Tightened global vertical spacing to reduce blank space overall
                VStack(spacing: 30) {

                    // MARK: Unlocked count section
                    VStack(spacing: 6) {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("/ \(achievementManager.achievements.count)")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.text)

                            Text("\(achievementManager.getUnlockedAchievements().count)")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        // Use English locale to keep numbers LTR if desired
                        .environment(\.locale, Locale(identifier: "en"))

                        Text("الإنجازات المفتوحة")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 12) // smaller top padding

                    // MARK: Recent badges (H-carousel with dynamic center scaling + snapping)
                    VStack(spacing: 10) { // tighter spacing inside this section
                        HStack {
                            Text("أحدث الشارات")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.text)
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        if !recentBadges.isEmpty {
                            GeometryReader { outer in
                                let containerWidth = outer.size.width

                                // Tighter layout: smaller spacing & slightly smaller item width
                                let itemWidth: CGFloat = 116
                                let itemSpacing: CGFloat = 12
                                let sidePadding = (containerWidth - itemWidth) / 2

                                // ScrollViewReader lets us snap to the nearest item smoothly
                                ScrollViewReader { proxy in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: itemSpacing) {
                                            ForEach(Array(recentBadges.enumerated()), id: \.element.id) { _, badge in
                                                DynamicBadgeCard(
                                                    badge: badge,
                                                    containerWidth: containerWidth
                                                ) {
                                                    selectedBadge = badge
                                                    showingBadgeDetail = true
                                                }
                                                // Fixed width keeps geometry math consistent
                                                .frame(width: itemWidth)
                                                // Stable ID for scrollTo snapping
                                                .id(badge.id)
                                            }
                                        }
                                        .padding(.horizontal, sidePadding) // center first & last items
                                        // Receive all items' centers for snapping
                                        .onPreferenceChange(ItemCenterPrefKey.self) { centers in
                                            self.itemCenters = centers
                                        }
                                    }
                                    .coordinateSpace(name: "carousel")
                                }
                            }
                            // ↓↓↓ Smaller fixed height eliminates the big blank space below the carousel
                            .frame(height: 140)
                        } else {
                            // Empty state message
                            VStack(spacing: 16) {
                                Image(systemName: "trophy")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(DesignSystem.Colors.primary.opacity(0.6))
                                
                                Text("كمل وحدة من الانجازات وراح تشوفها هنا")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(height: 140)
                        }
                    }

                    // MARK: All achievements list
                    VStack(spacing: 12) { // tighter spacing here too
                        HStack {
                            Text("جميع الانجازات")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.text)
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        LazyVStack(spacing: 10) {
                            ForEach(achievementManager.achievements) { achievement in
                                AchievementProgressCard(achievement: achievement)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Smaller spacer at the bottom so the scroll content ends closer
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("الإنجازات")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إغلاق") { dismiss() })
        }
        .sheet(isPresented: $showingBadgeDetail) {
            if let badge = selectedBadge {
                BadgeDetailView(badge: badge)
            }
        }
    }


}

// MARK: - Achievement Image Helper
struct AchievementImageView: View {
    let achievement: Achievement
    let size: CGFloat
    let color: Color
    
    var body: some View {
        if let imageName = achievement.imageName {
            // Use custom image if available
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(color)
        } else {
            // Fallback to SF Symbol icon
            Image(systemName: achievement.icon)
                .font(.system(size: size * 0.7, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// MARK: - Dynamic Badge Card
/// Simple badge card to prevent crashes
struct DynamicBadgeCard: View {
    let badge: Achievement
    let containerWidth: CGFloat
    let onTap: () -> Void

    @State private var isVisible = false

    var body: some View {
        GeometryReader { proxy in
            // Item center X relative to the named coordinate space
            let midX = proxy.frame(in: .named("carousel")).midX
            // Horizontal center of the outer container
            let center = containerWidth / 2

            // Distance from screen center (0 at center, increases toward edges)
            let distance = abs(midX - center)

            // Subtle sizing:
            // - narrower scale range
            // - smaller falloff per distance
            let maxScale: CGFloat = 1.0
            let minScale: CGFloat = 0.86
            let normalized = min(distance / center, 1)
            let scale = max(minScale, maxScale - normalized * 0.25)

            // Also narrow max/min circle size so the “pulsing” is gentler
            let maxBadge: CGFloat = 96
            let minBadge: CGFloat = 72
            let badgeSize = minBadge + (maxBadge - minBadge) * ((scale - minScale) / (maxScale - minScale))

            Button(action: onTap) {
                VStack(spacing: 6) {
//                                         if let imageName = badge.imageName {
//                         Image(imageName)
//                             .resizable()
//                             .aspectRatio(contentMode: .fill)
//                             .frame(width: badgeSize, height: badgeSize)
//                             .clipShape(Circle())
//                             .foregroundColor(DesignSystem.Colors.primary)
//                     } else {
//                         Image(systemName: badge.icon)
//                             .font(.system(size: badgeSize * 0.4, weight: .medium))
//                             .foregroundColor(DesignSystem.Colors.primary)
//                     }
                                         // Only show images, no icons
                     if let imageName = badge.imageName, !imageName.isEmpty {
                         Image(imageName)
                             .resizable()
                             .aspectRatio(contentMode: .fill)
                             .frame(width: badgeSize, height: badgeSize)
                             .clipShape(Circle())
                             .foregroundColor(DesignSystem.Colors.primary)
                             .onAppear {
                                 print("🖼️ Loading image: \(imageName)")
                             }
                     } else {
                         // Fallback to a default image if no image is available
                         Circle()
                             .fill(DesignSystem.Colors.primary.opacity(0.3))
                             .frame(width: badgeSize, height: badgeSize)
                             .onAppear {
                                 print("🔵 Showing fallback circle")
                             }
                     }
                   

                    VStack(spacing: 2) {
                        Text(badge.title)
                            .font(.system(size: badgeSize * 0.18, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: badgeSize * 0.5) // More height for 2 lines

                        if let unlockedDate = badge.unlockedDate {
                            Text(timeAgoString(from: unlockedDate))
                                .font(.system(size: badgeSize * 0.15, weight: .regular))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    .frame(height: badgeSize * 0.7) // More total height for text container
                }
                // Main scaling effect based on horizontal position
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.12), value: scale)
                // Arrival animation
                .scaleEffect(isVisible ? 1.0 : 0.92)
                .animation(.easeOut(duration: 0.22), value: isVisible)
            }
            .buttonStyle(.plain)
            .onAppear { isVisible = true }
            // Emit this item's measured midX so the parent can snap to it
            .preference(key: ItemCenterPrefKey.self, value: [badge.id: midX])
        }
        // Give the GeometryReader a fixed height
        .frame(height: 170) // a bit shorter as part of the vertical tightening
    }

    // Relative date helpers in Arabic
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "منذ \(minutes) دقيقة"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "منذ \(hours) ساعة"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "منذ \(days) يوم"
        } else if timeInterval < 2592000 {
            let weeks = Int(timeInterval / 604800)
            return "منذ \(weeks) أسبوع"
        } else {
            let months = Int(timeInterval / 2592000)
            return "منذ \(months) شهر"
        }
    }
}

// MARK: - Achievement Progress Card (unchanged)
struct AchievementProgressCard: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 16) {
            // Circular Progress Indicator
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: achievement.isUnlocked ? 1.0 : achievement.progress)
                    .stroke(DesignSystem.Colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: achievement.progress)

                if achievement.isUnlocked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primary)
                } else {
                    // Always show percentage for progress bars
                    Text("\(Int(achievement.progress * 100), specifier: "%d")%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }

            // Achievement Info
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.text)

                Text(achievement.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            if !achievement.isUnlocked {
                Text("\(achievement.currentValue) / \(achievement.targetValue)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .environment(\.locale, Locale(identifier: "en"))
    }
}

// MARK: - Badge Detail (unchanged)
struct BadgeDetailView: View {
    let badge: Achievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                                 // Badge Icon
//                 if let imageName = badge.imageName {
//                     Image(imageName)
//                         .resizable()
//                         .aspectRatio(contentMode: .fill)
//                         .frame(width: 180, height: 180)
//                         .clipShape(Circle())
//                         .foregroundColor(DesignSystem.Colors.primary)
//                 } else {
//                     Image(systemName: badge.icon)
//                         .font(.system(size: 72, weight: .medium))
//                         .foregroundColor(DesignSystem.Colors.primary)
//                 }
                                 // Only show images, no icons
                 if let imageName = badge.imageName, !imageName.isEmpty {
                     Image(imageName)
                         .resizable()
                         .aspectRatio(contentMode: .fill)
                         .frame(width: 180, height: 180)
                         .clipShape(Circle())
                         .foregroundColor(DesignSystem.Colors.primary)
                 } else {
                     // Fallback to a default circle if no image is available
                     Circle()
                         .fill(DesignSystem.Colors.primary.opacity(0.3))
                         .frame(width: 180, height: 180)
                 }
             //  .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)

                // Congratulations Text
                VStack(spacing: 12) {
                    Text("🎉 مبروك!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.text)

                    Text("تم فتح الإنجاز!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }

                // Badge Details
                VStack(spacing: 16) {
                    Text(badge.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.text)
                        .multilineTextAlignment(.center)

                    Text(badge.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    if let unlockedDate = badge.unlockedDate {
                        VStack(spacing: 4) {
                            Text("تم الفتح في")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            Text(unlockedDate, style: .date)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.text)
                        }
                        .padding(.top, 8)
                    }
                }

                Spacer()

                Button("إغلاق") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .navigationTitle("تفاصيل الإنجاز")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("تم") { dismiss() })
        }
    }
}

// MARK: - Preview
#Preview {
    AchievementsView()
        .environmentObject(AchievementManager())
}

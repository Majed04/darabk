//
//  SocialManager.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation
import SwiftUI

struct SocialPost {
    let id = UUID()
    let type: PostType
    let content: String
    let date: Date
    let achievementId: String?
    let challengeId: String?
    
    enum PostType {
        case achievement
        case challenge
        case milestone
        case personalBest
    }
}

class SocialManager: ObservableObject {
    @Published var posts: [SocialPost] = []
    @Published var shareText: String = ""
    @Published var showingShareSheet = false
    
    func shareAchievement(_ achievement: Achievement) {
        let text = "🏆 لقد حصلت على إنجاز جديد في دربك: \(achievement.title)! \n\n#دربك #تحدي_المشي #إنجاز"
        shareContent(text)
        
        // Create social post
        let post = SocialPost(
            type: .achievement,
            content: "\(achievement.title) - \(achievement.description)",
            date: Date(),
            achievementId: achievement.title,
            challengeId: nil
        )
        posts.insert(post, at: 0)
        savePosts()
    }
    
    func shareChallenge(_ challenge: Challenge) {
        let text = "🎯 لقد أكملت تحدي جديد في دربك: \(challenge.prompt)! \n\nهل تريد أن تتحداني؟ \n\n#دربك #تحدي_المشي #نشاط"
        shareContent(text)
        
        // Create social post
        let post = SocialPost(
            type: .challenge,
            content: "أكملت تحدي: \(challenge.prompt)",
            date: Date(),
            achievementId: nil,
            challengeId: challenge.prompt
        )
        posts.insert(post, at: 0)
        savePosts()
    }
    
    func shareStreak(_ days: Int) {
        let text = "🔥 لقد وصلت إلى سلسلة \(days) يوم في دربك! \n\nالمثابرة هي المفتاح للنجاح 💪 \n\n#دربك #سلسلة_المشي #مثابرة"
        shareContent(text)
        
        // Create social post
        let post = SocialPost(
            type: .milestone,
            content: "سلسلة \(days) يوم من المشي!",
            date: Date(),
            achievementId: nil,
            challengeId: nil
        )
        posts.insert(post, at: 0)
        savePosts()
    }
    
    func sharePersonalBest(_ steps: Int) {
        let text = "🚀 رقم قياسي جديد في دربك: \(steps) خطوة في يوم واحد! \n\nلا حدود للطموح 🌟 \n\n#دربك #رقم_قياسي #تحدي_الذات"
        shareContent(text)
        
        // Create social post
        let post = SocialPost(
            type: .personalBest,
            content: "رقم قياسي جديد: \(steps) خطوة!",
            date: Date(),
            achievementId: nil,
            challengeId: nil
        )
        posts.insert(post, at: 0)
        savePosts()
    }
    
    private func shareContent(_ text: String) {
        shareText = text
        showingShareSheet = true
    }
    
    func getShareableText(for achievement: Achievement) -> String {
        return "🏆 لقد حصلت على إنجاز جديد في دربك: \(achievement.title)! \n\n\(achievement.description) \n\n#دربك #تحدي_المشي #إنجاز"
    }
    
    func getShareableText(for challenge: Challenge) -> String {
        return "🎯 لقد أكملت تحدي جديد في دربك: \(challenge.prompt)! \n\nصور \(challenge.totalPhotos) من \(challenge.prompt) خلال تحقيق هدف المشي اليومي \n\nهل تريد أن تتحداني؟ \n\n#دربك #تحدي_المشي #نشاط"
    }
    
    func challengeFriend(with challenge: Challenge) -> String {
        return "👋 أتحداك في تطبيق دربك! \n\n🎯 التحدي: \(challenge.prompt) \n📸 عدد الصور: \(challenge.totalPhotos) \n🚶‍♂️ أثناء تحقيق هدف المشي اليومي \n\nهل تقبل التحدي؟ حمل التطبيق واكتشف المزيد! \n\n#دربك #تحدي_الأصدقاء"
    }
    
    private func savePosts() {
        // In a real app, you'd save to a database or cloud storage
        // For now, we'll just keep them in memory
    }
    
    func loadPosts() {
        // In a real app, you'd load from a database or cloud storage
        // For now, we'll start with empty posts
        posts = []
    }
}

// Helper for sharing functionality
extension View {
    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        self.sheet(isPresented: isPresented) {
            ShareSheet(items: items)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

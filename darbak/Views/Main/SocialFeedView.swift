//
//  SocialFeedView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI

struct SocialFeedView: View {
    @StateObject private var socialManager = SocialManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if socialManager.posts.isEmpty {
                    EmptyFeedView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(socialManager.posts, id: \.id) { post in
                                SocialPostCard(post: post)
                                    .padding(.horizontal, 20)
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("المشاركات")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إغلاق") { dismiss() })
        }
        .onAppear {
            socialManager.loadPosts()
        }
        .shareSheet(isPresented: $socialManager.showingShareSheet, items: [socialManager.shareText])
    }
}

struct SocialPostCard: View {
    let post: SocialPost
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ar")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: postIcon)
                    .font(.title2)
                    .foregroundColor(postColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(postTitle)
                        .font(.headline)
                        .bold()
                    
                    Text(dateFormatter.string(from: post.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // Share post
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(Color(hex: "#1B5299"))
                }
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            // Actions
            HStack(spacing: 20) {
                Button(action: {
                    // Like action
                }) {
                    HStack {
                        Image(systemName: "heart")
                        Text("إعجاب")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Button(action: {
                    // Comment action
                }) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("تعليق")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(15)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var postIcon: String {
        switch post.type {
        case .achievement:
            return "trophy.fill"
        case .challenge:
            return "target"
        case .milestone:
            return "flame.fill"
        case .personalBest:
            return "crown.fill"
        }
    }
    
    private var postColor: Color {
        switch post.type {
        case .achievement:
            return .orange
        case .challenge:
            return Color(hex: "#1B5299")
        case .milestone:
            return .red
        case .personalBest:
            return .yellow
        }
    }
    
    private var postTitle: String {
        switch post.type {
        case .achievement:
            return "إنجاز جديد"
        case .challenge:
            return "تحدي مكتمل"
        case .milestone:
            return "إنجاز مميز"
        case .personalBest:
            return "رقم قياسي"
        }
    }
}

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("لا توجد مشاركات")
                .font(.title2)
                .bold()
                .foregroundColor(.secondary)
            
            Text("أكمل إنجازاتك وتحدياتك لمشاركتها مع الأصدقاء")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    SocialFeedView()
}

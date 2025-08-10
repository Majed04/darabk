//
//  ChallengeHistoryView.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import SwiftUI

struct ChallengeHistoryView: View {
    @EnvironmentObject var challengeProgress: ChallengeProgress
    @Environment(\.dismiss) private var dismiss
    
    @State private var challengeHistory: [(challenge: Challenge, completedDate: Date)] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 15) {
                    if challengeHistory.isEmpty {
                        EmptyHistoryView()
                            .padding(.top, 100)
                    } else {
                        ForEach(Array(challengeHistory.enumerated()), id: \.offset) { index, item in
                            ChallengeHistoryCard(
                                challenge: item.challenge,
                                completedDate: item.completedDate,
                                rank: index + 1
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
            .navigationTitle("تاريخ التحديات")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("إغلاق") { dismiss() })
        }
        .onAppear {
            loadChallengeHistory()
        }
    }
    
    private func loadChallengeHistory() {
        challengeHistory = challengeProgress.getChallengeHistory()
    }
}

struct ChallengeHistoryCard: View {
    let challenge: Challenge
    let completedDate: Date
    let rank: Int
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ar")
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 15) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("#\(rank)")
                    .font(.headline)
                    .bold()
                    .foregroundColor(rankColor)
            }
            
            // Challenge Image
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#1B5299").opacity(0.1))
                    .frame(width: 60, height: 60)
                
                if !challenge.imageName.isEmpty {
                    Image(challenge.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "#1B5299"))
                }
            }
            
            // Challenge Info
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.prompt)
                    .font(.headline)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text("\(challenge.totalPhotos) صور")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("مكتمل في: \(dateFormatter.string(from: completedDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Completion Badge
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding(15)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .orange
        default:
            return Color(hex: "#1B5299")
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("لا توجد تحديات مكتملة")
                .font(.title2)
                .bold()
                .foregroundColor(.secondary)
            
            Text("أكمل أول تحدي لك لتراه هنا")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    ChallengeHistoryView()
        .environmentObject(ChallengeProgress())
}

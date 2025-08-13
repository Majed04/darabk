//
//  Challenge.swift
//  darbak
//
//  Created by Majed on 05/02/1447 AH.
//

import SwiftUI

struct ChallengePage: View {
    @State private var currentIndex = 0
    @State private var showingTheChallengeView = false
    @EnvironmentObject var challengeProgress: ChallengeProgress
    
    private let challenges = ChallengesData.shared.challenges
    let selectedChallenge: Challenge?
    
    var onBack: (() -> Void)? = nil
    @Environment(\.presentationMode) private var presentationMode
    
    init(selectedChallenge: Challenge? = nil, onBack: (() -> Void)? = nil) {
        self.selectedChallenge = selectedChallenge
        self.onBack = onBack
        
        // Set initial index based on selected challenge
        if let selectedChallenge = selectedChallenge,
           let index = ChallengesData.shared.challenges.firstIndex(where: { $0.id == selectedChallenge.id }) {
            _currentIndex = State(initialValue: index)
        } else {
            _currentIndex = State(initialValue: 0)
        }
    }
    
    private func createEmojiBackground() -> some View {
        GeometryReader { geometry in
            ForEach(0..<19, id: \.self) { index in
                let column = index % 3
                let row = index / 3
                let xOffset = CGFloat(column) * (geometry.size.width / 2.5) + 60
                let yOffset = CGFloat(row) * (geometry.size.height / 8) + 120
                
                Text(challenges[currentIndex].emojis[index % challenges[currentIndex].emojis.count])
                    .font(.system(size: 60))
                    .opacity(0.06)
                    .rotationEffect(.degrees(Double.random(in: -15...15)))
                    .position(
                        x: xOffset + CGFloat.random(in: -20...20),
                        y: yOffset + CGFloat.random(in: -15...15)
                    )
            }
        }
        .allowsHitTesting(false)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                createEmojiBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("تحدي اليوم")
                            .font(DesignSystem.Typography.largeTitle)
                            .primaryText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Challenge Card
                    VStack(spacing: 12) {
                        // Challenge Image
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 320)
                            .overlay(
                                Image(challenges[currentIndex].imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(15)
                            )
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                        
                        // Challenge Description
                        VStack(spacing: 10) {
                            Text("صور \(challenges[currentIndex].prompt) خلال إنجازك هدف اليوم")
                                .font(DesignSystem.Typography.title3)
                                .primaryText()
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 20)
                            
                            // Change Challenge Button
                            Button(action: {
                                var newIndex: Int
                                repeat {
                                    newIndex = Int.random(in: 0..<challenges.count)
                                } while newIndex == currentIndex
                                currentIndex = newIndex
                                

                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(DesignSystem.Typography.caption)
                                    Text("غير التحدي")
                                        .font(DesignSystem.Typography.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(DesignSystem.Colors.primaryLight)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.large)
                    .shadow(color: DesignSystem.Shadows.light, radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Start Challenge Button
                    Button(action: {
                        challengeProgress.selectChallenge(index: currentIndex)
                        showingTheChallengeView = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("مشينا")
                                    .font(DesignSystem.Typography.title3)
                                    .foregroundColor(DesignSystem.Colors.invertedText)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .font(DesignSystem.Typography.caption)
                                    Text("اضغط للبدء")
                                        .font(DesignSystem.Typography.caption)
                                }
                                .foregroundColor(DesignSystem.Colors.invertedText.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.left")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(DesignSystem.Colors.invertedText.opacity(0.8))
                        }
                        .padding(20)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarBackButtonHidden(false)
            .navigationTitle("")
        }
        .navigationDestination(isPresented: $showingTheChallengeView) {
            TheChallengeView(selectedChallengeIndex: currentIndex) {
                showingTheChallengeView = false
            }
            .environmentObject(challengeProgress)
        }
    }
}

#Preview {
    ChallengePage()
        .environmentObject(ChallengeProgress())
}

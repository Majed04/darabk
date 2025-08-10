//
//  Home.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI

struct Home: View {
    @ObservedObject var user: User = User()
    @EnvironmentObject var challengeProgress: ChallengeProgress
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var streakDays = 7 // Add state for streak count
    @State private var randomChallenge: Challenge
    @State private var showingChallengeView = false
    @State private var showingStreakView = false
    
    // Weekly step data (1000 to 10000 range)
    private let weeklySteps = [8500, 6200, 7800, 9100, 5400, 7200, 6800]
    private let maxSteps = 10000
    
    // Number formatter for English numerals
    private let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        return formatter
    }()
    
    init() {
        // Initialize with a random challenge
        let challenges = ChallengesData.shared.challenges
        _randomChallenge = State(initialValue: challenges.randomElement() ?? challenges[0])
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("الرئيسية")
                    .font(.largeTitle)
                    .bold()
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                // Toolbar (streak and profile)
                HStack(spacing: 15) {
                    HStack(spacing: 2) {
                        Button(action: {
                            showingStreakView = true
                        }) {
                            Text(englishFormatter.string(from: NSNumber(value: streakDays)) ?? "\(streakDays)")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .bold()
                            Image(systemName: "flame.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                        }
                    }
                    Button(action: {
                        // Profile action
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#1B5299"))
                    }
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 10)

            HStack {
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("مرحبا \(user.name.isEmpty ? "..." : user.name)")
                            .bold()
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("خطواتك")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            if healthKitManager.isAuthorized {
                                Text(englishFormatter.string(from: NSNumber(value: healthKitManager.currentSteps)) ?? "\(healthKitManager.currentSteps)")
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(Color(hex: "#1B5299"))
                                    .contentTransition(.numericText())
                                    .animation(.easeInOut(duration: 0.5), value: healthKitManager.currentSteps)
                            } else {
                                Text("--")
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(.gray)
                            }
                            
                            
                        }
                        
                    }
                    .padding(.horizontal, 20)
                
                Spacer()
                }
                
                // Text area above the button
                VStack(alignment: .leading, spacing: 10) {
                    Text("تحدي اليوم")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                // .padding(.bottom)
                
                // Large rectangular button
                Button(action: {
                    showingChallengeView = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(randomChallenge.fullTitle)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 90) // Invisible border to prevent text overlap with image
                        
                        Spacer()
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color(hex: "#1B5299"))
                    .cornerRadius(15)
                    .overlay(
                        Image("Star")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .offset(x: 20, y: -50)
                            .zIndex(1)
                        , alignment: .topTrailing
                    )
                }
                .padding(.horizontal, 20)
                
                // Weekly Progress Chart
                VStack(alignment: .leading, spacing: 15) {
                    Text("أدائك الأسبوعي")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    HStack(spacing: 15) {
                        ForEach(0..<7, id: \.self) { day in
                            VStack(spacing: 8) {
                                // Progress bar
                                VStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: "#1B5299").opacity(0.3))
                                        .frame(width: 30, height: 100)
                                        .overlay(
                                            VStack {
                                                Spacer()
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color(hex: "#1B5299"))
                                                    .frame(width: 30, height: CGFloat(weeklySteps[day]) / CGFloat(maxSteps) * 100)
                                            }
                                        )
                                }
                                .padding(.top, 20)
                                
                                // Day label
                                Text(["أحد", "اثنين", "ثلاثاء", "أربعاء", "خميس", "جمعة", "سبت"][day])
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 50)
                
                Spacer()
        }
        .navigationDestination(isPresented: $showingChallengeView) {
            ChallengePage(selectedChallenge: randomChallenge)
                .environmentObject(challengeProgress)
        }
        .navigationDestination(isPresented: $showingStreakView) {
            StreakView()
        }
        .onAppear {
            // Start fetching steps when view appears
            healthKitManager.fetchTodaySteps()
        }
    }
}

#Preview {
    Home()
        .environmentObject(ChallengeProgress())
}

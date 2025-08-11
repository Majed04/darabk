//
//  darbakApp.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI
import GameKit

@main
struct darbakApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @StateObject var user = User()
    @StateObject var challengeProgress = ChallengeProgress()
    
    init() {
        // Initialize Game Center
        print("Initializing Game Center...")
        // Delay authentication slightly to ensure app is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            GameCenterManager.shared.authenticatePlayer()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if hasCompletedOnboarding {
                    if challengeProgress.isChallengeInProgress {
                        TheChallengeView(onBack: {
                            challengeProgress.completeChallenge()
                        })
                    } else {
                        MainTabView()
                    }
                } else {
                    Onboarding()
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .environmentObject(user)
        .environmentObject(challengeProgress)
    }
}

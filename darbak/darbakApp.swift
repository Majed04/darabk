//
//  darbakApp.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI

@main
struct darbakApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @StateObject var user = User()
    @StateObject var challengeProgress = ChallengeProgress()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if hasCompletedOnboarding {
                    if challengeProgress.isChallengeInProgress {
                        TheChallengeView(onBack: {
                            challengeProgress.completeChallenge()
                        })
                        .environmentObject(challengeProgress)
                    } else {
                        Home()
                            .environmentObject(challengeProgress)
                    }
                } else {
                    Onboarding()
                }
            }
        }
        .environmentObject(user)
        .environmentObject(challengeProgress)
    }
}

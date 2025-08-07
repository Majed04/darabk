//
//  darbakApp.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI

@main
struct darbakApp: App {
    @StateObject var user = User()
    @StateObject var challengeProgress = ChallengeProgress()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if challengeProgress.isChallengeInProgress {
                    TheChallengeView(onBack: {
                        challengeProgress.completeChallenge()
                    })
                    .environmentObject(challengeProgress)
                } else {
                    Home()
                        .environmentObject(challengeProgress)
                }
            }
        }
        .environmentObject(user)
        .environmentObject(challengeProgress)
    }
}

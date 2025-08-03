//
//  Leaderboard.swift
//  darbak
//
//  Created by Majed on 04/02/1447 AH.
//

import SwiftUI

struct Leaderboard: View {
    @State private var progress: Double = 0.1
    var body: some View {
        VStack(spacing: 20) {
            Text("Leaderboard").font(
                .largeTitle
            ).fontWeight(.bold)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .animation(.smooth, value: progress)
                .padding()

            Button("Increase Progress") {
                if progress < 1.0 {
                    progress += 0.1
                }
            }
            
            Button("Reset The Progress") {
                progress = 0
            }
            
        }
    }
}

//
//  Welcome.swift
//  darbak
//
//  Created by Majed on 05/02/1447 AH.
//

import SwiftUI
import Lottie

struct Onboarding: View {
    @EnvironmentObject var user: User

    @State private var isPlaying: Bool = false

    var body: some View {
        VStack {
            LottieView(animation: .named("walking"))
                .playbackMode(isPlaying ? .playing(.fromProgress(0, toProgress: 1, loopMode: .loop)) : .paused)
                .frame(width: 200, height: 200)
            
            Button(isPlaying ? "Pause" : "Play") {
                isPlaying.toggle()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

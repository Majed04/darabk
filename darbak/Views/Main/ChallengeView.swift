//
//  Challenge.swift
//  darbak
//
//  Created by Majed on 05/02/1447 AH.
//

import SwiftUI

struct Challenge: Identifiable {
    let id = UUID()
    let imageName: String
    let prompt: String
    let emojis: [String]
}

struct ChallengePage: View {
    @State private var currentIndex = 0
    
    let challenges: [Challenge] = [
        Challenge(imageName: "StopSign", prompt: "4 علامات مرورية", emojis: ["🛑", "🚦", "⚠️", "🚸", "📍", "🛤️"]),
        Challenge(imageName: "Car", prompt: "4 سيارات", emojis: ["🚌", "🚍", "🚐", "🚎", "🚗", "🚕"]),
        Challenge(imageName: "Bus", prompt: "3 باصات", emojis: ["🚌", "🚍", "🚐", "🚎", "🚗", "🚕"]),
        Challenge(imageName: "Cat", prompt: "3 قطط", emojis: ["🐈", "🐱", "🐈‍⬛", "😸", "🐾"]),
        Challenge(imageName: "Birds", prompt: "4 طيور", emojis: ["🐦", "🐥", "🦜", "🦤", "🕊️", "🪿"])
    ]
    
    var onBack: (() -> Void)? = nil
    @Environment(\.presentationMode) private var presentationMode
    
    private func createEmojiBackground() -> some View {
        GeometryReader { geometry in
            ForEach(0..<19, id: \.self) { index in
                let column = index % 3
                let row = index / 3
                let xOffset = CGFloat(column) * (geometry.size.width / 2.5) + 60
                let yOffset = CGFloat(row) * (geometry.size.height / 8) + 120
                
                Text(challenges[currentIndex].emojis[index % challenges[currentIndex].emojis.count])
                    .font(.system(size: 60))
                    .opacity(0.09)
                    .rotationEffect(.degrees(Double.random(in: -15...15)))
                    .position(
                        x: xOffset + CGFloat.random(in: -20...20),
                        y: yOffset + CGFloat.random(in: -15...15)
                    )
                    .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.01), value: currentIndex)
            }
        }
        .allowsHitTesting(false)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                createEmojiBackground()
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("صور \(challenges[currentIndex].prompt) خلال إنجازك هدف اليوم")
                        .font(.title)
                        .bold()
                    
                    Image(challenges[currentIndex].imageName)
                        .resizable()
                        .frame(height: 430)
                        .cornerRadius(20)
                    
                    Button(action: {
                        var newIndex: Int
                        repeat {
                            newIndex = Int.random(in: 0..<challenges.count)
                        } while newIndex == currentIndex
                        currentIndex = newIndex
                    }) {
                        HStack {
                            Text("بغير تحدي اليوم")
                            Image(systemName: "repeat")
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    HStack(alignment: .center){
                        CustomButton(title: "التحدي") {
                            
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            if let onBack = onBack {
                                onBack()
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Image(systemName: "chevron.backward")
                        }
                    }
                }
                .navigationTitle("تحدي اليوم")
            }
        }
    }
}

#Preview {
    ChallengePage()
}

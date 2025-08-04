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
}
struct ChallengePage: View {
    
    let challenges: [Challenge] = [
        Challenge(imageName: "StopSign", prompt: "4 علامات قف"),
        Challenge(imageName: "Car", prompt: "4 سيارات"),
        Challenge(imageName: "Bus", prompt: "3 باصات"),
    ]

    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("تحدي اليوم")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal)
            Text("صور \(challenges[currentIndex].prompt) خلال إنجازك هدف اليوم")
                .font(.title)
                .bold()
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        VStack(spacing: 10) {

            Image(challenges[currentIndex].imageName)
                .resizable()
                .frame(width: 380, height: 430)
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
            Spacer()
            CustomButton(title: "عرفنا عليك") {

            }

        }.padding()
    }
}

#Preview {
    ChallengePage()
}

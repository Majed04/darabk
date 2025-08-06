//
//  Challenges.swift
//  darbak
//
//  Created by Assistant on $(DATE)
//

import Foundation

struct Challenge: Identifiable {
    let id = UUID()
    let imageName: String
    let prompt: String
    let emojis: [String]
    let totalPhotos: Int
    let modelName: String
    let hasAI: Bool
    
    var fullTitle: String {
        return "صور \(prompt) خلال إنجازك هدف اليوم"
    }
}

class ChallengesData {
    static let shared = ChallengesData()
    
    private init() {}
    
    let challenges: [Challenge] = [
        Challenge(imageName: "StopSign", prompt: "4 علامات مرورية", emojis: ["🛑", "🚦", "⚠️", "🚸", "📍", "🛤️"], totalPhotos: 4, modelName: "TrafficSigns", hasAI: true),
        Challenge(imageName: "Car", prompt: "4 سيارات", emojis: ["🚌", "🚍", "🚐", "🚎", "🚗", "🚕"], totalPhotos: 4, modelName: "", hasAI: false),
        Challenge(imageName: "Bus", prompt: "3 باصات", emojis: ["🚌", "🚍", "🚐", "🚎", "🚗", "🚕"], totalPhotos: 3, modelName: "", hasAI: false),
        Challenge(imageName: "Cat", prompt: "3 قطط", emojis: ["🐈", "🐱", "🐈‍⬛", "😸", "🐾"], totalPhotos: 3, modelName: "", hasAI: false),
        Challenge(imageName: "Birds", prompt: "4 طيور", emojis: ["🐦", "🐥", "🦜", "🦤", "🕊️", "🪿"], totalPhotos: 4, modelName: "", hasAI: false),
        Challenge(imageName: "challenge1", prompt: "4 سياكل", emojis: ["🚴🏼", "🚵🏼", "🚲", "🚴🏼‍♀️", "🚲", "🚵🏼"], totalPhotos: 4, modelName: "BikesModel", hasAI: true)

    ]
}
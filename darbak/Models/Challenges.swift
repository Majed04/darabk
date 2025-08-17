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
    let isColorChallenge: Bool
    let targetColor: String?
    
    init(imageName: String, prompt: String, emojis: [String], totalPhotos: Int, modelName: String, hasAI: Bool, isColorChallenge: Bool = false, targetColor: String? = nil) {
        self.imageName = imageName
        self.prompt = prompt
        self.emojis = emojis
        self.totalPhotos = totalPhotos
        self.modelName = modelName
        self.hasAI = hasAI
        self.isColorChallenge = isColorChallenge
        self.targetColor = targetColor
    }
    
    var fullTitle: String {
        return "صور \(prompt) خلال إنجازك هدف اليوم"
    }
}

class ChallengesData {
    static let shared = ChallengesData()
    
    private init() {}
    
    let challenges: [Challenge] = [
        Challenge(imageName: "StopSign", prompt: "4 علامات قف", emojis: ["🛑", "🚦", "⚠️", "🚸", "📍", "🛤️"], totalPhotos: 4, modelName: "YOLOv3TinyInt8LUT", hasAI: true),
        Challenge(imageName: "Car", prompt: "4 سيارات", emojis: ["🚌", "🚍", "🚐", "🚎", "🚗", "🚕"], totalPhotos: 4, modelName: "YOLOv3TinyInt8LUT", hasAI: true),
        Challenge(imageName: "Bus", prompt: "3 باصات", emojis: ["🚌", "🚍", "🚐", "🚎", "🚗", "🚕"], totalPhotos: 3, modelName: "YOLOv3TinyInt8LUT", hasAI: true),
        Challenge(imageName: "Cat", prompt: "3 قطط", emojis: ["🐈", "🐱", "🐈‍⬛", "😸", "🐾"], totalPhotos: 3, modelName: "YOLOv3TinyInt8LUT", hasAI: true),
        Challenge(imageName: "Birds", prompt: "4 طيور", emojis: ["🐦", "🐥", "🦜", "🦤", "🕊️", "🪿"], totalPhotos: 4, modelName: "YOLOv3TinyInt8LUT", hasAI: true),
        Challenge(imageName: "TrafficLight", prompt: "3 اشارات مرور", emojis: ["🚦", "🚥", "🚘", "⚠️", "🛣️", "🚦"], totalPhotos: 3, modelName: "YOLOv3TinyInt8LUT", hasAI: true),
        Challenge(imageName: "Cat", prompt: "4 سياكل", emojis: ["🚴🏼", "🚵🏼", "🚲", "🚴🏼‍♀️", "🚲", "🚵🏼"], totalPhotos: 4, modelName: "YOLOv3TinyInt8LUT", hasAI: true),
        Challenge(imageName: "Colors", prompt: "7 أشياء خضراء", emojis: ["🟢", "🍃", "🌿", "🥒", "🍏", "🧩"], totalPhotos: 7, modelName: "ColorDetection", hasAI: true, isColorChallenge: true, targetColor: "green"),
        Challenge(imageName: "Colors", prompt: "5 أشياء زرقاء", emojis: ["👤", "🟦", "🧢", "💙", "📘", "🔵"], totalPhotos: 5, modelName: "ColorDetection", hasAI: true, isColorChallenge: true, targetColor: "blue"),
        Challenge(imageName: "Colors", prompt: "5 أشياء حمراء", emojis: ["🍎", "🚗", "🛑", "🍅", "♦️", "🥤"], totalPhotos: 5, modelName: "ColorDetection", hasAI: true, isColorChallenge: true, targetColor: "red")
    ]
}

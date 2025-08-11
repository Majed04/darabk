//
//  Challenges.swift
//  darbak
//
//  Created by Assistant on $(DATE)
//

import Foundation
import GameKit

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

// MARK: - Competition Models
struct PhotoChallengeRace: Identifiable, Codable {
    let id = UUID()
    let challengeId: UUID
    let player1Id: String
    let player2Id: String
    let player1Name: String
    let player2Name: String
    let dailyGoal: Int
    let startDate: Date
    let endDate: Date
    let status: RaceStatus
    let winnerId: String?
    
    var isActive: Bool {
        return status == .active && Date() <= endDate
    }
    
    var timeRemaining: TimeInterval {
        return max(0, endDate.timeIntervalSince(Date()))
    }
}

enum RaceStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct RaceProgress: Codable {
    let playerId: String
    let playerName: String
    let completedPhotos: Int
    let dailyGoalProgress: Int
    let lastUpdate: Date
    let isCompleted: Bool
    
    var progressPercentage: Double {
        return min(1.0, Double(completedPhotos) / Double(4)) // Assuming 4 photos per challenge
    }
    
    var dailyGoalPercentage: Double {
        return min(1.0, Double(dailyGoalProgress) / Double(10000)) // Assuming 10k daily goal
    }
}

struct RaceInvitation: Codable {
    let raceId: String
    let challengeId: String
    let challengerName: String
    let challengeName: String
    let dailyGoal: Int
    let sentDate: Date
}

struct PersistedRacesData: Codable {
    let races: [PhotoChallengeRace]
    let progress: [String: RaceProgress]
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
        Challenge(imageName: "Cat", prompt: "4 سياكل", emojis: ["🚴🏼", "🚵🏼", "🚲", "🚴🏼‍♀️", "🚲", "🚵🏼"], totalPhotos: 4, modelName: "YOLOv3TinyInt8LUT", hasAI: true)
    ]
}

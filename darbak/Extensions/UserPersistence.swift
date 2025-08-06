//
//  UserPersistence.swift
//  darbak
//
//  Created by Majed on 06/02/1447 AH.
//

import Foundation

// MARK: - Challenge Progress Persistence
class ChallengeProgress: ObservableObject {
    @Published var completedPhotos: Int = 0
    @Published var selectedChallengeIndex: Int = 0
    @Published var challengeTitle: String = "صور 4 علامات قف خلال انجازك هدف اليوم"
    
    let challenges = [
        (title: "صور 4 علامات قف خلال انجازك هدف اليوم", totalPhotos: 4, modelName: "TrafficSigns"),
        (title: "صور 4 سيارات خلال انجازك هدف اليوم", totalPhotos: 4, modelName: "TrafficSigns"),
        (title: "صور 3 سياكل خلال انجازك هدف اليوم", totalPhotos: 3, modelName: "BikesModel")
    ]
    
    init() {
        loadProgress()
    }
    
    func saveProgress() {
        UserDefaults.standard.set(completedPhotos, forKey: "challengeCompletedPhotos")
        UserDefaults.standard.set(selectedChallengeIndex, forKey: "selectedChallengeIndex")
        UserDefaults.standard.set(challengeTitle, forKey: "challengeTitle")
    }
    
    func loadProgress() {
        completedPhotos = UserDefaults.standard.integer(forKey: "challengeCompletedPhotos")
        selectedChallengeIndex = UserDefaults.standard.integer(forKey: "selectedChallengeIndex")
        challengeTitle = UserDefaults.standard.string(forKey: "challengeTitle") ?? challenges[0].title
    }
    
    func resetProgress() {
        completedPhotos = 0
        saveProgress()
    }
    
    func incrementProgress() {
        let maxPhotos = challenges[selectedChallengeIndex].totalPhotos
        if completedPhotos < maxPhotos {
            completedPhotos += 1
            saveProgress()
        }
    }
    
    var currentModelName: String {
        return challenges[selectedChallengeIndex].modelName
    }
    
    func selectChallenge(index: Int) {
        selectedChallengeIndex = index
        challengeTitle = challenges[index].title
        resetProgress() // Reset progress when switching challenges
        saveProgress()
    }
    
    var totalPhotos: Int {
        return challenges[selectedChallengeIndex].totalPhotos
    }
}

extension User {
    func saveToDefaults() {
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(gender.rawValue, forKey: "userGender")
        UserDefaults.standard.set(weight, forKey: "userWeight")
        UserDefaults.standard.set(age, forKey: "userAge")
        UserDefaults.standard.set(height, forKey: "userHeight")
        UserDefaults.standard.set(sleepingHours, forKey: "userSleepingHours")
        UserDefaults.standard.set(goalSteps, forKey: "userGoalSteps")
    }

    func loadFromDefaults() {
        self.name = UserDefaults.standard.string(forKey: "userName") ?? "unknown"
        if let genderRaw = UserDefaults.standard.string(forKey: "userGender"),
           let genderEnum = Gender(rawValue: genderRaw) {
            self.gender = genderEnum
        } else {
            self.gender = .male
        }
        self.weight = UserDefaults.standard.double(forKey: "userWeight")
        self.age = UserDefaults.standard.integer(forKey: "userAge")
        self.height = UserDefaults.standard.double(forKey: "userHeight")
        self.sleepingHours = UserDefaults.standard.integer(forKey: "userSleepingHours")
        
        // Only load goalSteps if a value was previously saved, otherwise keep the default
        let savedGoalSteps = UserDefaults.standard.integer(forKey: "userGoalSteps")
        if savedGoalSteps > 0 {
            self.goalSteps = savedGoalSteps
        }
        // If savedGoalSteps is 0 (default return value), keep the initialized value
    }
}

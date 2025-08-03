//
//  UserPersistence.swift
//  darbak
//
//  Created by Majed on 06/02/1447 AH.
//

import Foundation

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
        self.goalSteps = UserDefaults.standard.integer(forKey: "userGoalSteps")
    }
}

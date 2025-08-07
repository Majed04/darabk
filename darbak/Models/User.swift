//
//  User.swift
//  darbak
//
//  Created by Majed on 06/02/1447 AH.
//


import Foundation
import SwiftUI

enum Gender: String, CaseIterable {
    case male
    case female
}

class User: ObservableObject {
    @Published var name: String = ""
    @Published var gender: Gender = .male;
    @Published var weight: Int = 0
    @Published var age: Int = 0
    @Published var height: Int = 0
    @Published var sleepingHours: Int = 4
    @Published var goalSteps: Int = 10000

    init(name: String = "", gender: Gender = .male, weight: Int = 0, age: Int = 0, height: Int = 0, sleepingHours: Int = 4, goalSteps: Int = 0) {
        self.name = name
        self.gender = gender
        self.weight = weight
        self.age = age
        self.height = height
        self.sleepingHours = sleepingHours
        self.goalSteps = goalSteps
        self.loadFromDefaults()
    }
}

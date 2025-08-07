//
//  calculation.swift
//  darbak
//
//  Created by Majed on 13/02/1447 AH.
//

import Foundation

func calculateGoalSteps(user: User) {
    var baseSteps = 5000
    

    switch user.age {
    case 0...25:
        baseSteps += 2000
    case 26...45:
        baseSteps += 1000
    case 46...65:
        baseSteps += 500
    default:
        break
    }
    
    // Adjust for Gender
    if user.gender == .male {
        baseSteps += 500 // Men generally have a slightly higher average step count
    }
    
    // Adjust for BMI (Body Mass Index) to encourage activity
    if user.height > 0 && user.weight > 0 {
        let heightInMeters = user.height / 100
        let bmi = user.weight / (heightInMeters * heightInMeters)
        
        if bmi > 25 { // Overweight category
            baseSteps += 1500
        } else if bmi < 18 { // Underweight category
            baseSteps += 500
        }
    }
    
    if user.sleepingHours < 7 || user.sleepingHours > 9 {
        baseSteps += 1000
    }
    
    let resultStep = max(baseSteps, 5000)
    
    user.goalSteps = resultStep
    
    user.saveToDefaults()
}

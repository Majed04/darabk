//
//  HealthKitManager.swift
//  darbak
//
//  Created by Majed on 16/02/1447 AH.
//

import SwiftUI
import HealthKit

// MARK: - HealthKit Manager
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var currentSteps: Int = 0
    @Published var isAuthorized = false
    
    private var stepCountQuery: HKObserverQuery?
    
    init() {
        requestAuthorization()
    }
    
    deinit {
        stopObserving()
    }
    
    private func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.startObserving()
                    self?.fetchTodaySteps()
                } else {
                    print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func fetchTodaySteps() {
        guard isAuthorized else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            guard let result = result,
                  let sum = result.sumQuantity() else {
                print("Failed to fetch steps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            DispatchQueue.main.async {
                self?.currentSteps = steps
            }
        }
        
        healthStore.execute(query)
    }
    
    private func startObserving() {
        guard isAuthorized else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        stepCountQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }
            
            // Fetch updated steps when new data is available
            self?.fetchTodaySteps()
        }
        
        if let query = stepCountQuery {
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
                if let error = error {
                    print("Background delivery error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func stopObserving() {
        if let query = stepCountQuery {
            healthStore.stop(query)
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        healthStore.disableBackgroundDelivery(for: stepType) { _, _ in }
    }
}

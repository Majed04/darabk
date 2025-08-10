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
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    private var stepCountQuery: HKObserverQuery?
    
    init() {
        print("🏥 HealthKitManager initializing...")
        requestAuthorization()
        print("🏥 HealthKitManager initialization complete")
    }
    
    deinit {
        stopObserving()
    }
    
    private func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("🏥 HealthKit is not available on this device")
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.currentSteps = 8500 // Fallback mock data
            }
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        print("🏥 Requesting HealthKit authorization...")
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { [weak self] success, error in
            DispatchQueue.main.async {
                let status = self?.healthStore.authorizationStatus(for: stepType) ?? .notDetermined
                self?.authorizationStatus = status
                
                // Check if we have any form of access (sharingAuthorized or sharingDenied both can work)
                if success {
                    print("🏥 HealthKit authorization completed with status: \(status.rawValue)")
                    
                    // Try to fetch data regardless of status - iOS sometimes returns .sharingDenied even when access is granted
                    self?.isAuthorized = true
                    self?.startObserving()
                    self?.fetchTodaySteps()
                    
                    // Test if we can actually read data
                    self?.testHealthKitAccess { hasAccess in
                        DispatchQueue.main.async {
                            if !hasAccess {
                                print("🏥 Cannot read HealthKit data, using fallback")
                                self?.isAuthorized = false
                                self?.provideFallbackData()
                            }
                        }
                    }
                } else {
                    print("🏥 HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                    self?.isAuthorized = false
                    self?.provideFallbackData()
                }
            }
        }
    }
    
    func fetchTodaySteps() {
        guard isAuthorized else { 
            print("🏥 HealthKit not authorized, using fallback data")
            return 
        }
        
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
    
    func provideFallbackData() {
        // Provide realistic step data based on time of day
        let hour = Calendar.current.component(.hour, from: Date())
        let baseSteps = Int(Double(hour) / 24.0 * Double.random(in: 8000...15000))
        currentSteps = max(baseSteps, 500) // Minimum 500 steps
        print("🏥 Using fallback step data: \(currentSteps)")
    }
    
    func retryAuthorization() {
        print("🏥 Retrying HealthKit authorization...")
        requestAuthorization()
    }
    
    private func testHealthKitAccess(completion: @escaping (Bool) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.startOfDay(for: endDate)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if error != nil {
                print("🏥 HealthKit test failed: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            } else if result != nil {
                print("🏥 HealthKit test successful - can read data")
                completion(true)
            } else {
                print("🏥 HealthKit test - no data available")
                completion(true) // No error means we have access, just no data
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchStepsForDate(_ date: Date, completion: @escaping (Int?) -> Void) {
        guard isAuthorized else {
            completion(nil)
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result,
                  let sum = result.sumQuantity() else {
                completion(nil)
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            completion(steps)
        }
        
        healthStore.execute(query)
    }
    
    func fetchStepsForDateRange(from startDate: Date, to endDate: Date, completion: @escaping ([Date: Int]) -> Void) {
        guard isAuthorized else {
            completion([:])
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: calendar.startOfDay(for: startDate),
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, results, error in
            if let error = error {
                print("🏥 Error fetching steps data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([:])
                }
                return
            }
            
            guard let results = results else {
                print("🏥 No results from HealthKit query")
                DispatchQueue.main.async {
                    completion([:])
                }
                return
            }
            
            var stepsData: [Date: Int] = [:]
            
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                let date = calendar.startOfDay(for: statistics.startDate)
                stepsData[date] = Int(steps)
                print("🏥 Fetched \(Int(steps)) steps for \(date)")
            }
            
            print("🏥 Successfully fetched \(stepsData.count) days of data")
            DispatchQueue.main.async {
                completion(stepsData)
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

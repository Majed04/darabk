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
    private var isInitialAuthComplete = false
    
    init() {
        print("🏥 HealthKitManager initializing...")
        setupAppStateNotifications()
        requestAuthorization()
        print("🏥 HealthKitManager initialization complete")
    }
    
    deinit {
        stopObserving()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAppStateNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // Re-check authorization status when app becomes active
        // This handles cases where user changed permissions in Settings
        if isInitialAuthComplete {
            checkAuthorizationStatus()
        }
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
                self?.isInitialAuthComplete = true
                
                if let error = error {
                    print("🏥 HealthKit authorization failed: \(error.localizedDescription)")
                    self?.isAuthorized = false
                    self?.provideFallbackData()
                    return
                }
                
                // Always check the actual authorization status after requesting
                self?.checkAuthorizationStatus()
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
    
    func refreshAuthorizationStatus() {
        print("🏥 Refreshing HealthKit authorization status...")
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("🏥 HealthKit is not available on this device")
            isAuthorized = false
            provideFallbackData()
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        authorizationStatus = status
        
        print("🏥 Current HealthKit authorization status: \(status.rawValue)")
        
        // Test if we can actually read data instead of relying on status alone
        // iOS sometimes returns .sharingDenied even when permission is granted
        testHealthKitAccess { [weak self] hasAccess in
            DispatchQueue.main.async {
                if hasAccess {
                    print("🏥 HealthKit access confirmed - can read data")
                    self?.isAuthorized = true
                    self?.startObserving()
                    self?.fetchTodaySteps()
                } else {
                    print("🏥 Cannot read HealthKit data, using fallback")
                    self?.isAuthorized = false
                    self?.provideFallbackData()
                }
            }
        }
    }
    
    private func testHealthKitAccess(completion: @escaping (Bool) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // Try a more comprehensive test - check for any step data in the last 7 days
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                // Check if this is a permission error
                let nsError = error as NSError
                if nsError.domain == "com.apple.healthkit" && nsError.code == 5 {
                    print("🏥 HealthKit test failed: Permission denied")
                    completion(false)
                } else {
                    print("🏥 HealthKit test failed with other error: \(error.localizedDescription)")
                    // For other errors, assume we have permission but there might be a temporary issue
                    completion(true)
                }
            } else {
                print("🏥 HealthKit test successful - can read data (result: \(result != nil))")
                completion(true)
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

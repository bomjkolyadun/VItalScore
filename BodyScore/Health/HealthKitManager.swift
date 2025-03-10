import Foundation
import HealthKit

/// Responsible for HealthKit authorization and providing raw data access
class HealthKitManager {
    let healthStore = HKHealthStore()
    
    // Types of health data we'll request
    let typesToRead: Set<HKObjectType> = {
        guard let bodyFatPercentage = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
              let leanBodyMass = HKObjectType.quantityType(forIdentifier: .leanBodyMass),
              let bmi = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
              let vo2Max = HKObjectType.quantityType(forIdentifier: .vo2Max),
              let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
              let activeEnergyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate),
              let heartRateVariability = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let oxygenSaturation = HKObjectType.quantityType(forIdentifier: .oxygenSaturation),
              let bloodPressureSystolic = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let bloodPressureDiastolic = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic),
              let basalEnergyBurned = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
              let height = HKObjectType.quantityType(forIdentifier: .height),
              let dob = HKObjectType.characteristicType(
                forIdentifier: .dateOfBirth
              ),
              let sex = HKObjectType.characteristicType(
                forIdentifier: .biologicalSex
              )
        else {
            return Set<HKObjectType>()
        }
        
        // Optional types that may not be available on all devices or may be empty
        var types: Set<HKObjectType> = [
            bodyFatPercentage, leanBodyMass, bmi,
            vo2Max, stepCount, activeEnergyBurned,
            restingHeartRate, heartRateVariability, oxygenSaturation,
            bloodPressureSystolic, bloodPressureDiastolic,
            basalEnergyBurned, height, sex, dob
        ]
        
        // Add workout type
        let workoutType = HKObjectType.workoutType()
        types.insert(workoutType)

        // Add sleep type
        if let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }
        
        // Add glucose if available
        if let bloodGlucose = HKObjectType.quantityType(forIdentifier: .bloodGlucose) {
            types.insert(bloodGlucose)
        }
        
        return types
    }()
    
    init() {
        // Check if HealthKit is available
        if HKHealthStore.isHealthDataAvailable() {
            print("HealthKit is available")
        } else {
            print("HealthKit is not available on this device")
        }
    }
    
    // Request authorization to access HealthKit data
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        print("Requesting HealthKit authorization...")
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("HealthKit authorization granted")
                } else if let error = error {
                    print("Authorization failed with error: \(error.localizedDescription)")
                } else {
                    print("Authorization denied without error")
                }
                completion(success, error)
            }
        }
    }
    
    // Helper methods for creating predicates and executing queries
    func createLastWeekPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        return HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
    }
    
    func createLongerPredicate(months: Int = 3) -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .month, value: -months, to: now)!
        return HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
    }
}

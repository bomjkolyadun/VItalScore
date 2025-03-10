import Foundation
import HealthKit

class FitnessFetcher {
    private let healthKitManager: HealthKitManager
    private let normalizer: FitnessNormalizerProtocol

    init(
        healthKitManager: HealthKitManager,
        normalizer: FitnessNormalizerProtocol
    ) {
        self.healthKitManager = healthKitManager
        self.normalizer = normalizer
    }
    
    func fetchMetrics(completion: @escaping ([HealthMetric]) -> Void) {
        let metrics = [
            fetchVO2Max,
            fetchStepCount,
            fetchActiveCalories
        ]
        
        let group = DispatchGroup()
        var fitnessMetrics: [HealthMetric] = []
        
        for fetchMetric in metrics {
            group.enter()
            fetchMetric { metric in
                if let metric = metric {
                    fitnessMetrics.append(metric)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(fitnessMetrics)
        }
    }
    
    private func fetchVO2Max(completion: @escaping (HealthMetric?) -> Void) {
        guard let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(quantityType: vo2MaxType,
                                     quantitySamplePredicate: healthKitManager.createLastWeekPredicate(),
                                     options: .mostRecent) { _, result, error in
            
            guard error == nil, let result = result, let quantity = result.mostRecentQuantity() else {
                completion(nil)
                return
            }
            
            let value = quantity.doubleValue(for: HKUnit.init(from: "ml/kg*min"))
            let metric = HealthMetric(id: "vo2Max", name: "VO₂ Max", 
                                    value: value, unit: "ml/kg/min", 
                                    category: .fitness,
                                    normalizedScore: self.normalizer.normalizeVO2Max(value))
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }
    
    private func fetchStepCount(completion: @escaping (HealthMetric?) -> Void) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil)
            return
        }
        
        let predicate = healthKitManager.createLastWeekPredicate()
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard error == nil, let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch step count: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }
            
            let value = sum.doubleValue(for: HKUnit.count())
            let dailyAverage = value / 7.0  // Average over the week
            
            print("Fetched step count: \(dailyAverage) steps per day")
            
            let metric = HealthMetric(
                id: "stepCount", 
                name: "Daily Steps", 
                value: dailyAverage, 
                unit: "steps",
                category: .fitness,
                normalizedScore: self.normalizer.normalizeSteps(dailyAverage)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }
    
    private func fetchActiveCalories(completion: @escaping (HealthMetric?) -> Void) {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil)
            return
        }
        
        let predicate = healthKitManager.createLastWeekPredicate()
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard error == nil, let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch active calories: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }
            
            let value = sum.doubleValue(for: HKUnit.kilocalorie())
            let dailyAverage = value / 7.0  // Average over the week
            
            print("Fetched active calories: \(dailyAverage) kcal per day")
            
            let metric = HealthMetric(
                id: "activeCalories", 
                name: "Active Calories", 
                value: dailyAverage, 
                unit: "kcal",
                category: .fitness,
                normalizedScore: self.normalizer.normalizeActiveCalories(dailyAverage)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }
}

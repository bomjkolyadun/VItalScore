import Foundation
import HealthKit

class MetabolicFetcher {
    private let healthKitManager: HealthKitManager
    private let normalizer: MetabolicNormalizerProtocol

    init(
        healthKitManager: HealthKitManager,
        normalizer: MetabolicNormalizerProtocol
    ) {
        self.healthKitManager = healthKitManager
        self.normalizer = normalizer
    }
    
    func fetchMetrics(completion: @escaping ([HealthMetric]) -> Void) {
        let metrics = [
            fetchBMR,
            fetchGlucose
        ]
        
        let group = DispatchGroup()
        var metabolicMetrics: [HealthMetric] = []
        
        for fetchMetric in metrics {
            group.enter()
            fetchMetric { metric in
                if let metric = metric {
                    metabolicMetrics.append(metric)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(metabolicMetrics)
        }
    }
    
    private func fetchBMR(completion: @escaping (HealthMetric?) -> Void) {
        guard let bmrType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
            completion(nil)
            return
        }
        
        let predicate = healthKitManager.createLastWeekPredicate()
        
        // Changed query to calculate sum instead of average for daily totals
        let query = HKStatisticsQuery(
            quantityType: bmrType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard error == nil, let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch BMR: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }
            
            let totalValue = sum.doubleValue(for: HKUnit.kilocalorie())
            // Calculate daily average
            let daysCount = 7.0
            let dailyAverage = totalValue / daysCount
            
            print("Fetched BMR: \(dailyAverage) kcal/day (Total: \(totalValue) over \(Int(daysCount)) days)")
            
            let metric = HealthMetric(
                id: "bmr", 
                name: "Basal Metabolic Rate", 
                value: dailyAverage, 
                unit: "kcal/day",
                category: .metabolic,
                normalizedScore: self.normalizer.normalizeBMR(dailyAverage)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }

    private func fetchGlucose(completion: @escaping (HealthMetric?) -> Void) {
        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            print("Blood glucose type not available")
            completion(nil)
            return
        }
        
        // Use sorting to make sure we get the most recent glucose readings
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Create a query for the most recent samples
        let query = HKSampleQuery(
            sampleType: glucoseType,
            predicate: healthKitManager.createLastWeekPredicate(),
            limit: 10, // Get several recent readings to average
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard error == nil, let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                print("Failed to fetch glucose data: \(error?.localizedDescription ?? "No data available")")
                completion(nil)
                return
            }
            
            // Calculate the average of the recent readings
            let totalValue = samples.reduce(0.0) { sum, sample in
                // Ensure consistent unit (mg/dL)
                return sum + sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci)))
            }
            
            let averageValue = totalValue / Double(samples.count)
            
            print("Fetched glucose: \(averageValue) mg/dL (from \(samples.count) samples)")
            
            let metric = HealthMetric(
                id: "glucose", 
                name: "Blood Glucose", 
                value: averageValue, 
                unit: "mg/dL",
                category: .metabolic,
                normalizedScore: self.normalizer.normalizeGlucose(averageValue)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }
}

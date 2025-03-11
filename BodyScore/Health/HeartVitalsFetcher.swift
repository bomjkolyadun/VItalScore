import Foundation
import HealthKit

class HeartVitalsFetcher: HealthMetricFetcherProtocol {
    private let healthKitManager: HealthKitManager
    private let normalizer: VitalsNormalizerProtocol

    init(
        healthKitManager: HealthKitManager,
        normalizer: VitalsNormalizerProtocol
    ) {
        self.healthKitManager = healthKitManager
        self.normalizer = normalizer
    }
    
    func fetchMetrics(completion: @escaping ([HealthMetric]) -> Void) {
        let metrics = [
            fetchRestingHeartRate,
            fetchHeartRateVariability,
            fetchBloodOxygen,
            fetchBloodPressure
        ]
        
        let group = DispatchGroup()
        var vitalsMetrics: [HealthMetric] = []
        
        for fetchMetric in metrics {
            group.enter()
            fetchMetric { metric in
                if let metric = metric {
                    vitalsMetrics.append(metric)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(vitalsMetrics)
        }
    }
    
    private func fetchRestingHeartRate(completion: @escaping (HealthMetric?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(
            quantityType: heartRateType,
            quantitySamplePredicate: healthKitManager.createLastWeekPredicate(),
            options: .discreteAverage
        ) { _, result, error in
            guard error == nil, let result = result, let average = result.averageQuantity() else {
                print("Failed to fetch resting heart rate: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }
            
            let value = average.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            
            print("Fetched resting heart rate: \(value) bpm")
            
            let metric = HealthMetric(
                id: "restingHeartRate", 
                name: "Resting Heart Rate", 
                value: value, 
                unit: "bpm",
                category: .heartAndVitals,
                normalizedScore: self.normalizer.normalizeRestingHeartRate(value)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }

    private func fetchHeartRateVariability(completion: @escaping (HealthMetric?) -> Void) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(
            quantityType: hrvType,
            quantitySamplePredicate: healthKitManager.createLastWeekPredicate(),
            options: .discreteAverage
        ) { _, result, error in
            guard error == nil, let result = result, let average = result.averageQuantity() else {
                print("Failed to fetch HRV: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }
            
            let value = average.doubleValue(for: HKUnit.secondUnit(with: .milli))
            
            print("Fetched HRV: \(value) ms")
            
            let metric = HealthMetric(
                id: "heartRateVariability", 
                name: "Heart Rate Variability", 
                value: value, 
                unit: "ms",
                category: .heartAndVitals,
                normalizedScore: self.normalizer.normalizeHRV(value)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }

    private func fetchBloodOxygen(completion: @escaping (HealthMetric?) -> Void) {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(
            quantityType: oxygenType,
            quantitySamplePredicate: healthKitManager.createLastWeekPredicate(),
            options: .discreteAverage
        ) { _, result, error in
            guard error == nil, let result = result, let average = result.averageQuantity() else {
                print("Failed to fetch blood oxygen: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }
            
            let value = average.doubleValue(for: HKUnit.percent()) * 100
            
            print("Fetched blood oxygen: \(value)%")
            
            let metric = HealthMetric(
                id: "bloodOxygen", 
                name: "Blood Oxygen", 
                value: value, 
                unit: "%",
                category: .heartAndVitals,
                normalizedScore: self.normalizer.normalizeBloodOxygen(value)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }

    private func fetchBloodPressure(completion: @escaping (HealthMetric?) -> Void) {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            completion(nil)
            return
        }
        
        let group = DispatchGroup()
        var systolic: Double?
        var diastolic: Double?
        
        // Fetch systolic blood pressure
        group.enter()
        let systolicQuery = HKStatisticsQuery(
            quantityType: systolicType,
            quantitySamplePredicate: healthKitManager.createLastWeekPredicate(),
            options: .discreteAverage
        ) { _, result, error in
            defer { group.leave() }
            
            guard error == nil, let result = result, let average = result.averageQuantity() else {
                print("Failed to fetch systolic BP: \(error?.localizedDescription ?? "No data")")
                return
            }
            
            systolic = average.doubleValue(for: HKUnit.millimeterOfMercury())
        }
        
        // Fetch diastolic blood pressure
        group.enter()
        let diastolicQuery = HKStatisticsQuery(
            quantityType: diastolicType,
            quantitySamplePredicate: healthKitManager.createLastWeekPredicate(),
            options: .discreteAverage
        ) { _, result, error in
            defer { group.leave() }
            
            guard error == nil, let result = result, let average = result.averageQuantity() else {
                print("Failed to fetch diastolic BP: \(error?.localizedDescription ?? "No data")")
                return
            }
            
            diastolic = average.doubleValue(for: HKUnit.millimeterOfMercury())
        }
        
        healthKitManager.healthStore.execute(systolicQuery)
        healthKitManager.healthStore.execute(diastolicQuery)
        
        group.notify(queue: .main) {
            guard let systolic = systolic, let diastolic = diastolic else {
                completion(nil)
                return
            }
            
            print("Fetched BP: \(systolic)/\(diastolic) mmHg")
            
            // Create a combined blood pressure metric
            let metric = HealthMetric(
                id: "bloodPressure", 
                name: "Blood Pressure", 
                value: systolic, // Primary value is systolic
                unit: "\(Int(systolic))/\(Int(diastolic)) mmHg", // Display format
                category: .heartAndVitals,
                normalizedScore: self.normalizer.normalizeBloodPressure(systolic: systolic, diastolic: diastolic)
            )
            completion(metric)
        }
    }
}

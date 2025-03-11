import Foundation
import HealthKit

class BodyCompositionFetcher: HealthMetricFetcherProtocol {
    private let healthKitManager: HealthKitManager
    private let normalizer: BodyCompositionNormalizerProtocol

    // Additional properties to store weight and height for BMI calculation
    private var latestWeight: Double?
    private var latestHeight: Double?
    
    init(
        healthKitManager: HealthKitManager,
        normalizer: BodyCompositionNormalizerProtocol
    ) {
        self.healthKitManager = healthKitManager
        self.normalizer = normalizer
    }
    
    func fetchMetrics(completion: @escaping ([HealthMetric]) -> Void) {
        // Expanded metrics array to include weight and height
        let metrics = [
            fetchBodyFatPercentage,
            fetchLeanBodyMass,
            fetchHeight,
            fetchBMI
        ]
        
        let group = DispatchGroup()
        var bodyCompositionMetrics: [HealthMetric] = []
        
        for fetchMetric in metrics {
            group.enter()
            fetchMetric { metric in
                if let metric = metric {
                    bodyCompositionMetrics.append(metric)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(bodyCompositionMetrics)
        }
    }
    
    private func fetchBodyFatPercentage(completion: @escaping (HealthMetric?) -> Void) {
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
            print("Body Fat Percentage type not available")
            completion(nil)
            return
        }
        
        let predicate = healthKitManager.createLongerPredicate(months: 3)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: bodyFatType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching body fat percentage: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                print("No body fat percentage data found")
                completion(nil)
                return
            }
            
            let value = sample.quantity.doubleValue(for: HKUnit.percent())
            print("Fetched body fat percentage: \(value)% (Date: \(sample.endDate))")
            
            let metric = HealthMetric(
                id: "bodyFat",
                name: "Body Fat Percentage", 
                value: value * 100.0,
                unit: "%", 
                category: .bodyComposition, 
                normalizedScore: self.normalizer.normalizeBodyFat(value)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }
    
    private func fetchLeanBodyMass(completion: @escaping (HealthMetric?) -> Void) {
        guard let leanBodyMassType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) else {
            print("Lean Body Mass type not available")
            completion(nil)
            return
        }
        
        let predicate = healthKitManager.createLongerPredicate(months: 3)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: leanBodyMassType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching lean body mass: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                print("No lean body mass data found")
                completion(nil)
                return
            }
            
            let value = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            print("Fetched lean body mass: \(value) kg (Date: \(sample.endDate))")
            
            let metric = HealthMetric(
                id: "leanBodyMass", 
                name: "Lean Body Mass", 
                value: value,
                unit: "kg", 
                category: .bodyComposition,
                normalizedScore: self.normalizer.normalizeLeanBodyMass(value)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }
    
    private func fetchHeight(completion: @escaping (HealthMetric?) -> Void) {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            print("Height type not available")
            completion(nil)
            return
        }
        
        let predicate = healthKitManager.createLongerPredicate(months: 6)  // Height changes less frequently
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: heightType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching height: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                print("No height data found")
                completion(nil)
                return
            }
            
            let meters = sample.quantity.doubleValue(for: HKUnit.meter())
            print("Fetched height: \(meters) m (Date: \(sample.endDate))")
            
            // Store for BMI calculation
            self.latestHeight = meters
            
//            let metric = HealthMetric(
//                id: "height", 
//                name: "Height", 
//                value: meters,
//                unit: "m", 
//                category: .bodyComposition,
//                normalizedScore: 0.5  // Neutral score for height
//            )
            completion(nil)
        }
        
        healthKitManager.healthStore.execute(query)
    }
    
    private func fetchBMI(completion: @escaping (HealthMetric?) -> Void) {
        guard let bmiType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else {
            print("BMI type not available")
            completion(nil)
            return
        }
        
        let predicate = healthKitManager.createLongerPredicate(months: 3)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: bmiType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching BMI: \(error.localizedDescription)")
                // Try calculating BMI from weight and height as fallback
                self.calculateBMI(completion: completion)
                return
            }
            
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                print("No BMI data found in HealthKit - trying to calculate from weight and height")
                // Try calculating BMI from weight and height as fallback
                self.calculateBMI(completion: completion)
                return
            }
            
            let value = sample.quantity.doubleValue(for: HKUnit.count())
            print("Fetched BMI: \(value) (Date: \(sample.endDate))")
            
            let metric = HealthMetric(
                id: "bmi", 
                name: "BMI", 
                value: value,
                unit: "", 
                category: .bodyComposition,
                normalizedScore: self.normalizer.normalizeBMI(value)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }
    
    private func calculateBMI(completion: @escaping (HealthMetric?) -> Void) {
        guard let weight = latestWeight, let height = latestHeight, height > 0 else {
            print("Cannot calculate BMI: missing weight or height data")
            completion(nil)
            return
        }
        
        // BMI formula: weight (kg) / (height (m) * height (m))
        let bmi = weight / (height * height)
        print("Calculated BMI from weight and height: \(bmi)")
        
        let metric = HealthMetric(
            id: "bmi", 
            name: "BMI (Calculated)", 
            value: bmi,
            unit: "", 
            category: .bodyComposition,
            normalizedScore: self.normalizer.normalizeBMI(bmi)
        )
        completion(metric)
    }
}

import Foundation
import HealthKit

class LifestyleFetcher {
    private let healthKitManager: HealthKitManager
    private let normalizer: MetricNormalizer
    
    init(healthKitManager: HealthKitManager, normalizer: MetricNormalizer) {
        self.healthKitManager = healthKitManager
        self.normalizer = normalizer
    }
    
    func fetchMetrics(completion: @escaping ([HealthMetric]) -> Void) {
        let metrics = [
            fetchSleep,
            fetchHydration
        ]
        
        let group = DispatchGroup()
        var lifestyleMetrics: [HealthMetric] = []
        
        for fetchMetric in metrics {
            group.enter()
            fetchMetric { metric in
                if let metric = metric {
                    lifestyleMetrics.append(metric)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(lifestyleMetrics)
        }
    }
    
    private func fetchSleep(completion: @escaping (HealthMetric?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        
        let predicate = healthKitManager.createLastWeekPredicate()
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { _, samples, error in
            guard error == nil, let samples = samples as? [HKCategorySample] else {
                print("Failed to fetch sleep data: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }
            
            var totalSleepTime: TimeInterval = 0
            var inBedCount = 0
            
            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue || 
                   sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalSleepTime += sample.endDate.timeIntervalSince(sample.startDate)
                    inBedCount += 1
                }
            }
            
            // If we have less than 3 nights of data, not enough to calculate
            if inBedCount < 3 {
                print("Not enough sleep data: only \(inBedCount) nights")
                completion(nil)
                return
            }
            
            // Calculate average sleep time in hours
            let averageSleepHours = (totalSleepTime / Double(inBedCount)) / 3600.0
            
            print("Fetched sleep: \(averageSleepHours) hours per night")
            
            let metric = HealthMetric(
                id: "sleep", 
                name: "Sleep Duration", 
                value: averageSleepHours, 
                unit: "hours",
                category: .lifestyle,
                normalizedScore: self.normalizer.normalizeSleep(averageSleepHours)
            )
            completion(metric)
        }
        
        healthKitManager.healthStore.execute(query)
    }

    private func fetchHydration(completion: @escaping (HealthMetric?) -> Void) {
        // Apple HealthKit doesn't directly track hydration
        // Calculate recommended daily water intake based on demographics
        
        let baseRecommendation: Double
        var dailyWaterIntake: Double
        
        // Calculate based on gender, age and height
        switch self.normalizer.userProfile.userGender {
        case .female:
            baseRecommendation = 2700.0 // 2.7L in ml
        case .male:
            baseRecommendation = 3700.0 // 3.7L in ml
        default:
            baseRecommendation = 3200.0 // Average between male and female
        }
        
        // Age adjustment - younger people typically need relatively more water per kg of body weight
        let userAge = self.normalizer.userProfile.userAge
        let ageAdjustment: Double
        if userAge > 0 {
            if userAge < 30 {
                ageAdjustment = 1.1 // 10% more for younger adults
            } else if userAge > 65 {
                ageAdjustment = 0.9 // 10% less for older adults
            } else {
                ageAdjustment = 1.0 // No adjustment for middle-aged adults
            }
        } else {
            ageAdjustment = 1.0 // Default if age unknown
        }
        
        // Height adjustment - taller people typically need more water
        let userHeight = self.normalizer.userProfile.userHeight
        let heightAdjustment: Double
        if userHeight > 0 {
            // Reference heights: ~1.7m for women, ~1.8m for men
            let referenceHeight = (self.normalizer.userProfile.userGender == .female) ? 1.7 : 1.8
            heightAdjustment = userHeight / referenceHeight
        } else {
            heightAdjustment = 1.0 // Default if height unknown
        }
        
        // Calculate adjusted water intake recommendation
        dailyWaterIntake = baseRecommendation * ageAdjustment * heightAdjustment
        
        // Round to nearest 50ml for cleaner display
        dailyWaterIntake = round(dailyWaterIntake / 50) * 50
        
        // For now, we'll assume the user is meeting 80% of their recommended intake
        let estimatedIntake = dailyWaterIntake * 0.8
        
        // Create the metric with calculated recommendation
        let metric = HealthMetric(
            id: "hydration",
            name: "Hydration",
            value: estimatedIntake,
            unit: "ml",
            category: .lifestyle,
            normalizedScore: self.normalizer.normalizeHydration(estimatedIntake, recommended: dailyWaterIntake)
        )
        
        print("Calculated hydration recommendation: \(dailyWaterIntake) ml, estimated intake: \(estimatedIntake) ml")
        completion(metric)
    }
}

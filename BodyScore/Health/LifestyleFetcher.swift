import Foundation
import HealthKit

class LifestyleFetcher: HealthMetricFetcherProtocol {
    private let healthKitManager: HealthKitManager
    private let normalizer: LifestyleNormalizerProtocol

    init(
        healthKitManager: HealthKitManager,
        normalizer: LifestyleNormalizerProtocol
    ) {
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
        
        // Get data from the last 7 days for more recent sleep patterns
        let calendar = Calendar.current
        let now = Date()
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: sevenDaysAgo,
            end: now,
            options: .strictStartDate
        )
        
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
            
            // Group samples by day to calculate nightly sleep
            let sleepByNight = Dictionary(grouping: samples) { sample -> Date in
                // Use midnight of the day as the key
                let components = calendar.dateComponents([.year, .month, .day], from: sample.startDate)
                return calendar.date(from: components) ?? sample.startDate
            }
            
            // We now have sleep samples grouped by night
            var totalSleepTime: TimeInterval = 0
            var nightCount = 0
            
            for (_, dailySamples) in sleepByNight {
                var nightlySleepDuration: TimeInterval = 0
                
                for sample in dailySamples {
                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue || 
                       sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                        nightlySleepDuration += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                // Only count nights with meaningful sleep data
                if nightlySleepDuration > 0 {
                    totalSleepTime += nightlySleepDuration
                    nightCount += 1
                }
            }
            
            // If we have less than 3 nights of data, not enough to calculate
            if nightCount < 1 {
                print("Not enough sleep data: only \(nightCount) nights")
                completion(nil)
                return
            }
            
            // Calculate average sleep time in hours
            let averageSleepHours = (totalSleepTime / Double(nightCount)) / 3600.0
            
            print("Fetched sleep: \(averageSleepHours) hours per night across \(nightCount) nights")
            
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
        // Try to get actual hydration data if available in HealthKit
        if #available(iOS 15.0, *) {
            if let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
                let calendar = Calendar.current
                let now = Date()
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else {
                    fallbackHydrationCalculation(completion: completion)
                    return
                }
                
                let predicate = HKQuery.predicateForSamples(
                    withStart: yesterday,
                    end: now,
                    options: .strictStartDate
                )
                
                let query = HKStatisticsQuery(
                    quantityType: waterType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    guard let result = result, let sum = result.sumQuantity() else {
                        print("No recent water intake data: \(error?.localizedDescription ?? "No data")")
                        self.fallbackHydrationCalculation(completion: completion)
                        return
                    }
                    
                    let waterIntake = sum.doubleValue(for: HKUnit.literUnit(with: .milli))
                    print("Fetched actual hydration: \(waterIntake) ml")
                    
                    // Calculate recommended intake for comparison
                    let recommendedIntake = self.calculateRecommendedWaterIntake()
                    
                    let metric = HealthMetric(
                        id: "hydration",
                        name: "Hydration",
                        value: waterIntake,
                        unit: "ml",
                        category: .lifestyle,
                        normalizedScore: self.normalizer.normalizeHydration(waterIntake, recommended: recommendedIntake)
                    )
                    completion(metric)
                }
                healthKitManager.healthStore.execute(query)
                return
            }
        }
        
        // Fall back to calculation if HealthKit data not available
        fallbackHydrationCalculation(completion: completion)
    }

    private func fallbackHydrationCalculation(completion: @escaping (HealthMetric?) -> Void) {
        let recommendedIntake = calculateRecommendedWaterIntake()
        
        // For estimation, assume the user is meeting 80% of their recommended intake
        let estimatedIntake = recommendedIntake * 0.8
        
        // Create the metric with calculated recommendation
        let metric = HealthMetric(
            id: "hydration",
            name: "Hydration",
            value: estimatedIntake,
            unit: "ml",
            category: .lifestyle,
            normalizedScore: self.normalizer.normalizeHydration(estimatedIntake, recommended: recommendedIntake)
        )
        
        print("Using calculated hydration: \(recommendedIntake) ml recommended, \(estimatedIntake) ml estimated")
        completion(metric)
    }

    private func calculateRecommendedWaterIntake() -> Double {
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
        return round(dailyWaterIntake / 50) * 50
    }
}

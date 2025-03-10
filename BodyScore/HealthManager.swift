import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    // Published properties for UI updates
    @Published var bodyScore: Double = 0
    @Published var confidenceScore: Double = 0
    @Published var metrics: [HealthMetric] = []
    @Published var isAuthorized: Bool = false
    
    // Category scores
    @Published var bodyCompositionScore: Double = 0
    @Published var fitnessScore: Double = 0
    @Published var heartvitalsScore: Double = 0
    @Published var metabolicScore: Double = 0
    @Published var lifestyleScore: Double = 0
    
    // User demographics
    @Published var userHeight: Double = 0 // in meters
    @Published var userGender: HKBiologicalSex = .notSet
    @Published var userAge: Int = 0
    
    // Computed property for formatted height
    var formattedHeight: String {
        if userHeight <= 0 {
            return "Not available"
        }
        
        let heightInCm = userHeight * 100
        return String(format: "%.0f cm", heightInCm)
    }
    
    // User preferences for metric weighting
    var userPreferences: UserPreferences = .defaultPreferences
    
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
    func requestAuthorization() {
        print("Requesting HealthKit authorization...")
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("HealthKit authorization granted")
                    self.isAuthorized = true
                    self.fetchUserDemographics()
                    self.fetchHealthData()
                } else if let error = error {
                    print("Authorization failed with error: \(error.localizedDescription)")
                } else {
                    print("Authorization denied without error")
                }
            }
        }
    }
    
    // Fetch all relevant health data
    func fetchHealthData() {
        fetchBodyCompositionData()
        fetchFitnessData()
        fetchHeartAndVitalsData()
        fetchMetabolicData()
        fetchLifestyleData()
        
        // Calculate overall body score after fetching all data
        calculateBodyScore()
    }
    
    // Fetch user demographics
    private func fetchUserDemographics() {
        fetchHeight()
        fetchBiologicalSex()
        fetchAge()
    }
    
    // MARK: - Demographic Data Fetchers
    
    private func fetchHeight() {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            print("Height type not available")
            return
        }
        
        // Get the most recent height measurement
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching height: \(error.localizedDescription)")
                return
            }
            
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                print("No height data found")
                return
            }
            
            let heightValue = sample.quantity.doubleValue(for: HKUnit.meter())
            print("Fetched height: \(heightValue) meters")
            
            DispatchQueue.main.async {
                self.userHeight = heightValue
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBiologicalSex() {
        do {
            let biologicalSex = try healthStore.biologicalSex()
            DispatchQueue.main.async {
                self.userGender = biologicalSex.biologicalSex
                print("Fetched biological sex: \(biologicalSex.biologicalSex.description)")
            }
        } catch {
            print("Error fetching biological sex: \(error.localizedDescription)")
        }
    }
    
    private func fetchAge() {
        do {
            let birthdayComponents = try healthStore.dateOfBirthComponents()
            let calendar = Calendar.current
            if let birthDate = calendar.date(from: birthdayComponents),
               let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year {
                DispatchQueue.main.async {
                    self.userAge = age
                    print("Fetched age: \(age) years")
                }
            } else {
                print("Could not calculate age from birth date components")
            }
        } catch {
            print("Error fetching date of birth: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Fetching Methods
    
    private func fetchBodyCompositionData() {
        let metrics = [
            fetchBodyFatPercentage,
            fetchLeanBodyMass,
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
            self.updateMetrics(bodyCompositionMetrics, category: .bodyComposition)
            self.calculateCategoryScore(for: .bodyComposition)
        }
    }
    
    private func fetchFitnessData() {
        let metrics = [
            fetchVO2Max,
            fetchStepCount,
            fetchActiveCalories,
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
            self.updateMetrics(fitnessMetrics, category: .fitness)
            self.calculateCategoryScore(for: .fitness)
        }
    }
    
    private func fetchHeartAndVitalsData() {
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
            self.updateMetrics(vitalsMetrics, category: .heartAndVitals)
            self.calculateCategoryScore(for: .heartAndVitals)
        }
    }
    
    private func fetchMetabolicData() {
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
            self.updateMetrics(metabolicMetrics, category: .metabolic)
            self.calculateCategoryScore(for: .metabolic)
        }
    }
    
    private func fetchLifestyleData() {
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
            self.updateMetrics(lifestyleMetrics, category: .lifestyle)
            self.calculateCategoryScore(for: .lifestyle)
        }
    }
    
    // MARK: - Individual Metric Fetchers
    
    private func fetchBodyFatPercentage(completion: @escaping (HealthMetric?) -> Void) {
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
            print("Body Fat Percentage type not available")
            completion(nil)
            return
        }
        
        // Use a longer time range to increase chance of finding data
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        // Sort by date to get the most recent value
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Query for the most recent sample
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
            
            let value = sample.quantity.doubleValue(for: HKUnit.percent()) // 0.262 for 26.2%
            print("Fetched body fat percentage: \(value)% (Date: \(sample.endDate))")
            
            let metric = HealthMetric(
                id: "bodyFat",
                name: "Body Fat Percentage", 
                value: value * 100.0,
                unit: "%", 
                category: .bodyComposition, 
                normalizedScore: self.normalizeBodyFat(value)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLeanBodyMass(completion: @escaping (HealthMetric?) -> Void) {
        guard let leanBodyMassType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) else {
            print("Lean Body Mass type not available")
            completion(nil)
            return
        }
        
        // Use a longer time range to increase chance of finding data
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        // Sort by date to get the most recent value
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Query for the most recent sample
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
                normalizedScore: self.normalizeLeanBodyMass(value)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBMI(completion: @escaping (HealthMetric?) -> Void) {
        guard let bmiType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else {
            print("BMI type not available")
            completion(nil)
            return
        }
        
        // Use a longer time range to increase chance of finding data
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .month, value: -3, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        // Sort by date to get the most recent value
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Query for the most recent sample
        let query = HKSampleQuery(
            sampleType: bmiType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching BMI: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                print("No BMI data found")
                completion(nil)
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
                normalizedScore: self.normalizeBMI(value)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchVO2Max(completion: @escaping (HealthMetric?) -> Void) {
        guard let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(quantityType: vo2MaxType,
                                     quantitySamplePredicate: createLastWeekPredicate(),
                                     options: .mostRecent) { _, result, error in
            
            guard error == nil, let result = result, let quantity = result.mostRecentQuantity() else {
                completion(nil)
                return
            }
            
            let value = quantity.doubleValue(for: HKUnit.init(from: "ml/kg*min"))
            let metric = HealthMetric(id: "vo2Max", name: "VO₂ Max", 
                                    value: value, unit: "ml/kg/min", 
                                    category: .fitness,
                                    normalizedScore: self.normalizeVO2Max(value))
            completion(metric)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchStepCount(completion: @escaping (HealthMetric?) -> Void) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -7, to: now)!)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
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
                normalizedScore: self.normalizeSteps(dailyAverage)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveCalories(completion: @escaping (HealthMetric?) -> Void) {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -7, to: now)!)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
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
                normalizedScore: self.normalizeActiveCalories(dailyAverage)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRestingHeartRate(completion: @escaping (HealthMetric?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(
            quantityType: heartRateType,
            quantitySamplePredicate: createLastWeekPredicate(),
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
                normalizedScore: self.normalizeRestingHeartRate(value)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
    }

    private func fetchHeartRateVariability(completion: @escaping (HealthMetric?) -> Void) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(
            quantityType: hrvType,
            quantitySamplePredicate: createLastWeekPredicate(),
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
                normalizedScore: self.normalizeHRV(value)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
    }

    private func fetchBloodOxygen(completion: @escaping (HealthMetric?) -> Void) {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(
            quantityType: oxygenType,
            quantitySamplePredicate: createLastWeekPredicate(),
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
                normalizedScore: self.normalizeBloodOxygen(value)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
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
            quantitySamplePredicate: createLastWeekPredicate(),
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
            quantitySamplePredicate: createLastWeekPredicate(),
            options: .discreteAverage
        ) { _, result, error in
            defer { group.leave() }
            
            guard error == nil, let result = result, let average = result.averageQuantity() else {
                print("Failed to fetch diastolic BP: \(error?.localizedDescription ?? "No data")")
                return
            }
            
            diastolic = average.doubleValue(for: HKUnit.millimeterOfMercury())
        }
        
        healthStore.execute(systolicQuery)
        healthStore.execute(diastolicQuery)
        
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
                normalizedScore: self.normalizeBloodPressure(systolic: systolic, diastolic: diastolic)
            )
            completion(metric)
        }
    }

    private func fetchBMR(completion: @escaping (HealthMetric?) -> Void) {
        guard let bmrType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
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
                normalizedScore: self.normalizeBMR(dailyAverage)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
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
            predicate: createLastWeekPredicate(),
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
                normalizedScore: self.normalizeGlucose(averageValue)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
    }

    private func fetchSleep(completion: @escaping (HealthMetric?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -7, to: now)!)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
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
                normalizedScore: self.normalizeSleep(averageSleepHours)
            )
            completion(metric)
        }
        
        healthStore.execute(query)
    }

    private func fetchHydration(completion: @escaping (HealthMetric?) -> Void) {
        // Apple HealthKit doesn't directly track hydration, so we need to use a different approach
        // We'll calculate a recommended daily water intake based on age, height, and optionally weight
        
        // Default recommended water intake for adults is around 2.7L for women and 3.7L for men
        // This includes water from all beverages and foods
        
        let baseRecommendation: Double
        var dailyWaterIntake: Double
        
        // Calculate based on gender, age and height
        switch userGender {
        case .female:
            baseRecommendation = 2700.0 // 2.7L in ml
        case .male:
            baseRecommendation = 3700.0 // 3.7L in ml
        default:
            baseRecommendation = 3200.0 // Average between male and female
        }
        
        // Age adjustment - younger people typically need relatively more water per kg of body weight
        // Older adults may need less but should still maintain adequate intake
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
        let heightAdjustment: Double
        if userHeight > 0 {
            // Reference heights: ~1.7m for women, ~1.8m for men
            let referenceHeight = (userGender == .female) ? 1.7 : 1.8
            heightAdjustment = userHeight / referenceHeight
        } else {
            heightAdjustment = 1.0 // Default if height unknown
        }
        
        // Calculate adjusted water intake recommendation
        dailyWaterIntake = baseRecommendation * ageAdjustment * heightAdjustment
        
        // Round to nearest 50ml for cleaner display
        dailyWaterIntake = round(dailyWaterIntake / 50) * 50
        
        // For now, we'll assume the user is meeting 80% of their recommended intake
        // In a real app, you could track this via manual entry or smart water bottles
        let estimatedIntake = dailyWaterIntake * 0.8
        
        // Create the metric with calculated recommendation
        let metric = HealthMetric(
            id: "hydration",
            name: "Hydration",
            value: estimatedIntake,
            unit: "ml",
            category: .lifestyle,
            normalizedScore: normalizeHydration(estimatedIntake, recommended: dailyWaterIntake)
        )
        
        print("Calculated hydration recommendation: \(dailyWaterIntake) ml, estimated intake: \(estimatedIntake) ml")
        completion(metric)
    }
    
    private func normalizeHydration(_ intake: Double, recommended: Double) -> Double {
        // Calculate score based on percentage of recommended intake
        let percentage = intake / recommended
        
        if percentage < 0.5 {
            return 0.3 // Severely under-hydrated
        } else if percentage < 0.7 {
            return 0.5 // Somewhat under-hydrated
        } else if percentage < 0.9 {
            return 0.7 // Slightly under-hydrated
        } else if percentage <= 1.1 {
            return 1.0 // Optimal hydration
        } else if percentage <= 1.3 {
            return 0.9 // Slightly over-hydrated
        } else {
            return 0.8 // Significantly over-hydrated
        }
    }

    // MARK: - Helper Methods
    
    private func createLastWeekPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        return HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
    }
    
    private func updateMetrics(_ newMetrics: [HealthMetric], category: HealthMetricCategory) {
        // Remove existing metrics of this category
        metrics.removeAll { $0.category == category }
        // Add new metrics
        metrics.append(contentsOf: newMetrics)
    }
    
    // MARK: - Score Calculation Methods
    
    private func calculateCategoryScore(for category: HealthMetricCategory) {
        let categoryMetrics = metrics.filter { $0.category == category }
        let totalWeight = userPreferences.categoryWeights[category] ?? 1.0
        
        if categoryMetrics.isEmpty {
            // No data for this category
            switch category {
            case .bodyComposition:
                bodyCompositionScore = 0
            case .fitness:
                fitnessScore = 0
            case .heartAndVitals:
                heartvitalsScore = 0
            case .metabolic:
                metabolicScore = 0
            case .lifestyle:
                lifestyleScore = 0
            }
            return
        }
        
        let categoryScore = categoryMetrics.reduce(0.0) { sum, metric in
            return sum + metric.normalizedScore
        } / Double(categoryMetrics.count) * 100.0
        
        // Update the appropriate category score
        switch category {
        case .bodyComposition:
            bodyCompositionScore = categoryScore * totalWeight
        case .fitness:
            fitnessScore = categoryScore * totalWeight
        case .heartAndVitals:
            heartvitalsScore = categoryScore * totalWeight
        case .metabolic:
            metabolicScore = categoryScore * totalWeight
        case .lifestyle:
            lifestyleScore = categoryScore * totalWeight
        }
        
        // Recalculate overall score
        calculateBodyScore()
    }
    
    func calculateBodyScore() {
        var totalScore = 0.0
        var availableWeight = 0.0
        
        // Get available categories
        let availableCategories = Set(metrics.map { $0.category })
        
        // Calculate total available weight
        for (category, weight) in userPreferences.categoryWeights {
            if availableCategories.contains(category) {
                availableWeight += weight
            }
        }
        
        // If no data is available at all
        if availableWeight == 0 {
            bodyScore = 0
            confidenceScore = 0
            return
        }
        
        // Calculate weighted score for each category
        if availableCategories.contains(.bodyComposition) {
            let weight = userPreferences.categoryWeights[.bodyComposition] ?? 1.0
            totalScore += (bodyCompositionScore * weight) / availableWeight
        }
        
        if availableCategories.contains(.fitness) {
            let weight = userPreferences.categoryWeights[.fitness] ?? 1.0
            totalScore += (fitnessScore * weight) / availableWeight
        }
        
        if availableCategories.contains(.heartAndVitals) {
            let weight = userPreferences.categoryWeights[.heartAndVitals] ?? 1.0
            totalScore += (heartvitalsScore * weight) / availableWeight
        }
        
        if availableCategories.contains(.metabolic) {
            let weight = userPreferences.categoryWeights[.metabolic] ?? 1.0
            totalScore += (metabolicScore * weight) / availableWeight
        }
        
        if availableCategories.contains(.lifestyle) {
            let weight = userPreferences.categoryWeights[.lifestyle] ?? 1.0
            totalScore += (lifestyleScore * weight) / availableWeight
        }
        
        // Calculate confidence score based on available data
        let totalPossibleWeight = userPreferences.categoryWeights.values.reduce(0, +)
        confidenceScore = (availableWeight / totalPossibleWeight) * 100.0
        
        // Update the overall body score
        bodyScore = totalScore
        
        // Save the score record
        saveScoreRecord()
    }
    
    private func saveScoreRecord() {
        let record = ScoreRecord(
            date: Date(),
            bodyScore: bodyScore,
            confidenceScore: confidenceScore,
            bodyCompositionScore: bodyCompositionScore,
            fitnessScore: fitnessScore,
            heartVitalsScore: heartvitalsScore,
            metabolicScore: metabolicScore,
            lifestyleScore: lifestyleScore
        )
        
        // Use ScoreRecordStore to save the record (will be implemented in ScoreRecord.swift)
        ScoreRecordStore.shared.saveRecord(record)
    }
    
    // MARK: - Normalization Methods (0-1 scale)
    
    private func normalizeBodyFat(_ percent: Double) -> Double {
        // Example normalization (would be adjusted based on gender and age)
        // For men: 10-20% is ideal, >25% is poor
        // For women: 18-28% is ideal, >32% is poor
      let value = percent * 100.0
        // This is a simplified version, would need gender/age adjustment
        if value < 10 {
            return 0.0  // Too low is not ideal
        } else if value < 15 {
            return 1.0  // Ideal for athletes
        } else if value < 20 {
            return 0.9  // Good for men
        } else if value < 25 {
            return 0.8  // Acceptable for men, good for women
        } else if value < 30 {
            return 0.6  // Acceptable for women
        } else {
            return max(0.0, 1 - ((value - 30) / 20))  // Gradually decrease score
        }
    }
    
    private func normalizeLeanBodyMass(_ value: Double) -> Double {
        // Default score if we can't calculate properly
        if userHeight <= 0 || userAge <= 0 {
            return 0.8
        }
        
        // Calculate Fat Free Mass Index (FFMI)
        // FFMI = LBM (kg) / height (m)^2
        let ffmi = value / (userHeight * userHeight)
        
        // FFMI interpretation based on gender
        // These ranges are approximations and could be refined further
        switch userGender {
        case .female:
            if ffmi < 14 {
                return 0.3  // Very low FFMI for females
            } else if ffmi < 16 {
                return 0.6  // Low but acceptable
            } else if ffmi < 18 {
                return 0.8  // Good
            } else if ffmi < 20 {
                return 1.0  // Excellent
            } else if ffmi < 22 {
                return 0.9  // Very athletic/muscular
            } else {
                return 0.8  // Potentially very muscular or measurement error
            }
            
        case .male:
            if ffmi < 17 {
                return 0.3  // Very low FFMI for males
            } else if ffmi < 19 {
                return 0.6  // Low but acceptable
            } else if ffmi < 21 {
                return 0.8  // Good
            } else if ffmi < 23 {
                return 1.0  // Excellent
            } else if ffmi < 25 {
                return 0.9  // Very athletic/muscular
            } else {
                return 0.8  // Potentially very muscular or measurement error
            }
            
        default:
            // For unknown gender, use a generic scale
            if ffmi < 16 {
                return 0.3  // Very low
            } else if ffmi < 18 {
                return 0.6  // Low
            } else if ffmi < 20 {
                return 0.8  // Good
            } else if ffmi < 22 {
                return 1.0  // Excellent
            } else {
                return 0.9  // Very muscular
            }
        }
    }
    
    private func normalizeBMI(_ value: Double) -> Double {
        // BMI normalization: 18.5-24.9 is considered normal
        if value < 16 {
            return 0.3  // Severely underweight
        } else if value < 18.5 {
            return 0.7  // Underweight
        } else if value <= 24.9 {
            return 1.0  // Normal
        } else if value <= 29.9 {
            return 0.7  // Overweight
        } else if value <= 34.9 {
            return 0.5  // Obese Class I
        } else if value <= 39.9 {
            return 0.3  // Obese Class II
        } else {
            return 0.1  // Obese Class III
        }
    }
    
    private func normalizeVO2Max(_ value: Double) -> Double {
        // VO2 Max normalization (would be adjusted by age and gender)
        // This is a simplified version
        if value < 30 {
            return max(0.1, value / 30)  // Poor
        } else if value < 40 {
            return 0.6 + (value - 30) / 25  // Fair to Good
        } else if value < 50 {
            return 0.8 + (value - 40) / 50  // Good to Excellent
        } else {
            return 1.0  // Excellent
        }
    }
    
    private func normalizeSteps(_ value: Double) -> Double {
        // 10,000 steps is often considered a good target
        if value < 1000 {
            return 0.1
        } else if value < 5000 {
            return 0.3 + (value - 1000) / (4000 * 2)
        } else if value < 10000 {
            return 0.6 + (value - 5000) / (5000 * 1.3)
        } else if value < 15000 {
            return 0.9 + (value - 10000) / 5000
        } else {
            return 1.0
        }
    }
    
    private func normalizeActiveCalories(_ value: Double) -> Double {
        // Target varies by gender, weight, age, but ~400-500 for women, ~500-600 for men is decent
        if value < 100 {
            return 0.1
        } else if value < 300 {
            return 0.3 + (value - 100) / 400
        } else if value < 500 {
            return 0.6 + (value - 300) / 500
        } else if value < 800 {
            return 0.8 + (value - 500) / 1500
        } else {
            return 1.0
        }
    }
    
    private func normalizeRestingHeartRate(_ value: Double) -> Double {
        // Lower is generally better, but too low can also be problematic
        if value < 40 {
            return 0.7  // Unusually low, potentially concerning
        } else if value < 50 {
            return 1.0  // Excellent, athletic
        } else if value < 60 {
            return 0.9  // Very good
        } else if value < 70 {
            return 0.8  // Good
        } else if value < 80 {
            return 0.6  // Average
        } else if value < 90 {
            return 0.4  // Elevated
        } else {
            return max(0.1, 0.4 - (value - 90) / 100)  // High, concerning
        }
    }

    private func normalizeHRV(_ value: Double) -> Double {
        // Higher HRV is generally better
        if value < 20 {
            return 0.3
        } else if value < 40 {
            return 0.5
        } else if value < 60 {
            return 0.7
        } else if value < 80 {
            return 0.85
        } else if value < 100 {
            return 0.95
        } else {
            return 1.0
        }
    }

    private func normalizeBloodOxygen(_ value: Double) -> Double {
        // 95-100% is normal
        if value < 90 {
            return 0.3  // Very low, concerning
        } else if value < 95 {
            return 0.6  // Low
        } else if value < 98 {
            return 0.85  // Good
        } else {
            return 1.0  // Excellent
        }
    }

    private func normalizeBloodPressure(systolic: Double, diastolic: Double) -> Double {
        // Based on standard BP categories
        if systolic < 90 || diastolic < 60 {
            return 0.4  // Low blood pressure
        } else if systolic < 120 && diastolic < 80 {
            return 1.0  // Normal blood pressure
        } else if systolic < 130 && diastolic < 80 {
            return 0.8  // Elevated
        } else if systolic < 140 || diastolic < 90 {
            return 0.6  // Stage 1 hypertension
        } else if systolic < 180 || diastolic < 120 {
            return 0.3  // Stage 2 hypertension
        } else {
            return 0.1  // Hypertensive crisis
        }
    }

    private func normalizeBMR(_ value: Double) -> Double {
        // This would need customization based on age, gender, weight, etc.
        // Simplified implementation
        if value < 1000 {
            return 0.5  // Low
        } else if value < 1400 {
            return 0.7  // Below average
        } else if value < 1800 {
            return 0.9  // Average to good
        } else {
            return 1.0  // High (could be good for active people)
        }
    }

    private func normalizeGlucose(_ value: Double) -> Double {
        // Based on general guidelines for blood glucose (mg/dL)
        if value < 70 {
            return 0.4  // Too low (hypoglycemia)
        } else if value < 100 {
            return 1.0  // Ideal fasting
        } else if value < 125 {
            return 0.8  // Normal to prediabetic
        } else if value < 180 {
            return 0.5  // High (diabetic range)
        } else {
            return 0.2  // Very high
        }
    }

    private func normalizeSleep(_ hours: Double) -> Double {
        // 7-9 hours generally recommended for adults
        if hours < 5 {
            return 0.2  // Very insufficient
        } else if hours < 6 {
            return 0.4  // Insufficient
        } else if hours < 7 {
            return 0.7  // Slightly under
        } else if hours <= 9 {
            return 1.0  // Optimal
        } else if hours <= 10 {
            return 0.8  // Slightly over
        } else {
            return 0.6  // Too much
        }
    }
}

// MARK: - Support Models

enum HealthMetricCategory: String, CaseIterable, Identifiable {
    case bodyComposition = "Body Composition"
    case fitness = "Fitness & Activity"
    case heartAndVitals = "Heart & Vitals"
    case metabolic = "Metabolic Health"
    case lifestyle = "Lifestyle"
    
    var id: String { self.rawValue }
}
struct HealthMetric: Identifiable {
    let id: String
    let name: String
    let value: Double
    let unit: String
    let category: HealthMetricCategory
    let normalizedScore: Double  // 0-1 score
}
struct UserPreferences {
    var categoryWeights: [HealthMetricCategory: Double]
    
    static var defaultPreferences: UserPreferences {
        return UserPreferences(
            categoryWeights: [
                .bodyComposition: 1.0,
                .fitness: 1.0,
                .heartAndVitals: 1.0,
                .metabolic: 0.8,
                .lifestyle: 0.5
            ]
        )
    }
    
    mutating func updateWeight(for category: HealthMetricCategory, weight: Double) {
        categoryWeights[category] = max(0, min(2, weight))  // Limit weights between 0-2
    }
    
    // Create a preference profile focusing on weight loss
    static var weightLossProfile: UserPreferences {
        return UserPreferences(
            categoryWeights: [
                .bodyComposition: 2.0,
                .fitness: 1.5,
                .heartAndVitals: 0.8,
                .metabolic: 1.2,
                .lifestyle: 0.6
            ]
        )
    }
    
    // Create a preference profile focusing on fitness
    static var fitnessProfile: UserPreferences {
        return UserPreferences(
            categoryWeights: [
                .bodyComposition: 0.8,
                .fitness: 2.0,
                .heartAndVitals: 1.2,
                .metabolic: 0.8,
                .lifestyle: 0.8
            ]
        )
    }
    
    // Create a preference profile focusing on heart health
    static var heartHealthProfile: UserPreferences {
        return UserPreferences(
            categoryWeights: [
                .bodyComposition: 0.8,
                .fitness: 1.0,
                .heartAndVitals: 2.0,
                .metabolic: 1.0,
                .lifestyle: 1.0
            ]
        )
    }
}

// Extension to make HKBiologicalSex more readable
extension HKBiologicalSex {
    var description: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        case .other: return "Other"
        default: return "Not Set"
        }
    }
}

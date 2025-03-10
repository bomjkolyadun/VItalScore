import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    // Core components
    private let healthKitManager = HealthKitManager()
    private let userProfile = HealthUserProfile()
    private lazy var metricNormalizer = MetricNormalizer(userProfile: userProfile)
    
    // Fetcher components
    private lazy var bodyCompositionFetcher = BodyCompositionFetcher(
        healthKitManager: healthKitManager, 
        normalizer: metricNormalizer
    )
    private lazy var fitnessFetcher = FitnessFetcher(
        healthKitManager: healthKitManager, 
        normalizer: metricNormalizer
    )
    private lazy var heartVitalsFetcher = HeartVitalsFetcher(
        healthKitManager: healthKitManager,
        normalizer: metricNormalizer
    )
    private lazy var metabolicFetcher = MetabolicFetcher(
        healthKitManager: healthKitManager,
        normalizer: metricNormalizer
    )
    private lazy var lifestyleFetcher = LifestyleFetcher(
        healthKitManager: healthKitManager,
        normalizer: metricNormalizer
    )
    
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
    
    // User preferences for metric weighting
    var userPreferences: UserPreferences = .defaultPreferences
    
    // Computed property for formatted height
    var formattedHeight: String {
        return userProfile.formattedHeight
    }

    var userAge: String {
        return "\(userProfile.userAge)"
    }
    
    init() {
        // HealthKit availability is checked in HealthKitManager
    }
    
    // Request authorization to access HealthKit data
    func requestAuthorization() {
        healthKitManager.requestAuthorization { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.userProfile.fetchUserDemographics(from: self.healthKitManager.healthStore) {
                        self.fetchHealthData()
                    }
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
    
    // Methods to fetch each category of data
    private func fetchBodyCompositionData() {
        bodyCompositionFetcher.fetchMetrics { metrics in
            self.updateMetrics(metrics, category: .bodyComposition)
            self.calculateCategoryScore(for: .bodyComposition)
        }
    }
    
    private func fetchFitnessData() {
        fitnessFetcher.fetchMetrics { metrics in
            self.updateMetrics(metrics, category: .fitness)
            self.calculateCategoryScore(for: .fitness)
        }
    }
    
    private func fetchHeartAndVitalsData() {
        heartVitalsFetcher.fetchMetrics { metrics in
            self.updateMetrics(metrics, category: .heartAndVitals)
            self.calculateCategoryScore(for: .heartAndVitals)
        }
    }
    
    private func fetchMetabolicData() {
        metabolicFetcher.fetchMetrics { metrics in
            self.updateMetrics(metrics, category: .metabolic)
            self.calculateCategoryScore(for: .metabolic)
        }
    }
    
    private func fetchLifestyleData() {
        lifestyleFetcher.fetchMetrics { metrics in
            self.updateMetrics(metrics, category: .lifestyle)
            self.calculateCategoryScore(for: .lifestyle)
        }
    }
    
    private func updateMetrics(_ newMetrics: [HealthMetric], category: HealthMetricCategory) {
        // Remove existing metrics of this category
        metrics.removeAll { $0.category == category }
        // Add new metrics
        metrics.append(contentsOf: newMetrics)
    }
    
    private func calculateCategoryScore(for category: HealthMetricCategory) {
        let categoryMetrics = metrics.filter { $0.category == category }
        let totalWeight = userPreferences.categoryWeights[category] ?? 1.0
        
        print("Calculating score for \(category): found \(categoryMetrics.count) metrics")
        
        if categoryMetrics.isEmpty {
            // No data for this category
            print("⚠️ No metrics found for category: \(category)")
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
        
        // Log the metrics we found
        for metric in categoryMetrics {
            print("📊 Metric: \(metric.name), Value: \(metric.value), Score: \(metric.normalizedScore)")
        }
        
        let categoryScore = categoryMetrics.reduce(0.0) { sum, metric in
            return sum + metric.normalizedScore
        } / Double(categoryMetrics.count) * 100.0
        
        // Update the appropriate category score
        switch category {
        case .bodyComposition:
            bodyCompositionScore = categoryScore * totalWeight
            print("Body composition score calculated: \(bodyCompositionScore)")
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
        
        // Use ScoreRecordStore to save the record
        ScoreRecordStore.shared.saveRecord(record)
    }
    
    // Debug function to check data fetching status
    func debugFetchStatus() {
        print("--- HEALTH DATA FETCH STATUS ---")
        print("Total metrics: \(metrics.count)")
        print("Body Composition: \(metrics.filter { $0.category == .bodyComposition }.count) metrics")
        print("Fitness: \(metrics.filter { $0.category == .fitness }.count) metrics")
        print("Heart & Vitals: \(metrics.filter { $0.category == .heartAndVitals }.count} metrics")
        print("Metabolic: \(metrics.filter { $0.category == .metabolic }.count} metrics")
        print("Lifestyle: \(metrics.filter { $0.category == .lifestyle }.count} metrics")
        print("------------------------------")
    }
}

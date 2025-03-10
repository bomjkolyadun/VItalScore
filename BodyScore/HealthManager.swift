import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    // Core components
    private let healthKitManager = HealthKitManager()
    private let userProfile = HealthUserProfile()
    private lazy var normalizerProvider = NormalizerProvider(userProfile: userProfile)
    
    // Fetcher components
    private lazy var bodyCompositionFetcher = BodyCompositionFetcher(
        healthKitManager: healthKitManager,
 
        normalizer: normalizerProvider
            .getNormalizer(
                for: .bodyComposition
            ) as! BodyCompositionNormalizerProtocol
    )
    private lazy var fitnessFetcher = FitnessFetcher(
        healthKitManager: healthKitManager, 
        normalizer: normalizerProvider
            .getNormalizer(for: .fitness) as! FitnessNormalizerProtocol
    )
    private lazy var heartVitalsFetcher = HeartVitalsFetcher(
        healthKitManager: healthKitManager,
        normalizer: normalizerProvider
            .getNormalizer(for: .heartAndVitals) as! VitalsNormalizerProtocol
    )
    private lazy var metabolicFetcher = MetabolicFetcher(
        healthKitManager: healthKitManager,
        normalizer: normalizerProvider
            .getNormalizer(for: .metabolic) as! MetabolicNormalizerProtocol
    )
    private lazy var lifestyleFetcher = LifestyleFetcher(
        healthKitManager: healthKitManager,
        normalizer: normalizerProvider
            .getNormalizer(for: .lifestyle) as! LifestyleNormalizerProtocol
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
        // Use the new BodyScoreCalculator for computing the score
        let result = BodyScoreCalculator.calculateBodyScore(
            from: metrics,
            with: userPreferences
        )
        
        // Update the overall body score and confidence score
        bodyScore = result.bodyScore
        confidenceScore = result.confidenceScore
        
        // Update individual category scores
        if let score = result.categoryScores[.bodyComposition] {
            bodyCompositionScore = score
        }
        
        if let score = result.categoryScores[.fitness] {
            fitnessScore = score
        }
        
        if let score = result.categoryScores[.heartAndVitals] {
            heartvitalsScore = score
        }
        
        if let score = result.categoryScores[.metabolic] {
            metabolicScore = score
        }
        
        if let score = result.categoryScores[.lifestyle] {
            lifestyleScore = score
        }
        
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
}

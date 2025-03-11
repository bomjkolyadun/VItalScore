import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    // Core components
    private let healthKitManager: HealthKitManager
    private let userProfile: HealthUserProfile
    private let normalizerProvider: NormalizerProvider

    // Dictionary to store fetchers by category
    private var fetchers: [HealthMetricCategory: HealthMetricFetcherProtocol]
    
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
    
    init(
        healthKitManager: HealthKitManager = HealthKitManager(),
        userProfile: HealthUserProfile = HealthUserProfile(),
        fetchers: [HealthMetricCategory: HealthMetricFetcherProtocol] = [:]
    ) {
        self.healthKitManager = healthKitManager
        self.userProfile = userProfile
        self.normalizerProvider = NormalizerProvider(userProfile: userProfile)
        self.fetchers = fetchers
        
        // If no fetchers provided, initialize with default fetchers
        if fetchers.isEmpty {
            self.fetchers = [
                .bodyComposition: BodyCompositionFetcher(
                    healthKitManager: healthKitManager,
                    normalizer: normalizerProvider.getNormalizer(for: .bodyComposition) as! BodyCompositionNormalizerProtocol
                ),
                .fitness: FitnessFetcher(
                    healthKitManager: healthKitManager,
                    normalizer: normalizerProvider.getNormalizer(for: .fitness) as! FitnessNormalizerProtocol
                ),
                .heartAndVitals: HeartVitalsFetcher(
                    healthKitManager: healthKitManager,
                    normalizer: normalizerProvider.getNormalizer(for: .heartAndVitals) as! VitalsNormalizerProtocol
                ),
                .metabolic: MetabolicFetcher(
                    healthKitManager: healthKitManager,
                    normalizer: normalizerProvider.getNormalizer(for: .metabolic) as! MetabolicNormalizerProtocol
                ),
                .lifestyle: LifestyleFetcher(
                    healthKitManager: healthKitManager,
                    normalizer: normalizerProvider.getNormalizer(for: .lifestyle) as! LifestyleNormalizerProtocol
                )
            ]
        }
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
    
    // Unified method to fetch all relevant health data
    func fetchHealthData() {
        let dispatchGroup = DispatchGroup()
        
        // Call fetch on each available fetcher
        for (category, fetcher) in fetchers {
            dispatchGroup.enter()
            fetcher.fetchMetrics { metrics in
                self.updateMetrics(metrics, category: category)
                self.calculateCategoryScore(for: category)
                dispatchGroup.leave()
            }
        }
        
        // Calculate overall body score after all fetchers complete
        dispatchGroup.notify(queue: .main) {
            self.calculateBodyScore()
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

import Foundation

class BodyScoreCalculator {
    
    // MARK: - Body Score Formula Components
    
    /**
     Main method to calculate holistic body score from normalized health metrics.
     
     Formula:
     BodyScore = ∑(Category_i × Weight_i) / ∑(Available_Weights)
     
     Where:
     - Category_i: Average score for each health category (0-100)
     - Weight_i: Importance weight for each category
     - Available_Weights: Sum of weights for available categories
     
     @param metrics Array of available health metrics
     @param preferences User preferences for category weighting
     @return Tuple containing (bodyScore, confidenceScore)
     */
    static func calculateBodyScore(
        from metrics: [HealthMetric],
        with preferences: UserPreferences
    ) -> (bodyScore: Double, confidenceScore: Double, categoryScores: [HealthMetricCategory: Double]) {
        
        var categoryScores: [HealthMetricCategory: Double] = [:]
        var categoryMetricCounts: [HealthMetricCategory: Int] = [:]
        var availableWeight = 0.0
        var totalScore = 0.0
        
        // 1. Calculate scores for each category separately
        for category in HealthMetricCategory.allCases {
            let categoryMetrics = metrics.filter { $0.category == category }
            categoryMetricCounts[category] = categoryMetrics.count

            if !categoryMetrics.isEmpty {
                let categoryAverage = categoryMetrics.reduce(0.0) { sum, metric in
                    print("metric", metric.name, metric.normalizedScore)
                    return sum + metric.normalizedScore
                } / Double(categoryMetrics.count)

                let categoryScore = categoryAverage * 100.0
                let weight = preferences.categoryWeights[category] ?? 1.0

                print("Category: \(category), Score: \(categoryScore), Weight: \(weight)")

                availableWeight += weight
                categoryScores[category] = categoryScore
                totalScore += categoryScore * weight
            }
        }
        
        // 2. Calculate confidence score based on data availability
        var confidenceScore = 0.0
        let totalPossibleWeight = preferences.categoryWeights.values.reduce(0, +)
        
        if totalPossibleWeight > 0 {
            confidenceScore = (availableWeight / totalPossibleWeight) * 100.0
            
            // Adjust confidence based on number of metrics in each category
            let idealMetricsPerCategory = [
                HealthMetricCategory.bodyComposition: 3.0,
                HealthMetricCategory.fitness: 3.0,
                HealthMetricCategory.heartAndVitals: 4.0,
                HealthMetricCategory.metabolic: 2.0,
                HealthMetricCategory.lifestyle: 2.0
            ]
            
            var metricCompleteness = 0.0
            var totalIdealMetrics = 0.0
            
            for (category, idealCount) in idealMetricsPerCategory {
                let actualCount = Double(categoryMetricCounts[category] ?? 0)
                if actualCount > 0 {
                    metricCompleteness += min(actualCount / idealCount, 1.0) * (preferences.categoryWeights[category] ?? 1.0)
                }
                totalIdealMetrics += preferences.categoryWeights[category] ?? 1.0
            }
            
            let completenessRatio = totalIdealMetrics > 0 ? metricCompleteness / totalIdealMetrics : 0
            
            // Final confidence is a weighted combination of category presence and metric completeness
            confidenceScore = confidenceScore * 0.7 + completenessRatio * 30.0
        }
        
        // 3. Calculate final body score
        var bodyScore = 0.0
        
        if availableWeight > 0 {
            // Calculate weighted average of category scores
            bodyScore = totalScore / availableWeight
        }
        
        return (bodyScore, confidenceScore, categoryScores)
    }
    
    /**
     Calculates the individual category scores from available metrics
     
     Formula for each category:
     CategoryScore = ∑(Metric_NormalizedScores) / Number_of_Metrics × 100
     
     @param metrics Array of available health metrics
     @return Dictionary mapping categories to their scores (0-100)
     */
    static func calculateCategoryScores(from metrics: [HealthMetric]) -> [HealthMetricCategory: Double] {
        var categoryScores: [HealthMetricCategory: Double] = [:]
        
        for category in HealthMetricCategory.allCases {
            let categoryMetrics = metrics.filter { $0.category == category }
            
            if !categoryMetrics.isEmpty {
                let categoryAverage = categoryMetrics.reduce(0.0) { sum, metric in
                    return sum + metric.normalizedScore
                } / Double(categoryMetrics.count)
                
                categoryScores[category] = categoryAverage * 100.0
            }
        }
        
        return categoryScores
    }
    
    /**
     Calculate a data quality confidence score based on metric availability
     
     Formula:
     Confidence = (Available_Categories / Total_Categories) × 
                  (Available_Metrics / Ideal_Metrics_Count) × 100
     
     @param metrics Array of available health metrics
     @return Confidence score (0-100)
     */
    static func calculateConfidenceScore(from metrics: [HealthMetric]) -> Double {
        let availableCategories = Set(metrics.map { $0.category })
        let totalCategories = HealthMetricCategory.allCases.count
        
        // Category coverage (what proportion of categories have at least some data)
        let categoryCoverage = Double(availableCategories.count) / Double(totalCategories)
        
        // Metric density (how many metrics we have compared to ideal)
        let idealMetricCount = 14.0 // Based on our core metrics definition
        let metricDensity = min(Double(metrics.count) / idealMetricCount, 1.0)
        
        // Combined confidence score
        let confidence = (categoryCoverage * 0.7 + metricDensity * 0.3) * 100.0
        
        return confidence
    }
}

import Foundation

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

import Foundation

struct HealthMetric: Identifiable {
    let id: String
    let name: String
    let value: Double
    let unit: String
    let category: HealthMetricCategory
    let normalizedScore: Double  // 0-1 score
}

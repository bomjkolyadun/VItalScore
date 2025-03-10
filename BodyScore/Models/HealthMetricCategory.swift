import Foundation

enum HealthMetricCategory: String, CaseIterable, Identifiable {
    case bodyComposition = "Body Composition"
    case fitness = "Fitness & Activity"
    case heartAndVitals = "Heart & Vitals"
    case metabolic = "Metabolic Health"
    case lifestyle = "Lifestyle"
    
    var id: String { self.rawValue }
}

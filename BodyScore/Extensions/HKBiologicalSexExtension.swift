import HealthKit

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

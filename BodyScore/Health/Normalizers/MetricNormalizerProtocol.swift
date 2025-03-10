import Foundation

/// Base protocol for all metric normalizers
protocol MetricNormalizerProtocol {
    var userProfile: HealthUserProfile { get }
    init(userProfile: HealthUserProfile)
}

/// Protocol for body composition normalizers
protocol BodyCompositionNormalizerProtocol: MetricNormalizerProtocol {
    func normalizeBodyFat(_ percent: Double) -> Double
    func normalizeLeanBodyMass(_ value: Double) -> Double
    func normalizeBMI(_ value: Double) -> Double
}

/// Protocol for fitness normalizers
protocol FitnessNormalizerProtocol: MetricNormalizerProtocol {
    func normalizeVO2Max(_ value: Double) -> Double
    func normalizeSteps(_ value: Double) -> Double
    func normalizeActiveCalories(_ value: Double) -> Double
}

/// Protocol for vitals normalizers
protocol VitalsNormalizerProtocol: MetricNormalizerProtocol {
    func normalizeRestingHeartRate(_ value: Double) -> Double
    func normalizeHRV(_ value: Double) -> Double
    func normalizeBloodOxygen(_ value: Double) -> Double
    func normalizeBloodPressure(systolic: Double, diastolic: Double) -> Double
}

/// Protocol for metabolic normalizers
protocol MetabolicNormalizerProtocol: MetricNormalizerProtocol {
    func normalizeBMR(_ value: Double) -> Double
    func normalizeGlucose(_ value: Double) -> Double
}

/// Protocol for lifestyle normalizers
protocol LifestyleNormalizerProtocol: MetricNormalizerProtocol {
    func normalizeSleep(_ hours: Double) -> Double
    func normalizeHydration(_ intake: Double, recommended: Double) -> Double
}

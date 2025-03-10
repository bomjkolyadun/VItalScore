import Foundation

/// A provider class to get the appropriate normalizer for a metric category
class NormalizerProvider {
    private let userProfile: HealthUserProfile
    
    // Lazy initialization for normalizers
    private lazy var bodyCompositionNormalizer = BodyCompositionNormalizer(userProfile: userProfile)
    private lazy var fitnessNormalizer = FitnessNormalizer(userProfile: userProfile)
    private lazy var vitalsNormalizer = VitalsNormalizer(userProfile: userProfile)
    private lazy var metabolicNormalizer = MetabolicNormalizer(userProfile: userProfile)
    private lazy var lifestyleNormalizer = LifestyleNormalizer(userProfile: userProfile)
    
    init(userProfile: HealthUserProfile) {
        self.userProfile = userProfile
    }
    
    func getNormalizer(for category: HealthMetricCategory) -> MetricNormalizerProtocol {
        switch category {
        case .bodyComposition:
            return bodyCompositionNormalizer
        case .fitness:
            return fitnessNormalizer
        case .heartAndVitals:
            return vitalsNormalizer
        case .metabolic:
            return metabolicNormalizer
        case .lifestyle:
            return lifestyleNormalizer
        }
    }
}

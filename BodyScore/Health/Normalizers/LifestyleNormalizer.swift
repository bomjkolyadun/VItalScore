import Foundation

class LifestyleNormalizer: LifestyleNormalizerProtocol {
    let userProfile: HealthUserProfile
    
    required init(userProfile: HealthUserProfile) {
        self.userProfile = userProfile
    }
    
    func normalizeSleep(_ hours: Double) -> Double {
        // 7-9 hours generally recommended for adults
        if hours < 5 {
            return 0.2  // Very insufficient
        } else if hours < 6 {
            return 0.4  // Insufficient
        } else if hours < 7 {
            return 0.7  // Slightly under
        } else if hours <= 9 {
            return 1.0  // Optimal
        } else if hours <= 10 {
            return 0.8  // Slightly over
        } else {
            return 0.6  // Too much
        }
    }
    
    func normalizeHydration(_ intake: Double, recommended: Double) -> Double {
        // Calculate score based on percentage of recommended intake
        let percentage = intake / recommended
        
        if percentage < 0.5 {
            return 0.3 // Severely under-hydrated
        } else if percentage < 0.7 {
            return 0.5 // Somewhat under-hydrated
        } else if percentage < 0.9 {
            return 0.7 // Slightly under-hydrated
        } else if percentage <= 1.1 {
            return 1.0 // Optimal hydration
        } else if percentage <= 1.3 {
            return 0.9 // Slightly over-hydrated
        } else {
            return 0.8 // Significantly over-hydrated
        }
    }
}

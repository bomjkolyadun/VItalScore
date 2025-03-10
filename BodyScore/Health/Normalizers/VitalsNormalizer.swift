import Foundation

class VitalsNormalizer: VitalsNormalizerProtocol {
    let userProfile: HealthUserProfile
    
    required init(userProfile: HealthUserProfile) {
        self.userProfile = userProfile
    }
    
    func normalizeRestingHeartRate(_ value: Double) -> Double {
        // Lower is generally better, but too low can also be problematic
        if value < 40 {
            return 0.7  // Unusually low, potentially concerning
        } else if value < 50 {
            return 1.0  // Excellent, athletic
        } else if value < 60 {
            return 0.9  // Very good
        } else if value < 70 {
            return 0.8  // Good
        } else if value < 80 {
            return 0.6  // Average
        } else if value < 90 {
            return 0.4  // Elevated
        } else {
            return max(0.1, 0.4 - (value - 90) / 100)  // High, concerning
        }
    }

    func normalizeHRV(_ value: Double) -> Double {
        // Higher HRV is generally better
        if value < 20 {
            return 0.3
        } else if value < 40 {
            return 0.5
        } else if value < 60 {
            return 0.7
        } else if value < 80 {
            return 0.85
        } else if value < 100 {
            return 0.95
        } else {
            return 1.0
        }
    }

    func normalizeBloodOxygen(_ value: Double) -> Double {
        // 95-100% is normal
        if value < 90 {
            return 0.3  // Very low, concerning
        } else if value < 95 {
            return 0.6  // Low
        } else if value < 98 {
            return 0.85  // Good
        } else {
            return 1.0  // Excellent
        }
    }

    func normalizeBloodPressure(systolic: Double, diastolic: Double) -> Double {
        // Based on standard BP categories
        if systolic < 90 || diastolic < 60 {
            return 0.4  // Low blood pressure
        } else if systolic < 120 && diastolic < 80 {
            return 1.0  // Normal blood pressure
        } else if systolic < 130 && diastolic < 80 {
            return 0.8  // Elevated
        } else if systolic < 140 || diastolic < 90 {
            return 0.6  // Stage 1 hypertension
        } else if systolic < 180 || diastolic < 120 {
            return 0.3  // Stage 2 hypertension
        } else {
            return 0.1  // Hypertensive crisis
        }
    }
}

import Foundation

class MetabolicNormalizer: MetabolicNormalizerProtocol {
    let userProfile: HealthUserProfile
    
    required init(userProfile: HealthUserProfile) {
        self.userProfile = userProfile
    }
    
    func normalizeBMR(_ value: Double) -> Double {
        // If we don't have gender or age information, use the default scale
        if userProfile.userGender == .notSet || userProfile.userAge <= 0 {
            // Simplified implementation when demographic data is missing
            if value < 1000 {
                return 0.5  // Low
            } else if value < 1400 {
                return 0.7  // Below average
            } else if value < 1800 {
                return 0.9  // Average to good
            } else {
                return 1.0  // High
            }
        }
        
        // Age adjustment factors - BMR naturally decreases with age
        let ageAdjustment: Double
        if userProfile.userAge < 30 {
            ageAdjustment = 0        // Base reference
        } else if userProfile.userAge < 40 {
            ageAdjustment = -100     // Slight decrease expected
        } else if userProfile.userAge < 50 {
            ageAdjustment = -200     // Moderate decrease
        } else if userProfile.userAge < 60 {
            ageAdjustment = -300     // Larger decrease
        } else {
            ageAdjustment = -400     // Significant decrease for seniors
        }
        
        // Gender-specific assessment with age adjustment
        switch userProfile.userGender {
        case .male:
            let adjustedValue = value - ageAdjustment
            if adjustedValue < 1400 {
                return 0.5  // Low for males
            } else if adjustedValue < 1600 {
                return 0.7  // Below average
            } else if adjustedValue < 1800 {
                return 0.8  // Average
            } else if adjustedValue < 2000 {
                return 0.9  // Good
            } else {
                return 1.0  // Excellent
            }
            
        case .female:
            let adjustedValue = value - ageAdjustment
            if adjustedValue < 1200 {
                return 0.5  // Low for females
            } else if adjustedValue < 1400 {
                return 0.7  // Below average
            } else if adjustedValue < 1600 {
                return 0.8  // Average
            } else if adjustedValue < 1800 {
                return 0.9  // Good
            } else {
                return 1.0  // Excellent
            }
            
        default:
            // For other genders, use a middle-ground approach
            let adjustedValue = value - ageAdjustment
            if adjustedValue < 1300 {
                return 0.5  // Low
            } else if adjustedValue < 1500 {
                return 0.7  // Below average
            } else if adjustedValue < 1700 {
                return 0.8  // Average
            } else if adjustedValue < 1900 {
                return 0.9  // Good
            } else {
                return 1.0  // Excellent
            }
        }
    }

    func normalizeGlucose(_ value: Double) -> Double {
        // Based on general guidelines for blood glucose (mg/dL)
        if value < 70 {
            return 0.4  // Too low (hypoglycemia)
        } else if value < 100 {
            return 1.0  // Ideal fasting
        } else if value < 125 {
            return 0.8  // Normal to prediabetic
        } else if value < 180 {
            return 0.5  // High (diabetic range)
        } else {
            return 0.2  // Very high
        }
    }
}

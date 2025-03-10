import Foundation

class BodyCompositionNormalizer: BodyCompositionNormalizerProtocol {
    let userProfile: HealthUserProfile
    
    required init(userProfile: HealthUserProfile) {
        self.userProfile = userProfile
    }
    
    func normalizeBodyFat(_ percent: Double) -> Double {
        let value = percent * 100.0
        
        // Handle case when we don't have gender or age information
        if userProfile.userGender == .notSet || userProfile.userAge <= 0 {
            // Fall back to simplified general scale
            if value < 10 {
                return 0.4  // Too low is not ideal for most people
            } else if value < 20 {
                return 0.9  // Generally good
            } else if value < 30 {
                return 0.7  // Acceptable for most
            } else {
                return max(0.2, 1.0 - ((value - 30) / 20))  // Gradually decrease
            }
        }
        
        // Age-specific adjustments
        let ageAdjustment: Double
        if userProfile.userAge < 30 {
            ageAdjustment = 0.0  // Lower body fat is normal for younger people
        } else if userProfile.userAge < 40 {
            ageAdjustment = 2.0  // Slight adjustment upward
        } else if userProfile.userAge < 50 {
            ageAdjustment = 3.5  // More adjustment for middle age
        } else if userProfile.userAge < 60 {
            ageAdjustment = 5.0  // Even more for older age
        } else {
            ageAdjustment = 6.5  // Highest adjustment for seniors
        }
        
        // Gender-specific assessment with age adjustment
        switch userProfile.userGender {
        case .male:
            if value < 6 {
                return 0.3  // Too low, potentially unhealthy
            } else if value < (10 + ageAdjustment) {
                return 1.0  // Excellent
            } else if value < (15 + ageAdjustment) {
                return 0.9  // Very good
            } else if value < (20 + ageAdjustment) {
                return 0.8  // Good
            } else if value < (25 + ageAdjustment) {
                return 0.6  // Acceptable
            } else if value < (30 + ageAdjustment) {
                return 0.4  // Poor
            } else {
                return max(0.1, 0.4 - ((value - (30 + ageAdjustment)) / 15))  // Very poor
            }
            
        case .female:
            if value < 12 {
                return 0.3  // Too low, potentially unhealthy
            } else if value < (18 + ageAdjustment) {
                return 1.0  // Excellent
            } else if value < (23 + ageAdjustment) {
                return 0.9  // Very good
            } else if value < (28 + ageAdjustment) {
                return 0.8  // Good
            } else if value < (33 + ageAdjustment) {
                return 0.6  // Acceptable
            } else if value < (38 + ageAdjustment) {
                return 0.4  // Poor
            } else {
                return max(0.1, 0.4 - ((value - (38 + ageAdjustment)) / 15))  // Very poor
            }
            
        default:
            // For other genders, use a mid-range approach
            if value < 10 {
                return 0.3  // Too low
            } else if value < (14 + ageAdjustment) {
                return 1.0  // Excellent
            } else if value < (20 + ageAdjustment) {
                return 0.9  // Very good
            } else if value < (25 + ageAdjustment) {
                return 0.8  // Good
            } else if value < (30 + ageAdjustment) {
                return 0.6  // Acceptable
            } else if value < (35 + ageAdjustment) {
                return 0.4  // Poor
            } else {
                return max(0.1, 0.4 - ((value - (35 + ageAdjustment)) / 15))  // Very poor
            }
        }
    }
    
    func normalizeLeanBodyMass(_ value: Double) -> Double {
        // Default score if we can't calculate properly
        if userProfile.userHeight <= 0 || userProfile.userAge <= 0 {
            return 0.8
        }
        
        // Calculate Fat Free Mass Index (FFMI)
        // FFMI = LBM (kg) / height (m)^2
        let ffmi = value / (userProfile.userHeight * userProfile.userHeight)
        
        // FFMI interpretation based on gender
        switch userProfile.userGender {
        case .female:
            if ffmi < 14 {
                return 0.3  // Very low FFMI for females
            } else if ffmi < 16 {
                return 0.6  // Low but acceptable
            } else if ffmi < 18 {
                return 0.8  // Good
            } else if ffmi < 20 {
                return 1.0  // Excellent
            } else if ffmi < 22 {
                return 0.9  // Very athletic/muscular
            } else {
                return 0.8  // Potentially very muscular or measurement error
            }
            
        case .male:
            if ffmi < 17 {
                return 0.3  // Very low FFMI for males
            } else if ffmi < 19 {
                return 0.6  // Low but acceptable
            } else if ffmi < 21 {
                return 0.8  // Good
            } else if ffmi < 23 {
                return 1.0  // Excellent
            } else if ffmi < 25 {
                return 0.9  // Very athletic/muscular
            } else {
                return 0.8  // Potentially very muscular or measurement error
            }
            
        default:
            // For unknown gender, use a generic scale
            if ffmi < 16 {
                return 0.3  // Very low
            } else if ffmi < 18 {
                return 0.6  // Low
            } else if ffmi < 20 {
                return 0.8  // Good
            } else if ffmi < 22 {
                return 1.0  // Excellent
            } else {
                return 0.9  // Very muscular
            }
        }
    }
    
    func normalizeBMI(_ value: Double) -> Double {
        // BMI normalization: 18.5-24.9 is considered normal
        if value < 16 {
            return 0.3  // Severely underweight
        } else if value < 18.5 {
            return 0.7  // Underweight
        } else if value <= 24.9 {
            return 1.0  // Normal
        } else if value <= 29.9 {
            return 0.7  // Overweight
        } else if value <= 34.9 {
            return 0.5  // Obese Class I
        } else if value <= 39.9 {
            return 0.3  // Obese Class II
        } else {
            return 0.1  // Obese Class III
        }
    }
}

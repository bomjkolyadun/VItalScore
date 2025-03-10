import Foundation

class FitnessNormalizer: FitnessNormalizerProtocol {
    let userProfile: HealthUserProfile
    
    required init(userProfile: HealthUserProfile) {
        self.userProfile = userProfile
    }
    
    func normalizeVO2Max(_ value: Double) -> Double {
        // If we don't have gender or age, use simplified version
        if userProfile.userGender == .notSet || userProfile.userAge <= 0 {
            // Simplified version without demographic data
            if value < 30 {
                return max(0.1, value / 30)  // Poor
            } else if value < 40 {
                return 0.6 + (value - 30) / 25  // Fair to Good
            } else if value < 50 {
                return 0.8 + (value - 40) / 50  // Good to Excellent
            } else {
                return 1.0  // Excellent
            }
        }
        
        // Get age bracket adjustments
        let ageAdjustment: Double
        if userProfile.userAge < 30 {
            ageAdjustment = 0  // Base reference group
        } else if userProfile.userAge < 40 {
            ageAdjustment = -2  // Slight decrease in expected VO2Max
        } else if userProfile.userAge < 50 {
            ageAdjustment = -5  // Moderate decrease
        } else if userProfile.userAge < 60 {
            ageAdjustment = -7  // Larger decrease
        } else {
            ageAdjustment = -10  // Significant decrease for seniors
        }
        
        // Gender-specific assessment with age adjustment
        switch userProfile.userGender {
        case .male:
            let adjustedValue = value - ageAdjustment
            if adjustedValue < 35 {
                return max(0.1, adjustedValue / 35)  // Poor
            } else if adjustedValue < 42 {
                return 0.6 + (adjustedValue - 35) / 17.5  // Fair
            } else if adjustedValue < 50 {
                return 0.8 + (adjustedValue - 42) / 40  // Good
            } else {
                return 1.0  // Excellent
            }
            
        case .female:
            let adjustedValue = value - ageAdjustment
            if adjustedValue < 30 {
                return max(0.1, adjustedValue / 30)  // Poor
            } else if adjustedValue < 37 {
                return 0.6 + (adjustedValue - 30) / 17.5  // Fair
            } else if adjustedValue < 45 {
                return 0.8 + (adjustedValue - 37) / 40  // Good
            } else {
                return 1.0  // Excellent
            }
            
        default:
            // For other genders, use a mid-range approach
            let adjustedValue = value - ageAdjustment
            if adjustedValue < 33 {
                return max(0.1, adjustedValue / 33)  // Poor
            } else if adjustedValue < 40 {
                return 0.6 + (adjustedValue - 33) / 17.5  // Fair
            } else if adjustedValue < 48 {
                return 0.8 + (adjustedValue - 40) / 40  // Good
            } else {
                return 1.0  // Excellent
            }
        }
    }
    
    func normalizeSteps(_ value: Double) -> Double {
        // 10,000 steps is often considered a good target
        if value < 1000 {
            return 0.1
        } else if value < 5000 {
            return 0.3 + (value - 1000) / (4000 * 2)
        } else if value < 10000 {
            return 0.6 + (value - 5000) / (5000 * 1.3)
        } else if value < 15000 {
            return 0.9 + (value - 10000) / 5000
        } else {
            return 1.0
        }
    }
    
    func normalizeActiveCalories(_ value: Double) -> Double {
        // If we don't have gender or age information, use the default scale
        if userProfile.userGender == .notSet || userProfile.userAge <= 0 {
            if value < 100 {
                return 0.1
            } else if value < 300 {
                return 0.3 + (value - 100) / 400
            } else if value < 500 {
                return 0.6 + (value - 300) / 500
            } else if value < 800 {
                return 0.8 + (value - 500) / 1500
            } else {
                return 1.0
            }
        }
        
        // Age adjustment factor - older people need fewer calories to achieve the same score
        let ageAdjustment: Double
        if userProfile.userAge < 30 {
            ageAdjustment = 1.0  // Base reference
        } else if userProfile.userAge < 40 {
            ageAdjustment = 0.9  // 10% reduction
        } else if userProfile.userAge < 50 {
            ageAdjustment = 0.85 // 15% reduction
        } else if userProfile.userAge < 60 {
            ageAdjustment = 0.8  // 20% reduction
        } else {
            ageAdjustment = 0.75 // 25% reduction for seniors
        }
        
        // Gender-specific scaling with age adjustment
        switch userProfile.userGender {
        case .male:
            let adjustedValue = value / ageAdjustment
            if adjustedValue < 150 {
                return 0.1
            } else if adjustedValue < 350 {
                return 0.3 + (adjustedValue - 150) / 400
            } else if adjustedValue < 600 {
                return 0.6 + (adjustedValue - 350) / 500
            } else if adjustedValue < 900 {
                return 0.8 + (adjustedValue - 600) / 1500
            } else {
                return 1.0
            }
            
        case .female:
            let adjustedValue = value / ageAdjustment
            if adjustedValue < 100 {
                return 0.1
            } else if adjustedValue < 250 {
                return 0.3 + (adjustedValue - 100) / 300
            } else if adjustedValue < 450 {
                return 0.6 + (adjustedValue - 250) / 400
            } else if adjustedValue < 700 {
                return 0.8 + (adjustedValue - 450) / 1250
            } else {
                return 1.0
            }
            
        default:
            // For other genders, use a middle-ground approach
            let adjustedValue = value / ageAdjustment
            if adjustedValue < 125 {
                return 0.1
            } else if adjustedValue < 300 {
                return 0.3 + (adjustedValue - 125) / 350
            } else if adjustedValue < 525 {
                return 0.6 + (adjustedValue - 300) / 450
            } else if adjustedValue < 800 {
                return 0.8 + (adjustedValue - 525) / 1375
            } else {
                return 1.0
            }
        }
    }
}

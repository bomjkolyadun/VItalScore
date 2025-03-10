import Foundation
import HealthKit

class MetricNormalizer {
    let userProfile: HealthUserProfile
    
    init(userProfile: HealthUserProfile) {
        self.userProfile = userProfile
    }
    
    // MARK: - Body Composition Normalizers
    
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
    
    // MARK: - Fitness Normalizers
    
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
    
    // MARK: - Heart and Vitals Normalizers
    
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
    
    // MARK: - Metabolic Normalizers

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
    
    // MARK: - Lifestyle Normalizers

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

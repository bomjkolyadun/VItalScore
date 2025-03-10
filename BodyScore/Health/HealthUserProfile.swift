import Foundation
import HealthKit

class HealthUserProfile {
    var userHeight: Double = 0
    var userGender: HKBiologicalSex = .notSet
    var userAge: Int = 0
    
    var formattedHeight: String {
        if userHeight <= 0 {
            return "Not available"
        }
        
        let heightInCm = userHeight * 100
        return String(format: "%.0f cm", heightInCm)
    }
    
    func fetchUserDemographics(from healthStore: HKHealthStore, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        group.enter()
        fetchHeight(from: healthStore) {
            group.leave()
        }
        
        group.enter()
        fetchBiologicalSex(from: healthStore) {
            group.leave()
        }
        
        group.enter()
        fetchAge(from: healthStore) {
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    private func fetchHeight(from healthStore: HKHealthStore, completion: @escaping () -> Void) {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            print("Height type not available")
            completion()
            return
        }
        
        // Get the most recent height measurement
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                print("Error fetching height: \(error.localizedDescription)")
                completion()
                return
            }
            
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                print("No height data found")
                completion()
                return
            }
            
            let heightValue = sample.quantity.doubleValue(for: HKUnit.meter())
            print("Fetched height: \(heightValue) meters")
            
            DispatchQueue.main.async {
                self.userHeight = heightValue
                completion()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBiologicalSex(from healthStore: HKHealthStore, completion: @escaping () -> Void) {
        do {
            let biologicalSex = try healthStore.biologicalSex()
            DispatchQueue.main.async {
                self.userGender = biologicalSex.biologicalSex
                print("Fetched biological sex: \(biologicalSex.biologicalSex.description)")
                completion()
            }
        } catch {
            print("Error fetching biological sex: \(error.localizedDescription)")
            completion()
        }
    }
    
    private func fetchAge(from healthStore: HKHealthStore, completion: @escaping () -> Void) {
        do {
            let birthdayComponents = try healthStore.dateOfBirthComponents()
            let calendar = Calendar.current
            if let birthDate = calendar.date(from: birthdayComponents),
               let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year {
                DispatchQueue.main.async {
                    self.userAge = age
                    print("Fetched age: \(age) years")
                    completion()
                }
            } else {
                print("Could not calculate age from birth date components")
                completion()
            }
        } catch {
            print("Error fetching date of birth: \(error.localizedDescription)")
            completion()
        }
    }
}

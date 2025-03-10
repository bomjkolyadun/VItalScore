import Foundation
import SwiftData
import SwiftUI

@Model
class ScoreRecord {
    var date: Date
    var bodyScore: Double
    var confidenceScore: Double
    
    // Category scores
    var bodyCompositionScore: Double
    var fitnessScore: Double
    var heartVitalsScore: Double
    var metabolicScore: Double
    var lifestyleScore: Double
    
    init(date: Date = Date(), 
         bodyScore: Double = 0, 
         confidenceScore: Double = 0,
         bodyCompositionScore: Double = 0, 
         fitnessScore: Double = 0, 
         heartVitalsScore: Double = 0, 
         metabolicScore: Double = 0, 
         lifestyleScore: Double = 0) {
        self.date = date
        self.bodyScore = bodyScore
        self.confidenceScore = confidenceScore
        self.bodyCompositionScore = bodyCompositionScore
        self.fitnessScore = fitnessScore
        self.heartVitalsScore = heartVitalsScore
        self.metabolicScore = metabolicScore
        self.lifestyleScore = lifestyleScore
    }
    
    // Helper to format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Get formatted body score as string with no decimal places
    var formattedBodyScore: String {
        return String(format: "%.0f", bodyScore)
    }
    
    // Get formatted confidence score as string with no decimal places
    var formattedConfidenceScore: String {
        return String(format: "%.0f%%", confidenceScore)
    }
}

// MARK: - Score Record Store

class ScoreRecordStore {
    static let shared = ScoreRecordStore()
    
    private init() {}
    
    func saveRecord(_ record: ScoreRecord) {
        // Logic to save the record via SwiftData will be handled through the ModelContainer in the app
        print("Score record saved: \(record.bodyScore) with confidence \(record.confidenceScore)")
    }
    
    func getScoreHistory(context: ModelContext, days: Int = 30) -> [ScoreRecord] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        let predicate = #Predicate<ScoreRecord> { record in
            record.date >= startDate && record.date <= endDate
        }
        
        let sortDescriptor = [SortDescriptor(\ScoreRecord.date, order: .forward)]
        
        do {
            let descriptor = FetchDescriptor<ScoreRecord>(predicate: predicate, sortBy: sortDescriptor)
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch score history: \(error.localizedDescription)")
            return []
        }
    }
    
    func getDailyAverages(context: ModelContext, days: Int = 30) -> [(date: Date, score: Double, confidence: Double)] {
        let records = getScoreHistory(context: context, days: days)
        
        // Group records by day
        let calendar = Calendar.current
        var groupedRecords: [Date: [ScoreRecord]] = [:]
        
        for record in records {
            let components = calendar.dateComponents([.year, .month, .day], from: record.date)
            if let dayStart = calendar.date(from: components) {
                if groupedRecords[dayStart] == nil {
                    groupedRecords[dayStart] = []
                }
                groupedRecords[dayStart]?.append(record)
            }
        }
        
        // Calculate daily averages
        return groupedRecords.map { day, dayRecords in
            let totalScore = dayRecords.reduce(0) { $0 + $1.bodyScore }
            let totalConfidence = dayRecords.reduce(0) { $0 + $1.confidenceScore }
            let avgScore = totalScore / Double(dayRecords.count)
            let avgConfidence = totalConfidence / Double(dayRecords.count)
            
            return (date: day, score: avgScore, confidence: avgConfidence)
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Sample Data Generator

extension ScoreRecord {
    static var sampleData: [ScoreRecord] {
        // Create sample data for the last 30 days
        let calendar = Calendar.current
        var samples: [ScoreRecord] = []
        
        for day in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else {
                continue
            }
            
            // Create somewhat realistic fluctuating data
            let baseScore = 70.0
            let dailyRandomness = Double.random(in: -8.0...8.0)
            let trendFactor = Double(day) * 0.2  // Small improvement trend over time
            
            let bodyScore = min(100, max(0, baseScore + dailyRandomness + trendFactor))
            let confidence = Double.random(in: 70...95)
            
            let record = ScoreRecord(
                date: date,
                bodyScore: bodyScore,
                confidenceScore: confidence,
                bodyCompositionScore: min(100, max(0, bodyScore + Double.random(in: -10...10))),
                fitnessScore: min(100, max(0, bodyScore + Double.random(in: -15...15))),
                heartVitalsScore: min(100, max(0, bodyScore + Double.random(in: -12...12))),
                metabolicScore: min(100, max(0, bodyScore + Double.random(in: -8...8))),
                lifestyleScore: min(100, max(0, bodyScore + Double.random(in: -20...20)))
            )
            
            samples.append(record)
        }
        
        return samples
    }
}
import SwiftUI
import SwiftData
import HealthKit

@main
struct BodyScoreApp: App {
    @StateObject private var healthManager = HealthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
        }
        .modelContainer(for: ScoreRecord.self)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Refresh data when app becomes active
                healthManager.fetchHealthData()
            }
        }
    }
    
    // Scene phase for app lifecycle management
    @Environment(\.scenePhase) var scenePhase
}
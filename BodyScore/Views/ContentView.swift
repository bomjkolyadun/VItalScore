import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var healthManager: HealthManager
    @Environment(\.modelContext) private var modelContext
    @Query private var scoreHistory: [ScoreRecord]
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge")
                }
                .tag(0)
            
            // Breakdown Tab
            BreakdownView()
                .tabItem {
                    Label("Breakdown", systemImage: "chart.bar")
                }
                .tag(1)
            
            // History Tab
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(2)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .tabViewStyle(DefaultTabViewStyle())
        .onAppear {
            // Request HealthKit authorization when the app launches
            if !healthManager.isAuthorized {
                healthManager.requestAuthorization()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthManager())
        .modelContainer(for: ScoreRecord.self, inMemory: true)
}

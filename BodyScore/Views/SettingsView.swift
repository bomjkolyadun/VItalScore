import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var healthManager: HealthManager
    @State private var selectedProfile: ProfileType = .custom
    
    enum ProfileType: String, CaseIterable, Identifiable {
        case custom = "Custom"
        case defaultProfile = "Default"
        case weightLoss = "Weight Loss"
        case fitness = "Fitness"
        case heartHealth = "Heart Health"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Focus Profile") {
                    Picker("Select Profile", selection: $selectedProfile) {
                        ForEach(ProfileType.allCases) { profile in
                            Text(profile.rawValue).tag(profile)
                        }
                    }
                    .onChange(of: selectedProfile) {
                        applyProfile()
                    }
                }
                
                Section("Category Weights") {
                    ForEach(HealthMetricCategory.allCases) { category in
                        HStack {
                            Text(category.rawValue)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f", healthManager.userPreferences.categoryWeights[category] ?? 1.0))
                                .foregroundColor(.secondary)
                            
                            Stepper("Weight", 
                                    value: Binding(
                                        get: {
                                            healthManager.userPreferences.categoryWeights[category] ?? 1.0
                                        },
                                        set: { newValue in
                                            var preferences = healthManager.userPreferences
                                            preferences.updateWeight(for: category, weight: newValue)
                                            healthManager.userPreferences = preferences
                                            healthManager.calculateBodyScore()
                                            selectedProfile = .custom
                                        }
                                    ),
                                    in: 0.1...2.0,
                                    step: 0.1)
                            .labelsHidden()
                        }
                    }
                }
                
                Section("Health Data") {
                    Button("Refresh Health Data") {
                        healthManager.fetchHealthData()
                    }
                    
                    NavigationLink("Health Permissions") {
                        Text("Manage your health data permissions in the Settings app.")
                            .padding()
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Vital Score App")
                        Spacer()
                        Text("v1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("This app calculates a comprehensive body score based on your health metrics from Apple Health.")
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func applyProfile() {
        switch selectedProfile {
        case .custom:
            // Do nothing, keep current settings
            break
        case .defaultProfile:
            healthManager.userPreferences = .defaultPreferences
        case .weightLoss:
            healthManager.userPreferences = .weightLossProfile
        case .fitness:
            healthManager.userPreferences = .fitnessProfile
        case .heartHealth:
            healthManager.userPreferences = .heartHealthProfile
        }
        
        // Recalculate scores with new weights
        healthManager.calculateBodyScore()
    }
}

#Preview {
    SettingsView()
        .environmentObject(HealthManager())
}

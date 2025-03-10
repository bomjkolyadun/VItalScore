import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var healthManager: HealthManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 20) // Add space above ScoreGaugeView
                    
                    // Main Score Display
                    ScoreGaugeView(
                        score: healthManager.bodyScore,
                        confidence: healthManager.confidenceScore
                    )
                    .frame(height: 200)
                    
                    // Category Score Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        CategoryScoreCard(
                            title: "Body Composition",
                            score: healthManager.bodyCompositionScore,
                            icon: "figure.arms.open",
                            color: .blue
                        )
                        
                        CategoryScoreCard(
                            title: "Fitness",
                            score: healthManager.fitnessScore,
                            icon: "figure.run",
                            color: .green
                        )
                        
                        CategoryScoreCard(
                            title: "Heart & Vitals",
                            score: healthManager.heartvitalsScore,
                            icon: "heart.fill",
                            color: .red
                        )
                        
                        CategoryScoreCard(
                            title: "Metabolic",
                            score: healthManager.metabolicScore,
                            icon: "bolt.fill",
                            color: .orange
                        )
                        
                        CategoryScoreCard(
                            title: "Lifestyle",
                            score: healthManager.lifestyleScore,
                            icon: "bed.double.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Recent metrics
                    VStack(alignment: .leading) {
                        Text("Recent Metrics")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(healthManager.metrics.prefix(5)) { metric in
                                    MetricCardView(metric: metric)
                                }
                                
                                if (healthManager.metrics.isEmpty) {
                                    Text("No metrics available")
                                        .frame(width: 120, height: 100)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Refresh Button
                    Button(action: {
                        withAnimation {
                            healthManager.fetchHealthData()
                        }
                    }) {
                        Label("Refresh Data", systemImage: "arrow.clockwise")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationTitle("Body Score")
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(HealthManager())
}

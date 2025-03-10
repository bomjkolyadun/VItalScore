import SwiftUI

struct BreakdownView: View {
    @EnvironmentObject private var healthManager: HealthManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    UserInfoCard()
                    IntroductionText()
                    MetricCategoriesBreakdown()
                }
                .padding(.vertical)
            }
            .navigationTitle("Score Breakdown")
        }
    }
}

struct UserInfoCard: View {
    @EnvironmentObject private var healthManager: HealthManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your Information")
                .font(.headline)
                .padding(.bottom, 8)
            
            HStack(spacing: 20) {
                UserInfoItem(
                    icon: "person.crop.circle.fill",
                    label: "Age",
                    value: "\(healthManager.userAge) years"
                )
                
                UserInfoItem(
                    icon: "arrow.up.and.down",
                    label: "Height",
                    value: healthManager.formattedHeight
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct IntroductionText: View {
    var body: some View {
        Text("Your score is calculated from the following categories:")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
    }
}

struct MetricCategoriesBreakdown: View {
    var body: some View {
        ForEach(HealthMetricCategory.allCases) { category in
            CategoryBreakdownView(category: category)
        }
    }
}

struct UserInfoItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.callout)
                    .fontWeight(.medium)
            }
        }
    }
}

struct CategoryBreakdownView: View {
    @EnvironmentObject private var healthManager: HealthManager
    let category: HealthMetricCategory
    
    private var categoryScore: Double {
        switch category {
        case .bodyComposition:
            return healthManager.bodyCompositionScore
        case .fitness:
            return healthManager.fitnessScore
        case .heartAndVitals:
            return healthManager.heartvitalsScore
        case .metabolic:
            return healthManager.metabolicScore
        case .lifestyle:
            return healthManager.lifestyleScore
        }
    }
    
    private var categoryMetrics: [HealthMetric] {
        healthManager.metrics.filter { $0.category == category }
    }
    
    private var categoryColor: Color {
        switch category {
        case .bodyComposition: return .blue
        case .fitness: return .green
        case .heartAndVitals: return .red
        case .metabolic: return .orange
        case .lifestyle: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(category.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(String(format: "%.0f", categoryScore))
                    .font(.headline)
                    .foregroundColor(categoryColor)
            }
            
            // Progress bar with GeometryReader to constrain width
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(height: 8)
                        .opacity(0.3)
                        .foregroundColor(categoryColor)
                    
                    Rectangle()
                        .frame(width: min(geometry.size.width, max(0, CGFloat(categoryScore) / 100 * geometry.size.width)), height: 8)
                        .foregroundColor(categoryColor)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
            
            // Category metrics
            ForEach(categoryMetrics) { metric in
                HStack {
                    Text(metric.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", metric.value)) \(metric.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
            
            if categoryMetrics.isEmpty {
                Text("No data available for this category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.horizontal)
    }
}

#Preview {
    BreakdownView()
        .environmentObject(HealthManager())
}

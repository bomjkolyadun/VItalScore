import SwiftUI

// MARK: - Metric Card Component

struct MetricCardView: View {
    let metric: HealthMetric
    
    private var metricColor: Color {
        switch metric.category {
        case .bodyComposition: return .blue
        case .fitness: return .green
        case .heartAndVitals: return .red
        case .metabolic: return .orange
        case .lifestyle: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric.name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(String(format: "%.1f", metric.value)) \(metric.unit)")
                .font(.headline)
            
            Spacer()
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(height: 4)
                    .opacity(0.3)
                    .foregroundColor(metricColor)
                
                Rectangle()
                    .frame(width: CGFloat(metric.normalizedScore * 120), height: 4)
                    .foregroundColor(metricColor)
            }
            .cornerRadius(2)
        }
        .frame(width: 120, height: 80)
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

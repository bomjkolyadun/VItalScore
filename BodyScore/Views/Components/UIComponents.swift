import SwiftUI

// MARK: - Score Gauge Component

struct ScoreGaugeView: View {
    let score: Double
    let confidence: Double
    @State private var animatedScore: Double = 0
    
    var body: some View {
        VStack {
            ZStack {
                // Background gauge
                Circle()
                    .trim(from: 0.0, to: 0.75)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 40)
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(135))
                
                // Score gauge
                Circle()
                    .trim(from: 0.0, to: min(0.75, 0.75 * animatedScore / 100))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.red, .orange, .yellow, .green]),
                            center: .center,
                            startAngle: .degrees(135),
                            endAngle: .degrees(405)
                        ),
                        style: StrokeStyle(lineWidth: 40, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(135))
                
                // Score text
                VStack {
                    Text(String(format: "%.0f", score))
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                    
                    Text("Body Score")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(confidence))% Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 1)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedScore = score
            }
        }
        .onChange(of: score) {
            withAnimation(.easeOut(duration: 0.5)) {
                animatedScore = score
            }
        }
    }
}

// MARK: - Category Score Card Component

struct CategoryScoreCard: View {
    let title: String
    let score: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("\(Int(score))")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: 50, height: 6)
                        .opacity(0.3)
                        .foregroundColor(color)
                    
                    Rectangle()
                        .frame(width: max(0, min(50, score / 100 * 50)), height: 6)
                        .foregroundColor(color)
                }
                .cornerRadius(3)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

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

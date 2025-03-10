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

                Circle()
                    .trim(from: 0.0, to: min(0.75, 0.75 * animatedScore / 100))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.red, .orange, .yellow, .green]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(270)
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

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        Text("Score Gauge Examples")
            .font(.headline)
            .padding(.top)
        
        HStack(spacing: 20) {
            ScoreGaugeView(score: 42, confidence: 85)
                .frame(width: 150, height: 150)
            
            ScoreGaugeView(score: 78, confidence: 92)
                .frame(width: 150, height: 150)
        }
        
        ScoreGaugeView(score: 95, confidence: 98)
    }
    .padding()
    .previewLayout(.sizeThatFits)
}

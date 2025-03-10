import SwiftUI

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

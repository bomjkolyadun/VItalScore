import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var timeRange: TimeRange = .month
    @State private var chartData: [(date: Date, score: Double, confidence: Double)] = []
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Time range picker
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: timeRange) {
                    loadChartData()
                }
                
                // Score chart
                ScoreChartView(data: chartData)
                    .frame(height: 300)
                    .padding()
                
                // Recent scores list
                ScoreHistoryListView(days: timeRange.days)
            }
            .navigationTitle("Score History")
            .onAppear {
                loadChartData()
            }
        }
    }
    
    private func loadChartData() {
        chartData = ScoreRecordStore.shared.getDailyAverages(
            context: modelContext, 
            days: timeRange.days
        )
    }
}

struct ScoreChartView: View {
  let data: [(date: Date, score: Double, confidence: Double)]

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "M/d"
    return formatter
  }

  var body: some View {
    Chart {
      ForEach(data, id: \.date) { item in
        LineMark(
          x: .value("Date", item.date),
          y: .value("Score", item.score)
        )
        .foregroundStyle(.blue)
        .symbol(.circle)

        AreaMark(
          x: .value("Date", item.date),
          yStart: .value("Lower", max(0, item.score * (1 - item.confidence / 100 * 0.5))),
          yEnd: .value("Upper", min(100, item.score * min(1.5, 2 - (item.confidence / 100))))
        )
        .foregroundStyle(.blue.opacity(0.1))
      }
    }
    .chartXAxis {
      AxisMarks(values: .stride(by: .day, count: 7)) { value in
        if let date = value.as(Date.self) {
          AxisValueLabel {
            Text(dateFormatter.string(from: date))
          }
        }
      }
    }
    .chartYAxis {
      AxisMarks(values: [0, 25, 50, 75, 100]) { value in
        if let intValue = value.as(Int.self) {
          AxisValueLabel {
            Text("\(intValue)")
          }
        }
        AxisGridLine()
      }
    }
    .chartYScale(domain: 0...100)
  }
}

struct ScoreHistoryListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var records: [ScoreRecord] = []
    let days: Int
    
    var body: some View {
        List {
            if records.isEmpty {
                Text("No records available for this time period")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(records) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.formattedDate)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Body Score: \(record.formattedBodyScore)")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Text(record.formattedConfidenceScore)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
        .onAppear {
            loadRecords()
        }
    }
    
    private func loadRecords() {
        records = ScoreRecordStore.shared.getScoreHistory(context: modelContext, days: days)
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(records[index])
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: ScoreRecord.self, inMemory: true)
}

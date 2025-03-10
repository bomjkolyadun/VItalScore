import SwiftUI
import SwiftData
import Charts

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

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject private var healthManager: HealthManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                                
                                if healthManager.metrics.isEmpty {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Open info/about sheet
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Breakdown View

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
            
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(height: 8)
                    .opacity(0.3)
                    .foregroundColor(categoryColor)
                
                Rectangle()
                    .frame(width: max(0, CGFloat(categoryScore) / 100 * UIScreen.main.bounds.width * 0.9), height: 8)
                    .foregroundColor(categoryColor)
            }
            .cornerRadius(4)
            
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

// MARK: - History View

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
        
        // If no data, add sample data (for preview only)
        if chartData.isEmpty {
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        // Convert sample records to chart data format
        let records = ScoreRecord.sampleData
            .filter { record in
                if let cutoffDate = Calendar.current.date(
                    byAdding: .day,
                    value: -timeRange.days,
                    to: Date()
                ) {
                    return record.date >= cutoffDate
                }
                return true
            }
        
        let calendar = Calendar.current
        var groupedRecords: [Date: [ScoreRecord]] = [:]
        
        for record in records {
            let components = calendar.dateComponents([.year, .month, .day], from: record.date)
            if let dayStart = calendar.date(from: components) {
                if groupedRecords[dayStart] == nil {
                    groupedRecords[dayStart] = []
                }
                groupedRecords[dayStart]?.append(record)
            }
        }
        
        chartData = groupedRecords.map { day, dayRecords in
            let totalScore = dayRecords.reduce(0) { $0 + $1.bodyScore }
            let totalConfidence = dayRecords.reduce(0) { $0 + $1.confidenceScore }
            let avgScore = totalScore / Double(dayRecords.count)
            let avgConfidence = totalConfidence / Double(dayRecords.count)
            
            return (date: day, score: avgScore, confidence: avgConfidence)
        }.sorted { $0.date < $1.date }
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
        .onAppear {
            loadRecords()
        }
    }
    
    private func loadRecords() {
        records = ScoreRecordStore.shared.getScoreHistory(context: modelContext, days: days)
        
        // If no data, load sample data
        if records.isEmpty {
            records = ScoreRecord.sampleData.filter { record in
                if let cutoffDate = Calendar.current.date(
                    byAdding: .day,
                    value: -days,
                    to: Date()
                ) {
                    return record.date >= cutoffDate
                }
                return true
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(records[index])
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject private var healthManager: HealthManager
    @State private var selectedProfile: ProfileType = .custom
    
    enum ProfileType: String, CaseIterable, Identifiable {
        case custom = "Custom"
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
                        Text("Body Score App")
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

// MARK: - UI Components

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

#Preview {
    ContentView()
        .environmentObject(HealthManager())
        .modelContainer(for: ScoreRecord.self, inMemory: true)
}

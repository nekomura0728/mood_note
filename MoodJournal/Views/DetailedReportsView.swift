import SwiftUI

/// 詳細レポート表示画面
struct DetailedReportsView: View {
    @StateObject private var reportsManager = DetailedReportsManager()
    @StateObject private var proManager = ProManager.shared
    @State private var selectedPeriod: ReportPeriod = .month
    @State private var showProUpgrade = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground.ignoresSafeArea()
                
                if !proManager.isPro {
                    proUpgradePrompt
                } else {
                    mainContent
                }
            }
            .navigationTitle("詳細レポート")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if proManager.isPro {
                    Task {
                        await reportsManager.generateDetailedReport(for: selectedPeriod)
                    }
                }
            }
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
        }
    }
    
    // MARK: - Pro Upgrade Prompt
    
    private var proUpgradePrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("詳細レポート")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("長期間の気分傾向を\n詳細に分析・可視化します")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: { showProUpgrade = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("Pro版で解除")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // 期間選択
                periodSelector
                
                // 現在のレポート
                if let currentReport = reportsManager.currentReport {
                    reportContent(currentReport)
                } else if reportsManager.isGenerating {
                    loadingCard
                } else {
                    generateReportCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .refreshable {
            await reportsManager.generateDetailedReport(for: selectedPeriod)
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分析期間")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Picker("期間", selection: $selectedPeriod) {
                ForEach(ReportPeriod.allCases, id: \.self) { period in
                    Text(period.displayName)
                        .tag(period)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedPeriod) { _, _ in
                Task {
                    await reportsManager.generateDetailedReport(for: selectedPeriod)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Report Content
    
    private func reportContent(_ report: DetailedReport) -> some View {
        VStack(spacing: 20) {
            // 概要メトリクス
            overviewMetricsCard(report.overviewMetrics)
            
            // 気分トレンド
            moodTrendsCard(report.moodTrends)
            
            // パターンインサイト
            if !report.patternInsights.isEmpty {
                patternInsightsCard(report.patternInsights)
            }
            
            // 推奨事項
            if !report.recommendations.isEmpty {
                recommendationsCard(report.recommendations)
            }
            
            // 詳細チャート
            detailedChartsCard(report.detailedCharts)
        }
    }
    
    // MARK: - Overview Metrics Card
    
    private func overviewMetricsCard(_ metrics: ReportOverviewMetrics) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("概要")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricItem(
                    title: "総記録数",
                    value: "\(metrics.totalRecords)",
                    subtitle: "件",
                    color: .blue
                )
                
                MetricItem(
                    title: "記録日数",
                    value: "\(metrics.recordingDays)",
                    subtitle: "日",
                    color: .green
                )
                
                MetricItem(
                    title: "平均気分",
                    value: String(format: "%.1f", metrics.averageMoodScore),
                    subtitle: "スコア",
                    color: metrics.averageMoodScore > 0 ? .green : .orange
                )
                
                MetricItem(
                    title: "継続率",
                    value: "\(Int(metrics.consistencyRate * 100))",
                    subtitle: "%",
                    color: .purple
                )
            }
            
            // 支配的な気分
            HStack(spacing: 12) {
                Text("最も多い気分")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(metrics.dominantMood.emoji)
                        .font(.system(size: 20))
                    
                    Text(metrics.dominantMood.displayName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.moodColor(for: metrics.dominantMood).opacity(0.1))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Mood Trends Card
    
    private func moodTrendsCard(_ trends: [MoodTrend]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("気分トレンド")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            ForEach(trends, id: \.mood) { trend in
                MoodTrendRow(trend: trend)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Pattern Insights Card
    
    private func patternInsightsCard(_ insights: [PatternInsight]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("パターンインサイト")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            ForEach(insights.indices, id: \.self) { index in
                PatternInsightRow(insight: insights[index])
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Recommendations Card
    
    private func recommendationsCard(_ recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("推奨事項")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            ForEach(recommendations.indices, id: \.self) { index in
                RecommendationRow(
                    recommendation: recommendations[index],
                    index: index + 1
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Detailed Charts Card
    
    private func detailedChartsCard(_ chartData: ReportChartData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("詳細チャート")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // 気分分布チャート
            moodDistributionChart(chartData.moodDistribution)
            
            // 週間パターンチャート
            if !chartData.weeklyPatterns.isEmpty {
                weeklyPatternsChart(chartData.weeklyPatterns)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Charts
    
    private func moodDistributionChart(_ distribution: [Mood: Int]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("気分分布")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            ForEach(Mood.allCases, id: \.self) { mood in
                let count = distribution[mood] ?? 0
                let totalCount = distribution.values.reduce(0, +)
                let percentage = totalCount > 0 ? Double(count) / Double(totalCount) : 0
                
                if count > 0 {
                    HStack {
                        Text(mood.emoji)
                            .font(.system(size: 16))
                            .frame(width: 30)
                        
                        Text(mood.displayName)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .frame(width: 80, alignment: .leading)
                        
                        ProgressView(value: percentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.moodColor(for: mood)))
                        
                        Text("\(count)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
    }
    
    private func weeklyPatternsChart(_ patterns: [WeeklyPatternPoint]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間パターン")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            let weekdays = ["", "日", "月", "火", "水", "木", "金", "土"]
            let maxScore = patterns.map { $0.averageScore }.max() ?? 1.0
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(patterns, id: \.weekday) { pattern in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 30, height: max(4, CGFloat(pattern.averageScore / maxScore * 60)))
                        
                        Text(weekdays[pattern.weekday])
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Loading Card
    
    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("レポートを生成中...")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Generate Report Card
    
    private var generateReportCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("詳細レポートを生成")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("選択した期間の記録から\n詳細な分析レポートを生成します")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await reportsManager.generateDetailedReport(for: selectedPeriod)
                }
            }) {
                Text("レポートを生成")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
}

// MARK: - Supporting Views

/// メトリクスアイテム
struct MetricItem: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                        .offset(y: -2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

/// 気分トレンド行
struct MoodTrendRow: View {
    let trend: MoodTrend
    
    var body: some View {
        HStack(spacing: 12) {
            Text(trend.mood.emoji)
                .font(.system(size: 20))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(trend.mood.displayName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(trend.trendDirection.emoji)
                        .font(.system(size: 12))
                    
                    Text(trend.trendDirection.displayName)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Text("\(trend.frequency)回 (\(String(format: "%.1f", trend.percentage))%)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

/// パターンインサイト行
struct PatternInsightRow: View {
    let insight: PatternInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: insight.impact.color))
                .frame(width: 8, height: 8)
                .offset(y: 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
    }
}

/// 推奨事項行
struct RecommendationRow: View {
    let recommendation: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.orange))
            
            Text(recommendation)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(4)
            
            Spacer()
        }
    }
}

#Preview {
    DetailedReportsView()
}
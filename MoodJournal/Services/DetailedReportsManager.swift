import Foundation
import SwiftUI

/// 詳細レポート管理システム
@MainActor
class DetailedReportsManager: ObservableObject {
    @Published var currentReport: DetailedReport?
    @Published var reportHistory: [DetailedReport] = []
    @Published var isGenerating = false
    
    private let dataController = DataController.shared
    
    func generateDetailedReport(for period: ReportPeriod) async -> DetailedReport? {
        guard ProManager.shared.isFeatureAvailable(.detailedReports) else { return nil }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let (startDate, endDate) = period.dateRange(from: Date())
        let entries = dataController.fetchEntries(from: startDate, to: endDate)
        
        guard entries.count >= 3 else { return nil }
        
        let analysis = DetailedReportAnalysis(entries: entries, period: period)
        let report = generateReport(from: analysis)
        
        currentReport = report
        reportHistory.insert(report, at: 0)
        
        // 履歴は最新15件まで保持
        if reportHistory.count > 15 {
            reportHistory = Array(reportHistory.prefix(15))
        }
        
        return report
    }
    
    private func generateReport(from analysis: DetailedReportAnalysis) -> DetailedReport {
        return DetailedReport(
            period: analysis.period,
            dateRange: analysis.dateRange,
            overviewMetrics: generateOverviewMetrics(analysis),
            moodTrends: generateMoodTrends(analysis),
            patternInsights: generatePatternInsights(analysis),
            comparativeAnalysis: generateComparativeAnalysis(analysis),
            recommendations: generateRecommendations(analysis),
            detailedCharts: generateChartData(analysis)
        )
    }
    
    private func generateOverviewMetrics(_ analysis: DetailedReportAnalysis) -> ReportOverviewMetrics {
        return ReportOverviewMetrics(
            totalRecords: analysis.entries.count,
            recordingDays: analysis.uniqueDays,
            averageMoodScore: analysis.averageMoodScore,
            dominantMood: analysis.dominantMood,
            consistencyRate: analysis.consistency,
            improvementRate: analysis.overallTrend
        )
    }
    
    private func generateMoodTrends(_ analysis: DetailedReportAnalysis) -> [MoodTrend] {
        var trends: [MoodTrend] = []
        
        // 各気分の頻度と傾向
        for mood in Mood.allCases {
            let count = analysis.moodDistribution[mood] ?? 0
            let percentage = analysis.entries.count > 0 ? Double(count) / Double(analysis.entries.count) * 100 : 0
            let trend = calculateMoodTrend(for: mood, in: analysis)
            
            trends.append(MoodTrend(
                mood: mood,
                frequency: count,
                percentage: percentage,
                trendDirection: trend,
                peakPeriods: findPeakPeriods(for: mood, in: analysis)
            ))
        }
        
        return trends.sorted { $0.frequency > $1.frequency }
    }
    
    private func calculateMoodTrend(for mood: Mood, in analysis: DetailedReportAnalysis) -> TrendDirection {
        let entries = analysis.entries.compactMap { entry -> (Date, Bool) in
            guard let entryMood = entry.moodEnum else { return nil }
            return (entry.date, entryMood == mood)
        }.sorted { $0.0 < $1.0 }
        
        guard entries.count >= 6 else { return .stable }
        
        let midpoint = entries.count / 2
        let earlierPeriod = entries.prefix(midpoint)
        let recentPeriod = entries.suffix(from: midpoint)
        
        let earlierCount = earlierPeriod.filter { $0.1 }.count
        let recentCount = recentPeriod.filter { $0.1 }.count
        
        let earlierRate = Double(earlierCount) / Double(earlierPeriod.count)
        let recentRate = Double(recentCount) / Double(recentPeriod.count)
        
        let difference = recentRate - earlierRate
        
        if difference > 0.15 {
            return .increasing
        } else if difference < -0.15 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func findPeakPeriods(for mood: Mood, in analysis: DetailedReportAnalysis) -> [String] {
        // 曜日別の分析
        let weekdayAnalysis = Dictionary(grouping: analysis.entries) { entry in
            Calendar.current.component(.weekday, from: entry.date)
        }.mapValues { entries in
            entries.filter { $0.moodEnum == mood }.count
        }
        
        let maxCount = weekdayAnalysis.values.max() ?? 0
        let peakWeekdays = weekdayAnalysis.filter { $0.value == maxCount && maxCount > 0 }
            .keys.map { weekdayNumber in
                ["", "日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"][weekdayNumber]
            }
        
        return peakWeekdays
    }
    
    private func generatePatternInsights(_ analysis: DetailedReportAnalysis) -> [PatternInsight] {
        var insights: [PatternInsight] = []
        
        // 週間パターンの分析
        if let weeklyPattern = analyzeWeeklyPattern(analysis) {
            insights.append(weeklyPattern)
        }
        
        // 気分の変動パターン
        if let volatilityInsight = analyzeVolatilityPattern(analysis) {
            insights.append(volatilityInsight)
        }
        
        // 継続性パターン
        if let consistencyInsight = analyzeConsistencyPattern(analysis) {
            insights.append(consistencyInsight)
        }
        
        // 改善パターン
        if let improvementInsight = analyzeImprovementPattern(analysis) {
            insights.append(improvementInsight)
        }
        
        return insights
    }
    
    private func analyzeWeeklyPattern(_ analysis: DetailedReportAnalysis) -> PatternInsight? {
        let weekdayScores = Dictionary(grouping: analysis.entries) { entry in
            Calendar.current.component(.weekday, from: entry.date)
        }.mapValues { entries in
            let scores = entries.compactMap { $0.moodEnum?.numericValue }
            return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        }
        
        let sortedWeekdays = weekdayScores.sorted { $0.value > $1.value }
        guard let best = sortedWeekdays.first, let worst = sortedWeekdays.last else { return nil }
        
        let weekdays = ["", "日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]
        let bestDay = weekdays[best.key]
        let worstDay = weekdays[worst.key]
        
        return PatternInsight(
            type: .weeklyPattern,
            title: "週間パターン",
            description: "\(bestDay)の気分が最も良く、\(worstDay)に落ち込みやすい傾向があります。",
            impact: abs(best.value - worst.value) > 0.5 ? .high : .medium,
            actionable: true
        )
    }
    
    private func analyzeVolatilityPattern(_ analysis: DetailedReportAnalysis) -> PatternInsight? {
        guard analysis.volatility > 0 else { return nil }
        
        let impact: PatternImpact
        let description: String
        
        if analysis.volatility > 0.7 {
            impact = .high
            description = "気分の変動が大きく、日によって大きな違いがあります。安定したルーティンを作ることで改善が期待できます。"
        } else if analysis.volatility > 0.4 {
            impact = .medium
            description = "適度な気分の変動があります。これは自然な範囲内ですが、パターンを把握することで予測可能になります。"
        } else {
            impact = .low
            description = "気分が安定しており、大きな変動は見られません。この安定性を維持することが重要です。"
        }
        
        return PatternInsight(
            type: .volatility,
            title: "気分の変動性",
            description: description,
            impact: impact,
            actionable: analysis.volatility > 0.4
        )
    }
    
    private func analyzeConsistencyPattern(_ analysis: DetailedReportAnalysis) -> PatternInsight? {
        let impact: PatternImpact
        let description: String
        let actionable: Bool
        
        if analysis.consistency > 0.85 {
            impact = .low
            description = "記録の継続性が非常に高く、素晴らしい習慣が身についています。"
            actionable = false
        } else if analysis.consistency > 0.6 {
            impact = .medium
            description = "記録の継続性は良好です。さらに安定した記録習慣を目指すことで、より正確な分析が可能になります。"
            actionable = true
        } else {
            impact = .high
            description = "記録の継続性に改善の余地があります。定期的な記録により、より詳細な気分パターンの把握が可能になります。"
            actionable = true
        }
        
        return PatternInsight(
            type: .consistency,
            title: "記録の継続性",
            description: description,
            impact: impact,
            actionable: actionable
        )
    }
    
    private func analyzeImprovementPattern(_ analysis: DetailedReportAnalysis) -> PatternInsight? {
        let impact: PatternImpact
        let description: String
        
        if analysis.overallTrend > 0.3 {
            impact = .low
            description = "全体的に気分が改善傾向にあります。現在の習慣やライフスタイルが良い影響を与えているようです。"
        } else if analysis.overallTrend < -0.3 {
            impact = .high
            description = "気分が下降傾向にあります。生活習慣やストレス要因を見直すことで改善が期待できます。"
        } else {
            impact = .medium
            description = "気分は比較的安定しています。大きな変化はありませんが、小さな改善を積み重ねることが重要です。"
        }
        
        return PatternInsight(
            type: .trend,
            title: "全体的な傾向",
            description: description,
            impact: impact,
            actionable: true
        )
    }
    
    private func generateComparativeAnalysis(_ analysis: DetailedReportAnalysis) -> ComparativeAnalysis? {
        // 前期間との比較は実装を簡略化
        // 実際のアプリでは過去の同期間データとの比較を実装
        return ComparativeAnalysis(
            previousPeriod: "前回同期間",
            moodScoreChange: analysis.overallTrend,
            consistencyChange: 0, // 簡略化
            dominantMoodChange: analysis.dominantMood.displayName
        )
    }
    
    private func generateRecommendations(_ analysis: DetailedReportAnalysis) -> [String] {
        var recommendations: [String] = []
        
        // 一貫性に基づく推奨
        if analysis.consistency < 0.7 {
            recommendations.append("記録の習慣化のため、毎日同じ時間に記録することをお勧めします")
        }
        
        // 変動性に基づく推奨
        if analysis.volatility > 0.6 {
            recommendations.append("気分の安定化のため、規則正しい睡眠と食事を心がけましょう")
        }
        
        // 傾向に基づく推奨
        if analysis.overallTrend < -0.2 {
            recommendations.append("気分の改善のため、リラクゼーションや軽い運動を取り入れてみましょう")
        }
        
        // 支配的な気分に基づく推奨
        if analysis.dominantMood == .tired {
            recommendations.append("疲労感が多い場合、十分な休息とストレス管理を重視しましょう")
        } else if analysis.dominantMood == .sleepy {
            recommendations.append("眠気が多い場合、睡眠の質と時間を見直してみましょう")
        } else if analysis.dominantMood == .angry {
            recommendations.append("イライラが多い場合、ストレス発散の方法を見つけることが大切です")
        }
        
        // 基本的な推奨事項
        recommendations.append("継続的な記録により、より詳細なパターンを把握できます")
        
        return recommendations
    }
    
    private func generateChartData(_ analysis: DetailedReportAnalysis) -> ReportChartData {
        return ReportChartData(
            moodDistribution: analysis.moodDistribution,
            dailyTrends: generateDailyTrends(analysis),
            weeklyPatterns: generateWeeklyPatterns(analysis),
            monthlyOverview: generateMonthlyOverview(analysis)
        )
    }
    
    private func generateDailyTrends(_ analysis: DetailedReportAnalysis) -> [DailyTrendPoint] {
        return analysis.entries.map { entry in
            DailyTrendPoint(
                date: entry.date,
                moodScore: entry.moodEnum?.numericValue ?? 0,
                mood: entry.moodEnum ?? .normal
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func generateWeeklyPatterns(_ analysis: DetailedReportAnalysis) -> [WeeklyPatternPoint] {
        let weekdayData = Dictionary(grouping: analysis.entries) { entry in
            Calendar.current.component(.weekday, from: entry.date)
        }.mapValues { entries in
            let scores = entries.compactMap { $0.moodEnum?.numericValue }
            return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        }
        
        return (1...7).map { weekday in
            WeeklyPatternPoint(
                weekday: weekday,
                averageScore: weekdayData[weekday] ?? 0
            )
        }
    }
    
    private func generateMonthlyOverview(_ analysis: DetailedReportAnalysis) -> [MonthlyOverviewPoint] {
        // 月別の概要データ生成（簡略化）
        let monthlyData = Dictionary(grouping: analysis.entries) { entry in
            Calendar.current.component(.month, from: entry.date)
        }.mapValues { entries in
            let scores = entries.compactMap { $0.moodEnum?.numericValue }
            return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        }
        
        return monthlyData.map { month, score in
            MonthlyOverviewPoint(month: month, averageScore: score)
        }.sorted { $0.month < $1.month }
    }
}

// MARK: - Data Structures

/// 詳細レポート
struct DetailedReport: Identifiable {
    let id = UUID()
    let period: ReportPeriod
    let dateRange: DateInterval
    let overviewMetrics: ReportOverviewMetrics
    let moodTrends: [MoodTrend]
    let patternInsights: [PatternInsight]
    let comparativeAnalysis: ComparativeAnalysis?
    let recommendations: [String]
    let detailedCharts: ReportChartData
    let generatedAt = Date()
}

/// レポート期間
enum ReportPeriod: String, CaseIterable {
    case month = "month"
    case threeMonths = "three_months"
    case sixMonths = "six_months"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .month: return "1ヶ月"
        case .threeMonths: return "3ヶ月"
        case .sixMonths: return "6ヶ月"
        case .year: return "1年"
        }
    }
    
    func dateRange(from date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let endDate = calendar.endOfDay(for: date)
        
        switch self {
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
            return (startDate, endDate)
        case .threeMonths:
            let startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!
            return (startDate, endDate)
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -6, to: endDate)!
            return (startDate, endDate)
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
            return (startDate, endDate)
        }
    }
}

/// 概要メトリクス
struct ReportOverviewMetrics {
    let totalRecords: Int
    let recordingDays: Int
    let averageMoodScore: Double
    let dominantMood: Mood
    let consistencyRate: Double
    let improvementRate: Double
}

/// 気分トレンド
struct MoodTrend {
    let mood: Mood
    let frequency: Int
    let percentage: Double
    let trendDirection: TrendDirection
    let peakPeriods: [String]
}

/// トレンド方向
enum TrendDirection {
    case increasing
    case decreasing
    case stable
    
    var displayName: String {
        switch self {
        case .increasing: return "増加傾向"
        case .decreasing: return "減少傾向"
        case .stable: return "安定"
        }
    }
    
    var emoji: String {
        switch self {
        case .increasing: return "📈"
        case .decreasing: return "📉"
        case .stable: return "➡️"
        }
    }
}

/// パターンインサイト
struct PatternInsight {
    let type: PatternType
    let title: String
    let description: String
    let impact: PatternImpact
    let actionable: Bool
}

enum PatternType {
    case weeklyPattern
    case volatility
    case consistency
    case trend
    case seasonal
}

enum PatternImpact {
    case low
    case medium
    case high
    
    var color: String {
        switch self {
        case .low: return "#4CAF50"
        case .medium: return "#FF9800"
        case .high: return "#F44336"
        }
    }
}

/// 比較分析
struct ComparativeAnalysis {
    let previousPeriod: String
    let moodScoreChange: Double
    let consistencyChange: Double
    let dominantMoodChange: String
}

/// レポートチャートデータ
struct ReportChartData {
    let moodDistribution: [Mood: Int]
    let dailyTrends: [DailyTrendPoint]
    let weeklyPatterns: [WeeklyPatternPoint]
    let monthlyOverview: [MonthlyOverviewPoint]
}

struct DailyTrendPoint {
    let date: Date
    let moodScore: Double
    let mood: Mood
}

struct WeeklyPatternPoint {
    let weekday: Int
    let averageScore: Double
}

struct MonthlyOverviewPoint {
    let month: Int
    let averageScore: Double
}

/// 詳細レポート分析
struct DetailedReportAnalysis {
    let entries: [MoodEntry]
    let period: ReportPeriod
    let dateRange: DateInterval
    let moodDistribution: [Mood: Int]
    let dominantMood: Mood
    let averageMoodScore: Double
    let consistency: Double
    let overallTrend: Double
    let volatility: Double
    let uniqueDays: Int
    
    init(entries: [MoodEntry], period: ReportPeriod) {
        self.entries = entries
        self.period = period
        self.dateRange = DateInterval(start: entries.first?.date ?? Date(), end: entries.last?.date ?? Date())
        
        let validEntries = entries.compactMap { $0.moodEnum }
        
        // 気分分布
        self.moodDistribution = Dictionary(grouping: validEntries, by: { $0 })
            .mapValues { $0.count }
        
        // 支配的な気分
        self.dominantMood = moodDistribution.max(by: { $0.value < $1.value })?.key ?? .normal
        
        // 平均気分スコア
        let scores = validEntries.map { $0.numericValue }
        self.averageMoodScore = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        
        // 一貫性（期間に対する記録率）
        let totalPossibleDays = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1
        self.uniqueDays = Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
        self.consistency = Double(uniqueDays) / Double(totalPossibleDays)
        
        // 全体的な傾向
        if entries.count >= 6 {
            let midpoint = entries.count / 2
            let recentScores = entries.prefix(midpoint).compactMap { $0.moodEnum?.numericValue }
            let earlierScores = entries.suffix(from: midpoint).compactMap { $0.moodEnum?.numericValue }
            
            let recentAvg = recentScores.isEmpty ? 0 : recentScores.reduce(0, +) / Double(recentScores.count)
            let earlierAvg = earlierScores.isEmpty ? 0 : earlierScores.reduce(0, +) / Double(earlierScores.count)
            self.overallTrend = recentAvg - earlierAvg
        } else {
            self.overallTrend = 0
        }
        
        // 変動性
        if scores.count > 1 {
            let variance = scores.map { pow($0 - averageMoodScore, 2) }.reduce(0, +) / Double(scores.count)
            let stdDev = sqrt(variance)
            self.volatility = min(stdDev / 4.0, 1.0) // -2から2の範囲で正規化
        } else {
            self.volatility = 0
        }
    }
}
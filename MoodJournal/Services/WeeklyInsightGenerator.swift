import Foundation
import SwiftUI

/// 週次インサイト生成システム
@MainActor
class WeeklyInsightGenerator: ObservableObject {
    @Published var currentInsight: WeeklyInsight?
    @Published var insightHistory: [WeeklyInsight] = []
    @Published var isGenerating = false
    
    private let dataController = DataController.shared
    
    func generateWeeklyInsight() async -> WeeklyInsight? {
        guard ProManager.shared.isFeatureAvailable(.weeklyInsights) else { return nil }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let entries = dataController.fetchEntries(from: oneWeekAgo, to: Date())
        
        guard entries.count >= 3 else { return nil }
        
        let analysis = WeeklyAnalysis(entries: entries)
        let insight = generateInsight(from: analysis)
        
        currentInsight = insight
        insightHistory.insert(insight, at: 0)
        
        // 履歴は最新20件まで保持
        if insightHistory.count > 20 {
            insightHistory = Array(insightHistory.prefix(20))
        }
        
        return insight
    }
    
    private func generateInsight(from analysis: WeeklyAnalysis) -> WeeklyInsight {
        let template = SelectTemplate.forWeeklyAnalysis(analysis)
        let content = template.generate(with: analysis)
        
        return WeeklyInsight(
            weekRange: getWeekDateRange(),
            content: content,
            dominantMood: analysis.dominantMood,
            recordingDays: analysis.entries.count,
            highlights: generateHighlights(analysis),
            encouragement: generateEncouragement(analysis),
            nextWeekFocus: generateNextWeekFocus(analysis)
        )
    }
    
    private func generateHighlights(_ analysis: WeeklyAnalysis) -> [String] {
        var highlights: [String] = []
        
        // 記録の継続性
        if analysis.consistency > 0.8 {
            highlights.append("🎯 毎日の記録をしっかり続けています")
        } else if analysis.consistency > 0.5 {
            highlights.append("📝 記録を継続する努力が見られます")
        }
        
        // 気分の改善
        if analysis.improvement > 0.5 {
            highlights.append("📈 週の後半で気分が上向きました")
        } else if analysis.improvement < -0.5 {
            highlights.append("💙 少し大変でしたが記録を続けました")
        }
        
        // 気分の多様性
        let variety = analysis.moodDistribution.count
        if variety >= 4 {
            highlights.append("🌈 豊かな感情の変化がありました")
        }
        
        return highlights
    }
    
    private func generateEncouragement(_ analysis: WeeklyAnalysis) -> String {
        if analysis.averageMoodScore > 0.5 {
            return "素晴らしい1週間でした！この調子を大切に続けてください✨"
        } else if analysis.averageMoodScore > 0 {
            return "バランスの取れた1週間でした。小さな変化も大切にしてください🌱"
        } else if analysis.improvement > 0 {
            return "大変でしたが、週の後半は持ち直しています。頑張っていますね💪"
        } else {
            return "お疲れ様でした。記録を続けることで、きっと良い変化が見えてきますよ🌟"
        }
    }
    
    private func generateNextWeekFocus(_ analysis: WeeklyAnalysis) -> String {
        if analysis.dominantMood == .tired {
            return "来週は休息とリフレッシュを意識してみませんか？"
        } else if analysis.dominantMood == .angry {
            return "来週はストレス発散の時間を作ってみましょう"
        } else if analysis.dominantMood == .sleepy {
            return "来週は睡眠リズムを整えることを目標にしてみませんか？"
        } else if analysis.dominantMood == .happy {
            return "来週もこの良い調子を維持していきましょう！"
        } else {
            return "来週も自分のペースで記録を続けてみませんか？"
        }
    }
    
    private func getWeekDateRange() -> DateInterval {
        let calendar = Calendar.current
        let now = Date()
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        return DateInterval(start: oneWeekAgo, end: now)
    }
}

/// 週次インサイトのデータ構造
struct WeeklyInsight: Identifiable {
    let id = UUID()
    let weekRange: DateInterval
    let content: String
    let dominantMood: Mood
    let recordingDays: Int
    let highlights: [String]
    let encouragement: String
    let nextWeekFocus: String
    let createdAt = Date()
    
    var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        
        let startText = formatter.string(from: weekRange.start)
        let endText = formatter.string(from: weekRange.end)
        
        return "\(startText) - \(endText)"
    }
}

/// 週次分析データ
struct WeeklyAnalysis {
    let entries: [MoodEntry]
    let moodDistribution: [Mood: Int]
    let dominantMood: Mood
    let averageMoodScore: Double
    let consistency: Double
    let improvement: Double
    
    init(entries: [MoodEntry]) {
        self.entries = entries
        
        // 気分の分布
        let validEntries = entries.compactMap { $0.moodEnum }
        self.moodDistribution = Dictionary(grouping: validEntries, by: { $0 })
            .mapValues { $0.count }
        
        // 最も多い気分
        self.dominantMood = moodDistribution.max(by: { $0.value < $1.value })?.key ?? .normal
        
        // 平均気分スコア
        let scores = validEntries.map { $0.numericValue }
        self.averageMoodScore = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        
        // 記録の安定性（毎日記録しているかどうか）
        self.consistency = Double(entries.count) / 7.0
        
        // 改善度（前半と後半の比較）
        let midpoint = max(1, entries.count / 2)
        let firstHalf = entries.prefix(midpoint).compactMap { $0.moodEnum?.numericValue }
        let secondHalf = entries.suffix(from: midpoint).compactMap { $0.moodEnum?.numericValue }
        
        let firstHalfAvg = firstHalf.isEmpty ? 0 : firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondHalfAvg = secondHalf.isEmpty ? 0 : secondHalf.reduce(0, +) / Double(secondHalf.count)
        self.improvement = secondHalfAvg - firstHalfAvg
    }
}

/// 気分を数値化するextension
extension Mood {
    var numericValue: Double {
        switch self {
        case .angry: return -2.0
        case .tired: return -1.0
        case .sleepy: return -0.5
        case .normal: return 0.0
        case .happy: return 2.0
        }
    }
}

/// テンプレート選択システム
struct SelectTemplate {
    static func forWeeklyAnalysis(_ analysis: WeeklyAnalysis) -> WeeklySummaryTemplate {
        if analysis.averageMoodScore > 0.5 {
            return PositiveWeekTemplate()
        } else if analysis.averageMoodScore < -0.5 {
            return ChallengingWeekTemplate()
        } else if analysis.improvement > 0.3 {
            return ImprovingWeekTemplate()
        } else if analysis.consistency > 0.8 {
            return ConsistentWeekTemplate()
        } else {
            return BalancedWeekTemplate()
        }
    }
}

/// テンプレート基底プロトコル
protocol WeeklySummaryTemplate {
    func generate(with analysis: WeeklyAnalysis) -> String
}

/// ポジティブな週のテンプレート
class PositiveWeekTemplate: WeeklySummaryTemplate {
    func generate(with analysis: WeeklyAnalysis) -> String {
        let templates = [
            "素晴らしい1週間でした！『{dominantMood}』の記録が多く、{recordingDays}日間しっかり記録を続けられましたね。あなたの心の調子がとても良い状態です✨",
            "今週はとても充実していたようですね。{dominantMood}な気分が{dominantMoodCount}日もあり、きっと楽しいことが多かったのでしょう。この調子を大切に！",
            "輝いている1週間でした⭐️『{dominantMood}』が多く、平均的にもとてもポジティブな気分で過ごせていますね。"
        ]
        
        return templates.randomElement()!
            .replacingOccurrences(of: "{dominantMood}", with: analysis.dominantMood.displayName)
            .replacingOccurrences(of: "{recordingDays}", with: "\(analysis.recordingDays)")
            .replacingOccurrences(of: "{dominantMoodCount}", with: "\(analysis.moodDistribution[analysis.dominantMood] ?? 0)")
    }
}

/// 困難な週のテンプレート
class ChallengingWeekTemplate: WeeklySummaryTemplate {
    func generate(with analysis: WeeklyAnalysis) -> String {
        let templates = [
            "今週は少し大変だったようですね。{recordingDays}日間、気分を記録し続けたあなたの頑張りは本当に素晴らしいです。",
            "お疲れ様でした。『{dominantMood}』な日が多かったですが、それでも毎日の記録を続けられたのは立派です。",
            "しんどい1週間だったかもしれませんが、{improvement}きっと来週はもう少し楽になりますよ。"
        ]
        
        let improvementText = analysis.improvement > 0 ? "週の後半は少し上向きでしたし、" : ""
        
        return templates.randomElement()!
            .replacingOccurrences(of: "{dominantMood}", with: analysis.dominantMood.displayName)
            .replacingOccurrences(of: "{recordingDays}", with: "\(analysis.recordingDays)")
            .replacingOccurrences(of: "{improvement}", with: improvementText)
    }
}

/// 改善傾向の週のテンプレート
class ImprovingWeekTemplate: WeeklySummaryTemplate {
    func generate(with analysis: WeeklyAnalysis) -> String {
        let templates = [
            "週の後半にかけて気分が上向きになっていて素晴らしいですね！{recordingDays}日間の記録から、回復力の強さが見えます。",
            "徐々に調子が上がってきているのが分かります。この上向きな流れを大切にして、来週も頑張りましょう！",
            "週の始めは少し大変でしたが、後半は持ち直していますね。こうした変化に気づけるのも記録のおかげです。"
        ]
        
        return templates.randomElement()!
            .replacingOccurrences(of: "{recordingDays}", with: "\(analysis.recordingDays)")
    }
}

/// 安定した週のテンプレート
class ConsistentWeekTemplate: WeeklySummaryTemplate {
    func generate(with analysis: WeeklyAnalysis) -> String {
        let templates = [
            "とても安定した1週間でしたね。毎日記録を続けて、『{dominantMood}』を中心にバランスの取れた気分で過ごせました。",
            "継続的に記録を続けられて素晴らしいです！{dominantMood}な気分を中心に、安定した心の状態を保てていますね。",
            "記録の継続が素晴らしいです。安定した気分で過ごせているのは、きっと良い生活リズムができているからでしょう。"
        ]
        
        return templates.randomElement()!
            .replacingOccurrences(of: "{dominantMood}", with: analysis.dominantMood.displayName)
    }
}

/// バランスの取れた週のテンプレート
class BalancedWeekTemplate: WeeklySummaryTemplate {
    func generate(with analysis: WeeklyAnalysis) -> String {
        let templates = [
            "バランスの取れた1週間でした。様々な気分を経験しながらも、{recordingDays}日間記録を続けられましたね。",
            "いろいろな気分の変化がありましたが、それも自然なことです。{recordingDays}日間の記録から、あなたの豊かな感情が見えます。",
            "今週も記録を続けてくださりありがとうございます。{dominantMood}を中心に、自然な気分の変化を大切にされていますね。"
        ]
        
        return templates.randomElement()!
            .replacingOccurrences(of: "{recordingDays}", with: "\(analysis.recordingDays)")
            .replacingOccurrences(of: "{dominantMood}", with: analysis.dominantMood.displayName)
    }
}
import Foundation
import SwiftUI

/// パーソナルコーチングシステム
@MainActor
class PersonalCoachingSystem: ObservableObject {
    @Published var currentCoaching: PersonalCoaching?
    @Published var coachingHistory: [PersonalCoaching] = []
    @Published var isGenerating = false
    
    private let dataController = DataController.shared
    
    func generatePersonalCoaching() async -> PersonalCoaching? {
        guard ProManager.shared.isFeatureAvailable(.personalCoaching) else { return nil }
        
        isGenerating = true
        defer { isGenerating = false }
        
        // 過去2週間のデータを分析
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let entries = dataController.fetchEntries(from: twoWeeksAgo, to: Date())
        
        guard entries.count >= 5 else { return nil }
        
        let analysis = PersonalCoachingAnalysis(entries: entries)
        let coaching = generateCoachingAdvice(from: analysis)
        
        currentCoaching = coaching
        coachingHistory.insert(coaching, at: 0)
        
        // 履歴は最新10件まで保持
        if coachingHistory.count > 10 {
            coachingHistory = Array(coachingHistory.prefix(10))
        }
        
        return coaching
    }
    
    private func generateCoachingAdvice(from analysis: PersonalCoachingAnalysis) -> PersonalCoaching {
        let pattern = identifyMoodPattern(analysis)
        let advice = generateAdvice(for: pattern, analysis: analysis)
        let actionItems = generateActionItems(for: pattern, analysis: analysis)
        let nextSteps = generateNextSteps(for: pattern)
        
        return PersonalCoaching(
            analysisDate: Date(),
            moodPattern: pattern,
            primaryAdvice: advice,
            actionItems: actionItems,
            nextSteps: nextSteps,
            analysisData: PersonalCoachingData(
                averageMood: analysis.averageMoodScore,
                consistency: analysis.consistency,
                recentTrend: analysis.recentTrend,
                dominantMoods: analysis.topMoods,
                volatility: analysis.volatility
            )
        )
    }
    
    private func identifyMoodPattern(_ analysis: PersonalCoachingAnalysis) -> MoodPattern {
        // 最近の傾向を重視したパターン判定
        if analysis.recentTrend > 0.5 {
            return .improving
        } else if analysis.recentTrend < -0.5 {
            return .declining
        } else if analysis.volatility > 0.7 {
            return .unstable
        } else if analysis.consistency > 0.8 {
            return .stable
        } else if analysis.averageMoodScore > 0.5 {
            return .positive
        } else if analysis.averageMoodScore < -0.3 {
            return .challenging
        } else {
            return .neutral
        }
    }
    
    private func generateAdvice(for pattern: MoodPattern, analysis: PersonalCoachingAnalysis) -> String {
        switch pattern {
        case .improving:
            return "素晴らしい上向きな傾向が見られます！この調子を維持するために、現在行っていることを継続しましょう。特に最近始めた新しい習慣や環境の変化があれば、それを大切にしてください。"
            
        case .declining:
            return "最近少し大変な時期が続いているようですね。まずは十分な睡眠と規則正しい食事を心がけ、小さなことでも自分を褒めてあげることから始めましょう。一人で抱え込まず、信頼できる人に話を聞いてもらうことも大切です。"
            
        case .unstable:
            return "気分の波が大きい傾向が見られます。安定した日常リズムを作ることで、気分の変動を穏やかにできるかもしれません。特に睡眠時間と起床時間を一定にすることから始めてみましょう。"
            
        case .stable:
            return "とても安定した気分で過ごせていますね。この良い状態を維持するために、現在の生活リズムや習慣を大切にしてください。時々新しいチャレンジを加えることで、さらに充実感を得られるかもしれません。"
            
        case .positive:
            return "全体的にポジティブな気分で過ごせていて素晴らしいです！この良い状態を活用して、新しいことにチャレンジしたり、他の人に親切にしたりすることで、さらに良い循環を作り出せそうです。"
            
        case .challenging:
            return "厳しい状況が続いているようですが、毎日記録を続けているあなたの努力は本当に立派です。小さな一歩を大切にして、無理をせず自分のペースで進んでいきましょう。必要なときは専門家に相談することも選択肢の一つです。"
            
        case .neutral:
            return "バランスの取れた安定した状態ですね。平穏な毎日を送れているのは素晴らしいことです。時々楽しみや小さな目標を加えることで、より充実感を感じられるかもしれません。"
        }
    }
    
    private func generateActionItems(for pattern: MoodPattern, analysis: PersonalCoachingAnalysis) -> [String] {
        var items: [String] = []
        
        // パターン別の基本アクションアイテム
        switch pattern {
        case .improving:
            items.append("現在の良い習慣を記録して継続する")
            items.append("新しい小さなチャレンジを1つ追加してみる")
            
        case .declining:
            items.append("睡眠時間を7-8時間確保する")
            items.append("信頼できる人と話す時間を作る")
            items.append("簡単なリラクゼーション（深呼吸など）を試す")
            
        case .unstable:
            items.append("毎日同じ時間に起床する")
            items.append("就寝前のリラックスタイムを設ける")
            
        case .stable:
            items.append("現在のルーティンを維持する")
            items.append("月に1つ新しい体験をしてみる")
            
        case .positive:
            items.append("この良い状態をもたらした要因を振り返る")
            items.append("周りの人に感謝の気持ちを表現してみる")
            
        case .challenging:
            items.append("1日1つ、小さな楽しみを見つける")
            items.append("基本的な生活習慣（食事・睡眠・運動）を整える")
            
        case .neutral:
            items.append("新しい趣味や興味を探してみる")
            items.append("感謝できることを3つ毎日見つける")
        }
        
        // 気分の分析に基づく追加アイテム
        if analysis.topMoods.contains(.tired) {
            items.append("疲労回復のため十分な休息を取る")
        }
        
        if analysis.topMoods.contains(.sleepy) {
            items.append("睡眠の質を改善する（寝る前のスマホ使用を控える等）")
        }
        
        if analysis.topMoods.contains(.angry) {
            items.append("ストレス発散の方法を見つける（散歩、音楽、読書等）")
        }
        
        if analysis.consistency < 0.5 {
            items.append("記録を続けやすい時間帯を見つける")
        }
        
        return items
    }
    
    private func generateNextSteps(for pattern: MoodPattern) -> [String] {
        switch pattern {
        case .improving:
            return [
                "2週間後にもう一度分析して進歩を確認する",
                "良い習慣をさらに強化する方法を考える",
                "周りの人とポジティブな体験を共有する"
            ]
            
        case .declining:
            return [
                "1週間後に気分の変化をチェックする",
                "必要であれば専門家に相談を検討する",
                "サポートシステム（家族・友人）を活用する"
            ]
            
        case .unstable:
            return [
                "安定したルーティンを3週間続けてみる",
                "気分の変動パターンをより詳しく観察する",
                "ストレス要因を特定して対策を立てる"
            ]
            
        case .stable:
            return [
                "現在の良い状態を長期間維持する",
                "新しい成長の機会を探す",
                "他の人のサポートに回る余裕を作る"
            ]
            
        case .positive:
            return [
                "この良い状態の要因を詳しく分析する",
                "ポジティブな影響を周りに広げる",
                "更なる成長目標を設定する"
            ]
            
        case .challenging:
            return [
                "毎週小さな改善点を見つける",
                "サポートリソースを確認・活用する",
                "長期的な回復計画を立てる"
            ]
            
        case .neutral:
            return [
                "より充実感を得られる活動を見つける",
                "新しい人間関係や体験を増やす",
                "将来の目標を明確にする"
            ]
        }
    }
}

/// パーソナルコーチングデータ構造
struct PersonalCoaching: Identifiable {
    let id = UUID()
    let analysisDate: Date
    let moodPattern: MoodPattern
    let primaryAdvice: String
    let actionItems: [String]
    let nextSteps: [String]
    let analysisData: PersonalCoachingData
    
    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: analysisDate)
    }
}

/// 気分パターンの種類
enum MoodPattern: String, CaseIterable {
    case improving = "improving"       // 改善傾向
    case declining = "declining"       // 下降傾向
    case unstable = "unstable"         // 不安定
    case stable = "stable"             // 安定
    case positive = "positive"         // ポジティブ
    case challenging = "challenging"   // 困難
    case neutral = "neutral"           // 中性的
    
    var displayName: String {
        switch self {
        case .improving: return "改善傾向"
        case .declining: return "要注意"
        case .unstable: return "変動あり"
        case .stable: return "安定"
        case .positive: return "良好"
        case .challenging: return "困難"
        case .neutral: return "平常"
        }
    }
    
    var emoji: String {
        switch self {
        case .improving: return "📈"
        case .declining: return "📉"
        case .unstable: return "🌊"
        case .stable: return "⚖️"
        case .positive: return "✨"
        case .challenging: return "💪"
        case .neutral: return "🌤️"
        }
    }
    
    var color: String {
        switch self {
        case .improving: return "#4CAF50"
        case .declining: return "#FF9800"
        case .unstable: return "#9C27B0"
        case .stable: return "#2196F3"
        case .positive: return "#8BC34A"
        case .challenging: return "#F44336"
        case .neutral: return "#607D8B"
        }
    }
}

/// コーチング分析データ
struct PersonalCoachingData {
    let averageMood: Double
    let consistency: Double
    let recentTrend: Double
    let dominantMoods: [Mood]
    let volatility: Double
}

/// パーソナルコーチング分析システム
struct PersonalCoachingAnalysis {
    let entries: [MoodEntry]
    let averageMoodScore: Double
    let consistency: Double
    let recentTrend: Double
    let topMoods: [Mood]
    let volatility: Double
    
    init(entries: [MoodEntry]) {
        self.entries = entries
        
        let validEntries = entries.compactMap { $0.moodEnum }
        let scores = validEntries.map { $0.numericValue }
        
        // 平均気分スコア
        self.averageMoodScore = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        
        // 記録の一貫性（14日中何日記録したか）
        self.consistency = Double(entries.count) / 14.0
        
        // 最近の傾向（最新7日と前7日の比較）
        let midpoint = max(1, entries.count / 2)
        let recentScores = entries.prefix(midpoint).compactMap { $0.moodEnum?.numericValue }
        let earlierScores = entries.suffix(from: midpoint).compactMap { $0.moodEnum?.numericValue }
        
        let recentAvg = recentScores.isEmpty ? 0 : recentScores.reduce(0, +) / Double(recentScores.count)
        let earlierAvg = earlierScores.isEmpty ? 0 : earlierScores.reduce(0, +) / Double(earlierScores.count)
        self.recentTrend = recentAvg - earlierAvg
        
        // 最も多い気分トップ3
        let moodCounts = Dictionary(grouping: validEntries, by: { $0 })
            .mapValues { $0.count }
        self.topMoods = moodCounts.sorted(by: { $0.value > $1.value })
            .prefix(3)
            .map { $0.key }
        
        // 気分の変動性（標準偏差を正規化）
        if scores.count > 1 {
            let variance = scores.map { pow($0 - averageMoodScore, 2) }.reduce(0, +) / Double(scores.count)
            let stdDev = sqrt(variance)
            // -2から2の範囲で正規化（4で割る）
            self.volatility = min(stdDev / 4.0, 1.0)
        } else {
            self.volatility = 0
        }
    }
}
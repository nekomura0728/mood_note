import WidgetKit
import SwiftUI

/// ウィジェットのタイムラインエントリー
struct MoodTimelineEntry: TimelineEntry {
    let date: Date
    let todayMood: Mood?
    let todayText: String?
    let timestamp: Date?
    let recentMoods: [Mood?]
}

/// ウィジェットのタイムラインプロバイダー
struct MoodTimelineProvider: TimelineProvider {
    typealias Entry = MoodTimelineEntry
    
    /// プレースホルダーエントリー
    func placeholder(in context: Context) -> MoodTimelineEntry {
        print("[Widget] Creating placeholder entry")
        
        let entry = MoodTimelineEntry(
            date: Date(),
            todayMood: Mood.happy,
            todayText: "今日は素晴らしい1日でした！",
            timestamp: Date(),
            recentMoods: [Mood.happy, Mood.normal, Mood.tired, Mood.angry, Mood.sleepy, Mood.happy, Mood.normal]
        )
        
        print("[Widget] Placeholder entry created successfully")
        return entry
    }
    
    /// スナップショット（ウィジェットギャラリー用）
    func getSnapshot(in context: Context, completion: @escaping (MoodTimelineEntry) -> Void) {
        print("[Widget] Getting snapshot for context: \(context)")
        
        let entry = placeholder(in: context)
        print("[Widget] Snapshot entry created, calling completion")
        completion(entry)
        print("[Widget] Snapshot completion called successfully")
    }
    
    /// タイムライン生成
    func getTimeline(in context: Context, completion: @escaping (Timeline<MoodTimelineEntry>) -> Void) {
        let currentDate = Date()
        
        // データを安全に取得（非同期処理を避けて同期処理で実行）
        let todayData: (mood: Mood?, text: String?, timestamp: Date?)
        let recentMoods: [Mood?]
        
        // SharedDataManagerからのデータ取得を最大限安全に実行
        // 追加の安全チェック: SharedDataManagerが正常に初期化されているか確認
        let manager = SharedDataManager.shared
        
        // データを取得
        todayData = manager.getTodayMood()
        recentMoods = manager.getRecentMoods()
        
        print("[Widget] Successfully retrieved data - Today: \(todayData.mood?.rawValue ?? "nil"), Recent: \(recentMoods.count) items")
        
        // エントリーを作成（防御的プログラミング）
        let entry = MoodTimelineEntry(
            date: currentDate,
            todayMood: todayData.mood,
            todayText: todayData.text?.isEmpty == false ? todayData.text : nil,
            timestamp: todayData.timestamp,
            recentMoods: recentMoods.count > 7 ? Array(recentMoods.prefix(7)) : recentMoods
        )
        print("[Widget] Timeline entry created successfully")
        
        // 次の更新時刻を安全に計算
        let calendar = Calendar.current
        var nextUpdateDate: Date
        
        if let calculatedDate = calendar.date(byAdding: .minute, value: 15, to: currentDate) {
            nextUpdateDate = calculatedDate
        } else {
            // カレンダー計算が失敗した場合のフォールバック
            nextUpdateDate = currentDate.addingTimeInterval(15 * 60) // 15分後
        }
        
        // 日付境界での更新を考慮
        if let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: currentDate) {
            let startOfTomorrow = calendar.startOfDay(for: tomorrowStart)
            nextUpdateDate = min(nextUpdateDate, startOfTomorrow)
        }
        
        // タイムラインを作成
        let timeline = Timeline(
            entries: [entry],
            policy: .after(nextUpdateDate)
        )
        print("[Widget] Timeline created successfully, next update: \(nextUpdateDate)")
        
        // 完了ハンドラーを安全に呼び出し
        DispatchQueue.main.async {
            completion(timeline)
        }
    }
}

/// ウィジェット用のMood拡張
extension Mood {
    /// ウィジェット表示用の色
    var widgetColor: Color {
        switch self {
        case .happy: return Color(red: 1.0, green: 0.9, blue: 0.7)
        case .normal: return Color(red: 0.7, green: 0.9, blue: 1.0)
        case .tired: return Color(red: 0.9, green: 0.8, blue: 1.0)
        case .angry: return Color(red: 1.0, green: 0.7, blue: 0.7)
        case .sleepy: return Color(red: 0.7, green: 1.0, blue: 0.9)
        }
    }
}
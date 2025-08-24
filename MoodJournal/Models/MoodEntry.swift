import Foundation
import SwiftData

/// 気分エントリーのデータモデル
@Model
final class MoodEntry {
    /// 一意識別子
    var id: UUID
    
    /// 気分
    var mood: String // Moodのraw value
    
    /// テキスト（最大140字）
    var text: String?
    
    /// タイムスタンプ
    var timestamp: Date
    
    /// イニシャライザー
    init(mood: Mood, text: String? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.mood = mood.rawValue
        self.text = text?.prefix(140).description
        self.timestamp = timestamp
    }
    
    /// Mood enumを取得
    var moodEnum: Mood? {
        Mood(rawValue: mood)
    }
    
    /// 日付のみ取得（時刻なし）
    var dateOnly: Date {
        Calendar.current.startOfDay(for: timestamp)
    }
    
    /// エントリーの日付（timestampのエイリアス）
    var date: Date {
        timestamp
    }
    
    /// フォーマット済み日付文字列
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: timestamp)
    }
    
    /// フォーマット済み時刻文字列
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: timestamp)
    }
}
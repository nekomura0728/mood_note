import Foundation

/// 気分を表すenum
enum Mood: String, CaseIterable, Codable {
    case happy = "happy"     // 😃
    case normal = "normal"   // 🙂
    case tired = "tired"     // 😫
    case angry = "angry"     // 😡
    case sleepy = "sleepy"   // 😴
    
    /// 表示用の絵文字
    var emoji: String {
        switch self {
        case .happy: return "😃"
        case .normal: return "🙂"
        case .tired: return "😫"
        case .angry: return "😡"
        case .sleepy: return "😴"
        }
    }
    
    /// 日本語表示名
    var displayName: String {
        switch self {
        case .happy: return "うれしい"
        case .normal: return "ふつう"
        case .tired: return "つかれた"
        case .angry: return "いらいら"
        case .sleepy: return "ねむい"
        }
    }
    
    /// テーマカラー（パステルカラー）
    var themeColor: String {
        switch self {
        case .happy: return "#FFE5B4"  // Peach
        case .normal: return "#B4E5FF" // Sky Blue
        case .tired: return "#E5D4FF"  // Lavender
        case .angry: return "#FFB4B4"  // Coral
        case .sleepy: return "#C8E6C9" // Soft Green (より落ち着いた緑)
        }
    }
}
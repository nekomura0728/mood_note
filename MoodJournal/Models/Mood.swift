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
    
    /// ローカライズされた表示名
    var displayName: String {
        switch self {
        case .happy: return NSLocalizedString("mood.happy", comment: "")
        case .normal: return NSLocalizedString("mood.normal", comment: "")
        case .tired: return NSLocalizedString("mood.tired", comment: "")
        case .angry: return NSLocalizedString("mood.angry", comment: "")
        case .sleepy: return NSLocalizedString("mood.sleepy", comment: "")
        }
    }
    
    /// テーマカラー（ライトモード用パステルカラー）
    var themeColor: String {
        switch self {
        case .happy: return "#FFE5B4"  // Peach
        case .normal: return "#B4E5FF" // Sky Blue
        case .tired: return "#E5D4FF"  // Lavender
        case .angry: return "#FFB4B4"  // Coral
        case .sleepy: return "#C8E6C9" // Soft Green (より落ち着いた緑)
        }
    }
    
    /// テーマカラー（ダークモード用）
    var darkThemeColor: String {
        switch self {
        case .happy: return "#8B6B47"  // Dark Peach
        case .normal: return "#4A7A8C" // Dark Sky Blue
        case .tired: return "#6B5B8C"  // Dark Lavender
        case .angry: return "#8B4545"  // Dark Coral
        case .sleepy: return "#4A6B50" // Dark Green
        }
    }
}
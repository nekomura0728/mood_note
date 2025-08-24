import Foundation

extension Date {
    /// 日付のみ（時刻なし）を取得
    var dateOnly: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// 今日かどうか
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 昨日かどうか
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// 日本語形式の日付文字列
    var japaneseShortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        if isToday {
            return "今日"
        } else if isYesterday {
            return "昨日"
        } else {
            formatter.dateFormat = "M/d"
            return formatter.string(from: self)
        }
    }
    
    /// 日本語形式の詳細日付文字列
    var japaneseDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        if isToday {
            return "今日"
        } else if isYesterday {
            return "昨日"
        } else {
            formatter.dateFormat = "M月d日(E)"
            return formatter.string(from: self)
        }
    }
    
    /// 時刻文字列
    var timeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// 指定した日数前の日付を取得
    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
    
    /// 指定した日数後の日付を取得
    func daysLater(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}
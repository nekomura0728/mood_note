import WidgetKit
import SwiftUI

/// ロック画面ウィジェット（AccessoryRectangular）
struct MoodLockScreenWidget: Widget {
    let kind: String = "MoodLockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoodTimelineProvider()) { entry in
            // エントリーの安全性チェック
            if entry.date.timeIntervalSince1970 > 0 {
                MoodLockScreenWidgetView(entry: entry)
            } else {
                // フォールバックビュー
                MoodLockScreenWidgetView(entry: MoodTimelineEntry(
                    date: Date(),
                    todayMood: nil,
                    todayText: nil,
                    timestamp: nil,
                    recentMoods: []
                ))
            }
        }
        .configurationDisplayName("今日の気分")
        .description("今日の気分記録状況を表示します")
        .supportedFamilies([.accessoryRectangular])
    }
}

/// ロック画面ウィジェットのView
struct MoodLockScreenWidgetView: View {
    var entry: MoodTimelineEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // ヘッダー行
            HStack(spacing: 8) {
                Text("きぶん日記")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let mood = entry.todayMood {
                    Text(mood.emoji)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "heart")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // 状態表示行
            if let mood = entry.todayMood, let timestamp = entry.timestamp {
                HStack {
                    Text(mood.displayName)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(timestamp))
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("今日はまだ未記録")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            // テキスト表示行（オプション）
            if let text = entry.todayText, 
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(text)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        let result = formatter.string(from: date)
        return result.isEmpty ? "時刻不明" : result
    }
}

#Preview("ロック画面 - 記録あり", as: .accessoryRectangular) {
    MoodLockScreenWidget()
} timeline: {
    MoodTimelineEntry(
        date: Date(),
        todayMood: Mood.happy,
        todayText: "今日はとても良い1日でした！",
        timestamp: Date(),
        recentMoods: []
    )
    
    MoodTimelineEntry(
        date: Date(),
        todayMood: nil,
        todayText: nil,
        timestamp: nil,
        recentMoods: []
    )
}
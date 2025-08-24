import WidgetKit
import SwiftUI

/// ホーム画面ウィジェット（Small/Medium）
struct MoodHomeScreenWidget: Widget {
    let kind: String = "MoodHomeScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoodTimelineProvider()) { entry in
            // エントリーの安全性チェックとフォールバック
            if entry.date.timeIntervalSince1970 > 0 {
                MoodHomeScreenWidgetView(entry: entry)
            } else {
                // フォールバックビュー
                MoodHomeScreenWidgetView(entry: MoodTimelineEntry(
                    date: Date(),
                    todayMood: nil,
                    todayText: nil,
                    timestamp: nil,
                    recentMoods: []
                ))
            }
        }
        .configurationDisplayName(NSLocalizedString("widget.home.title", comment: ""))
        .description(NSLocalizedString("widget.home.description", comment: ""))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// ホーム画面ウィジェットのView
struct MoodHomeScreenWidgetView: View {
    var entry: MoodTimelineEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            smallWidgetView
        }
    }
    
    // MARK: - Small Widget
    
    private var smallWidgetView: some View {
        VStack(spacing: 8) {
            // ヘッダー
            HStack {
                Text(NSLocalizedString("widget.home.title", comment: ""))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Spacer()
            
            // 今日の気分
            if let mood = entry.todayMood {
                VStack(spacing: 4) {
                    Text(mood.emoji)
                        .font(.system(size: 32))
                    
                    Text("\(NSLocalizedString("widget.today_prefix", comment: ""))\(mood.displayName)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("widget.record_prompt", comment: ""))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(widgetBackground)
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }
    
    // MARK: - Medium Widget
    
    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("widget.home.title", comment: ""))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("widget.recent_days", comment: ""))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 今日の気分
                if let mood = entry.todayMood {
                    VStack(spacing: 2) {
                        Text(mood.emoji)
                            .font(.system(size: 20))
                        Text(NSLocalizedString("date.today", comment: ""))
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        Text(NSLocalizedString("date.today", comment: ""))
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 直近7日間の気分
            HStack(spacing: 8) {
                ForEach(Array(entry.recentMoods.prefix(7).enumerated()), id: \.offset) { index, mood in
                    VStack(spacing: 4) {
                        if let mood = mood {
                            Text(mood.emoji)
                                .font(.system(size: 20))
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 16, height: 16)
                        }
                        
                        Text(dayLabel(for: index))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 7日未満の場合は空のスロットを表示
                ForEach(entry.recentMoods.count..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                        
                        Text(dayLabel(for: index))
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(widgetBackground)
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }
    
    // MARK: - Helper Views
    
    private var widgetBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.9, blue: 0.9, opacity: 0.8),
                Color(red: 0.9, green: 0.95, blue: 1.0, opacity: 0.8),
                Color(red: 0.94, green: 0.9, blue: 1.0, opacity: 0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Helper Methods
    
    private func dayLabel(for index: Int) -> String {
        guard index >= 0 && index < 7 else {
            return ""
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        guard let date = calendar.date(byAdding: .day, value: -6 + index, to: today) else {
            // フォールバックとして単純な数値を返す
            return "\(index + 1)"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale.current
        let result = formatter.string(from: date)
        return result.isEmpty ? "\(index + 1)" : result
    }
}

#Preview("ホーム画面 Small", as: .systemSmall) {
    MoodHomeScreenWidget()
} timeline: {
    MoodTimelineEntry(
        date: Date(),
        todayMood: Mood.happy,
        todayText: NSLocalizedString("widget.sample_text", comment: ""),
        timestamp: Date(),
        recentMoods: [Mood.tired, Mood.normal, Mood.happy, Mood.angry, Mood.sleepy, Mood.normal, Mood.happy]
    )
}

#Preview("ホーム画面 Medium", as: .systemMedium) {
    MoodHomeScreenWidget()
} timeline: {
    MoodTimelineEntry(
        date: Date(),
        todayMood: Mood.happy,
        todayText: NSLocalizedString("widget.sample_text", comment: ""),
        timestamp: Date(),
        recentMoods: [Mood.tired, Mood.normal, Mood.happy, Mood.angry, Mood.sleepy, Mood.normal, Mood.happy]
    )
}
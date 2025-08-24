import SwiftUI

/// エントリーカードコンポーネント
struct EntryCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: MoodEntry
    let showDate: Bool
    
    init(entry: MoodEntry, showDate: Bool = true) {
        self.entry = entry
        self.showDate = showDate
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 気分スタンプと時間（コンパクトに）
            if let mood = entry.moodEnum {
                VStack(spacing: 4) {
                    Text(mood.emoji)
                        .font(.system(size: 36))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.moodColor(for: mood, colorScheme: colorScheme))
                                .opacity(0.3)
                        )
                    
                    // 時刻を絵文字の下に表示
                    Text(entry.formattedTime)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            // テキストコンテンツ（シンプルに）
            VStack(alignment: .leading, spacing: 6) {
                // 日付表示（タイムラインでのみ）
                if showDate {
                    Text(entry.formattedDate)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // テキスト
                if let text = entry.text, !text.isEmpty {
                    Text(text)
                        .font(Theme.bodyFont)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // テキストがない場合は気分の名前を表示
                    if let mood = entry.moodEnum {
                        Text(mood.displayName)
                            .font(Theme.bodyFont)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground(for: colorScheme))
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity(for: colorScheme)),
                    radius: Theme.cardShadowRadius,
                    x: 0,
                    y: 2
                )
        )
    }
}

// MARK: - プレビュー用のサンプルデータ

#Preview {
    VStack(spacing: 16) {
        // テキスト付きエントリー
        EntryCard(entry: {
            let entry = MoodEntry(mood: .happy, text: "今日はとても良い1日でした！新しいプロジェクトが始まってワクワクしています。")
            return entry
        }())
        
        // テキストなしエントリー
        EntryCard(entry: {
            let entry = MoodEntry(mood: .tired)
            return entry
        }())
        
        // 別の気分
        EntryCard(entry: {
            let entry = MoodEntry(mood: .angry, text: "電車が遅延して大変でした")
            return entry
        }())
    }
    .padding()
}
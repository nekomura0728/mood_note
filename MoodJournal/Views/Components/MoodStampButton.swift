import SwiftUI

/// 気分スタンプボタンコンポーネント
struct MoodStampButton: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // スタンプ
                Text(mood.emoji)
                    .font(.system(size: 40))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                // ラベル
                Text(mood.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(isSelected ? Color.moodColor(for: mood) : Color.white)
                    .shadow(
                        color: Color.moodColor(for: mood).opacity(isSelected ? 0.3 : 0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                Circle()
                    .stroke(
                        Color.moodColor(for: mood),
                        lineWidth: isSelected ? 3 : 0
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(Theme.defaultAnimation, value: isSelected)
    }
}

#Preview {
    HStack(spacing: 20) {
        MoodStampButton(mood: .happy, isSelected: false) { }
        MoodStampButton(mood: .normal, isSelected: true) { }
        MoodStampButton(mood: .tired, isSelected: false) { }
    }
    .padding()
}
import SwiftUI

/// 気分スタンプボタンコンポーネント
struct MoodStampButton: View {
    @Environment(\.colorScheme) private var colorScheme
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
                    .fill(isSelected ? 
                        Color.moodColor(for: mood, colorScheme: colorScheme) : 
                        (colorScheme == .dark ? Color(hex: "2C2C3E") : Color.white))
                    .shadow(
                        color: Color.moodColor(for: mood, colorScheme: colorScheme).opacity(isSelected ? 0.3 : 0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                Circle()
                    .stroke(
                        Color.moodColor(for: mood, colorScheme: colorScheme),
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
import SwiftUI

/// 記録画面
struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataController = DataController.shared
    
    @State private var selectedMood: Mood? = nil
    @State private var moodText: String = ""
    @State private var showSuccess = false
    @State private var textFieldFocused = false
    
    private let maxTextLength = 140
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダー
                    headerSection
                    
                    // 気分スタンプ選択
                    moodSelectionSection
                    
                    // テキスト入力
                    textInputSection
                    
                    // 保存ボタン
                    saveButtonSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Theme.gradientBackground.ignoresSafeArea())
        .animation(Theme.defaultAnimation, value: selectedMood)
        .overlay(
            // 成功フィードバック
            successOverlay
        )
    }
    
    // MARK: - Views
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("今日の気分")
                .font(Theme.titleFont)
                .foregroundColor(.primary)
            
            Text("スタンプを選んで気分を記録しましょう")
                .font(Theme.bodyFont)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var moodSelectionSection: some View {
        VStack(spacing: 20) {
            Text("気分を選んでください")
                .font(Theme.bodyFont)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    MoodStampButton(
                        mood: mood,
                        isSelected: selectedMood == mood
                    ) {
                        withAnimation(Theme.defaultAnimation) {
                            selectedMood = mood
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ひとこと（任意）")
                    .font(Theme.bodyFont)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(moodText.count)/\(maxTextLength)")
                    .font(Theme.captionFont)
                    .foregroundColor(moodText.count > maxTextLength ? .red : .secondary)
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Theme.buttonCornerRadius)
                    .fill(Color(uiColor: .systemGray6))
                    .frame(minHeight: 100)
                
                if moodText.isEmpty && !textFieldFocused {
                    Text("今日はどんな1日でしたか？")
                        .font(Theme.bodyFont)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $moodText)
                    .font(Theme.bodyFont)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .onTapGesture {
                        textFieldFocused = true
                    }
                    .onChange(of: moodText) { oldValue, newValue in
                        if newValue.count > maxTextLength {
                            moodText = String(newValue.prefix(maxTextLength))
                        }
                    }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private var saveButtonSection: some View {
        Button(action: saveEntry) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("記録する")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: Theme.buttonCornerRadius)
                    .fill(
                        selectedMood != nil
                        ? LinearGradient(
                            colors: [
                                Color.moodColor(for: selectedMood!)
                                    .adjustedSaturation(1.3)
                                    .opacity(0.9),
                                Color.moodColor(for: selectedMood!)
                                    .adjustedSaturation(1.5)
                                    .opacity(1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color.gray.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .disabled(selectedMood == nil)
        }
        .animation(Theme.defaultAnimation, value: selectedMood)
    }
    
    private var successOverlay: some View {
        Group {
            if showSuccess {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("記録しました！")
                        .font(Theme.titleFont)
                        .foregroundColor(.primary)
                    
                    if let mood = selectedMood {
                        Text(mood.emoji)
                            .font(.system(size: 40))
                    }
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .fill(Theme.cardBackground)
                        .shadow(
                            color: .black.opacity(0.2),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccess)
    }
    
    // MARK: - Actions
    
    private func saveEntry() {
        guard let mood = selectedMood else {
            print("[RecordView] No mood selected")
            return
        }
        
        print("[RecordView] Saving entry with mood: \(mood.displayName)")
        
        let text = moodText.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalText = text.isEmpty ? nil : text
        
        // 安全にエントリーを作成（エラーハンドリング修正）
        dataController.createEntry(mood: mood, text: finalText)
        
        // 成功フィードバック表示
        withAnimation {
            showSuccess = true
        }
        
        print("[RecordView] Entry saved successfully")
        
        // 2秒後にリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSuccess = false
                selectedMood = nil
                moodText = ""
                textFieldFocused = false
            }
        }
    }
}

#Preview {
    RecordView()
}
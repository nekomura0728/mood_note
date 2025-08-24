import SwiftUI

/// パーソナルコーチング表示画面
struct PersonalCoachingView: View {
    @StateObject private var coachingSystem = PersonalCoachingSystem()
    @StateObject private var proManager = ProManager.shared
    @State private var showProUpgrade = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground.ignoresSafeArea()
                
                if !proManager.isPro {
                    proUpgradePrompt
                } else {
                    mainContent
                }
            }
            .navigationTitle("パーソナルコーチ")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if proManager.isPro {
                    Task {
                        await coachingSystem.generatePersonalCoaching()
                    }
                }
            }
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
        }
    }
    
    // MARK: - Pro Upgrade Prompt
    
    private var proUpgradePrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("パーソナルコーチ")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("気分パターンを分析し、\n具体的なアドバイスを提供します")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: { showProUpgrade = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("Pro版で解除")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // 現在のコーチング
                if let currentCoaching = coachingSystem.currentCoaching {
                    currentCoachingCard(currentCoaching)
                } else if coachingSystem.isGenerating {
                    loadingCard
                } else {
                    generateCoachingCard
                }
                
                // 履歴
                if !coachingSystem.coachingHistory.isEmpty {
                    historySection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .refreshable {
            await coachingSystem.generatePersonalCoaching()
        }
    }
    
    // MARK: - Current Coaching Card
    
    private func currentCoachingCard(_ coaching: PersonalCoaching) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("パーソナルコーチング")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(coaching.dateText)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // パターンバッジ
                HStack(spacing: 6) {
                    Text(coaching.moodPattern.emoji)
                        .font(.system(size: 16))
                    
                    Text(coaching.moodPattern.displayName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: coaching.moodPattern.color))
                )
            }
            
            // メインアドバイス
            VStack(alignment: .leading, spacing: 12) {
                Text("アドバイス")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(coaching.primaryAdvice)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.primary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: coaching.moodPattern.color).opacity(0.1))
            )
            
            // アクションアイテム
            if !coaching.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("今日からできること")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    ForEach(coaching.actionItems.indices, id: \.self) { index in
                        ActionItemRow(
                            item: coaching.actionItems[index],
                            index: index + 1
                        )
                    }
                }
            }
            
            // 次のステップ
            if !coaching.nextSteps.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("次のステップ")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    ForEach(coaching.nextSteps.indices, id: \.self) { index in
                        NextStepRow(
                            step: coaching.nextSteps[index],
                            index: index + 1
                        )
                    }
                }
            }
            
            // 分析データ
            analysisDataSection(coaching.analysisData)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Analysis Data Section
    
    private func analysisDataSection(_ data: PersonalCoachingData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("分析データ")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                AnalysisMetricCard(
                    title: "平均気分",
                    value: String(format: "%.1f", data.averageMood),
                    subtitle: "スコア",
                    color: data.averageMood > 0 ? .green : .orange
                )
                
                AnalysisMetricCard(
                    title: "記録の安定性",
                    value: "\(Int(data.consistency * 100))",
                    subtitle: "%",
                    color: .blue
                )
                
                AnalysisMetricCard(
                    title: "最近の傾向",
                    value: data.recentTrend > 0 ? "↗️" : data.recentTrend < 0 ? "↘️" : "→",
                    subtitle: data.recentTrend > 0 ? "改善" : data.recentTrend < 0 ? "注意" : "安定",
                    color: data.recentTrend > 0 ? .green : data.recentTrend < 0 ? .red : .gray
                )
                
                AnalysisMetricCard(
                    title: "変動性",
                    value: data.volatility > 0.6 ? "高" : data.volatility > 0.3 ? "中" : "低",
                    subtitle: "",
                    color: data.volatility > 0.6 ? .orange : .blue
                )
            }
        }
    }
    
    // MARK: - Loading Card
    
    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("コーチングを生成中...")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Generate Coaching Card
    
    private var generateCoachingCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("パーソナルコーチングを生成")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("過去2週間の記録から\nあなた専用のアドバイスを生成します")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await coachingSystem.generatePersonalCoaching()
                }
            }) {
                Text("コーチングを生成")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("過去のコーチング")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            ForEach(coachingSystem.coachingHistory.prefix(3), id: \.id) { coaching in
                HistoryCoachingCard(coaching: coaching)
            }
        }
    }
}

// MARK: - Supporting Views

/// アクションアイテム行
struct ActionItemRow: View {
    let item: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.blue))
            
            Text(item)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(4)
            
            Spacer()
        }
    }
}

/// 次のステップ行
struct NextStepRow: View {
    let step: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            
            Text(step)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(4)
            
            Spacer()
        }
    }
}

/// 分析メトリクスカード
struct AnalysisMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                        .offset(y: -2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

/// 履歴コーチングカード
struct HistoryCoachingCard: View {
    let coaching: PersonalCoaching
    
    var body: some View {
        HStack(spacing: 12) {
            Text(coaching.moodPattern.emoji)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(coaching.dateText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(coaching.moodPattern.displayName)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: coaching.moodPattern.color))
                        )
                }
                
                Text(coaching.primaryAdvice)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(0.05),
                    radius: 4,
                    x: 0, y: 1
                )
        )
    }
}

#Preview {
    PersonalCoachingView()
}
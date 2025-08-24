import SwiftUI

/// 週次インサイト表示画面
struct WeeklyInsightsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var insightGenerator = WeeklyInsightGenerator()
    @StateObject private var proManager = ProManager.shared
    @State private var selectedInsight: WeeklyInsight?
    @State private var showProUpgrade = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground(for: colorScheme).ignoresSafeArea()
                
                if !proManager.isPro {
                    proUpgradePrompt
                } else {
                    mainContent
                }
            }
            .navigationTitle("weekly_insights.title")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if proManager.isPro {
                    Task {
                        await insightGenerator.generateWeeklyInsight()
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
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("週次インサイト")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("1週間の気分を振り返り、\n温かいコメントでまとめます")
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
                        colors: [.orange, .orange.opacity(0.8)],
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
                // 現在のインサイト
                if let currentInsight = insightGenerator.currentInsight {
                    currentInsightCard(currentInsight)
                } else if insightGenerator.isGenerating {
                    loadingCard
                } else {
                    generateInsightCard
                }
                
                // 履歴
                if !insightGenerator.insightHistory.isEmpty {
                    historySection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .refreshable {
            await insightGenerator.generateWeeklyInsight()
        }
    }
    
    // MARK: - Current Insight Card
    
    private func currentInsightCard(_ insight: WeeklyInsight) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今週のインサイト")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(insight.weekRangeText)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(insight.dominantMood.emoji)
                    .font(.system(size: 32))
            }
            
            // メインコンテンツ
            Text(insight.content)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            // ハイライト
            if !insight.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ハイライト")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    ForEach(insight.highlights, id: \.self) { highlight in
                        Text(highlight)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.moodColor(for: insight.dominantMood).opacity(0.1))
                )
            }
            
            // エンカレッジメント
            Text(insight.encouragement)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            
            // 来週の focus
            VStack(alignment: .leading, spacing: 8) {
                Text("来週のフォーカス")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text(insight.nextWeekFocus)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            // 統計情報
            HStack(spacing: 20) {
                StatItem(
                    title: "記録日数",
                    value: "\(insight.recordingDays)",
                    subtitle: "日"
                )
                
                StatItem(
                    title: "主な気分",
                    value: insight.dominantMood.displayName,
                    subtitle: ""
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground(for: colorScheme))
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity(for: colorScheme)),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Loading Card
    
    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("インサイトを生成中...")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground(for: colorScheme))
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity(for: colorScheme)),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - Generate Insight Card
    
    private var generateInsightCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("週次インサイトを生成")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("過去1週間の記録から\n気分の傾向とアドバイスを生成します")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await insightGenerator.generateWeeklyInsight()
                }
            }) {
                Text("インサイトを生成")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
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
                .fill(Theme.cardBackground(for: colorScheme))
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity(for: colorScheme)),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("過去のインサイト")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            ForEach(insightGenerator.insightHistory.prefix(5), id: \.id) { insight in
                HistoryInsightCard(insight: insight) {
                    selectedInsight = insight
                }
            }
        }
    }
}

/// 統計アイテムコンポーネント
struct StatItem: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                        .offset(y: -1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 履歴インサイトカード
struct HistoryInsightCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let insight: WeeklyInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(insight.dominantMood.emoji)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.weekRangeText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(insight.content)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground(for: colorScheme))
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 4,
                        x: 0, y: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WeeklyInsightsView()
}
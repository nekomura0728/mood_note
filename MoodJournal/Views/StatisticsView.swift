import SwiftUI
import UIKit

/// 統計画面（Pro版機能）
struct StatisticsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var dataController = DataController.shared
    @StateObject private var proManager = ProManager.shared
    @State private var selectedPeriod: StatisticsPeriod = .month
    @State private var moodStatistics: [Mood: Int] = [:]
    @State private var totalEntries = 0
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground(for: colorScheme).ignoresSafeArea()
                
                if !proManager.isPro {
                    proUpgradeView
                } else if isLoading {
                    ProgressView(NSLocalizedString("statistics.calculating", comment: ""))
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    scrollContent
                }
            }
            .navigationTitle(LocalizedStringKey("statistics.title"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadStatistics()
            }
        }
    }
    
    // MARK: - Views
    
    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 期間選択
                periodSelector
                
                // 概要
                overviewSection
                
                // 気分分布チャート
                if totalEntries > 0 {
                    // パーソナルコーチング
                    personalCoachingCard
                    
                    // きぶん分布
                    detailedStatistics
                } else {
                    emptyStateView
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
    
    private var periodSelector: some View {
        Picker(NSLocalizedString("statistics.period", comment: ""), selection: $selectedPeriod) {
            ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                Text(period.displayName)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedPeriod) { _, _ in
            loadStatistics()
        }
        .padding(.horizontal)
    }
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(NSLocalizedString("statistics.overview", comment: ""))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
            }
            
            HStack(spacing: 20) {
                // 総記録数
                StatCard(
                    title: NSLocalizedString("statistics.total_entries", comment: ""),
                    value: "\(totalEntries)",
                    subtitle: NSLocalizedString("statistics.entries_unit", comment: ""),
                    color: .blue
                )
                
                // 記録日数
                StatCard(
                    title: NSLocalizedString("statistics.record_days", comment: ""),
                    value: "\(uniqueDaysCount)",
                    subtitle: NSLocalizedString("statistics.days_unit", comment: ""),
                    color: .green
                )
            }
            
            // 最多気分
            if let mostFrequentMood = mostFrequentMood {
                HStack {
                    Text(NSLocalizedString("statistics.most_frequent_mood", comment: ""))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text(mostFrequentMood.emoji)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(mostFrequentMood.displayName)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            
                            Text(String.localizedStringWithFormat(NSLocalizedString("statistics.times_format", comment: ""), moodStatistics[mostFrequentMood] ?? 0))
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                        .fill(Color.moodColor(for: mostFrequentMood, colorScheme: colorScheme).opacity(0.1))
                )
            }
        }
        .padding(20)
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
    
    private var moodDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("statistics.mood_distribution", comment: ""))
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            // 簡易円グラフ（Chartsの代替）
            HStack {
                // 円グラフ
                ZStack {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        let count = moodStatistics[mood] ?? 0
                        if count > 0 {
                            let percentage = Double(count) / Double(totalEntries)
                            Circle()
                                .trim(from: 0, to: percentage)
                                .stroke(Color.moodColor(for: mood, colorScheme: colorScheme), lineWidth: 20)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                        }
                    }
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 80, height: 80)
                }
                .frame(width: 120, height: 120)
                
                Spacer()
                
                // 凡例
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        let count = moodStatistics[mood] ?? 0
                        if count > 0 {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.moodColor(for: mood, colorScheme: colorScheme))
                                    .frame(width: 12, height: 12)
                                
                                Text(mood.displayName)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
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
    
    private var detailedStatistics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("statistics.mood_distribution", comment: ""))
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            VStack(spacing: 12) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    let count = moodStatistics[mood] ?? 0
                    let percentage = totalEntries > 0 ? Double(count) / Double(totalEntries) * 100 : 0
                    
                    HStack {
                        Text(mood.emoji)
                            .font(.system(size: 20))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mood.displayName)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            
                            Text(String.localizedStringWithFormat(NSLocalizedString("statistics.count_percentage_format", comment: ""), count, String(format: "%.1f", percentage)))
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // プログレスバー
                        ProgressView(value: percentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.moodColor(for: mood, colorScheme: colorScheme)))
                            .frame(width: 80)
                    }
                }
            }
        }
        .padding(20)
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
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(NSLocalizedString("statistics.no_data", comment: ""))
                .font(Theme.titleFont)
                .foregroundColor(.primary)
            
            Text(NSLocalizedString("statistics.no_data_description", comment: ""))
                .font(Theme.bodyFont)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private var proUpgradeView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                VStack(spacing: 12) {
                    Text(NSLocalizedString("statistics.pro_required", comment: ""))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("statistics.pro_required_description", comment: ""))
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 16) {
                NavigationLink(destination: ProVersionView()) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.white)
                        Text(NSLocalizedString("statistics.upgrade_to_pro", comment: ""))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(NSLocalizedString("settings.pro_price", comment: ""))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Pro Features
    
    
    private var personalCoachingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                Text(NSLocalizedString("statistics.personal_coaching", comment: ""))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Spacer()
                
                Text(NSLocalizedString("statistics.recommended", comment: ""))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            
            Text(generatePersonalCoaching())
                .font(.system(size: 15, design: .rounded))
                .lineLimit(nil)
                .foregroundColor(.primary)
            
        }
        .padding(20)
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
    
    // MARK: - Helper Methods
    
    private func loadStatistics() {
        isLoading = true
        
        let calendar = Calendar.current
        let now = Date()
        let (startDate, endDate) = selectedPeriod.dateRange(from: now)
        
        moodStatistics = dataController.getMoodStatistics(from: startDate, to: endDate)
        totalEntries = moodStatistics.values.reduce(0, +)
        
        isLoading = false
    }
    
    private var mostFrequentMood: Mood? {
        moodStatistics.max(by: { $0.value < $1.value })?.key
    }
    
    private var uniqueDaysCount: Int {
        // 簡易実装：エントリー数をベースにした推定値
        // 実際の実装ではデータベースクエリが必要
        min(totalEntries, selectedPeriod.maxDays)
    }
    
    // MARK: - AI Analysis Functions
    
    private func generatePersonalCoaching() -> String {
        let calendar = Calendar.current
        let now = Date()
        let (startDate, endDate) = selectedPeriod.dateRange(from: now)
        
        // 期間内の全エントリーを取得
        let allEntries = dataController.fetchAllEntries()
            .filter { $0.date >= startDate && $0.date <= endDate }
        
        let totalEntries = allEntries.count
        guard totalEntries > 0 else {
            return NSLocalizedString("coaching.no_data", comment: "")
        }
        
        // ロケールを確認して言語を選択
        let isEnglish = Locale.current.language.languageCode?.identifier == "en"
        
        if isEnglish {
            return generateEnglishPersonalCoaching(entries: allEntries, totalEntries: totalEntries)
        } else {
            return generateJapanesePersonalCoaching(entries: allEntries, totalEntries: totalEntries)
        }
    }
    
    private func generateJapanesePersonalCoaching(entries allEntries: [MoodEntry], totalEntries: Int) -> String {
        
        // 基本的な気分統計
        let happyCount = allEntries.filter { $0.moodEnum == .happy }.count
        let normalCount = allEntries.filter { $0.moodEnum == .normal }.count
        let tiredCount = allEntries.filter { $0.moodEnum == .tired }.count
        let angryCount = allEntries.filter { $0.moodEnum == .angry }.count
        let sleepyCount = allEntries.filter { $0.moodEnum == .sleepy }.count
        
        let happyRatio = Double(happyCount) / Double(totalEntries)
        let tiredRatio = Double(tiredCount) / Double(totalEntries)
        let angryRatio = Double(angryCount) / Double(totalEntries)
        let sleepyRatio = Double(sleepyCount) / Double(totalEntries)
        let normalRatio = Double(normalCount) / Double(totalEntries)
        
        // 時間帯分析
        let timePatterns = analyzeTimePatterns(entries: allEntries)
        
        // テキスト分析
        let textInsights = analyzeTextContent(entries: allEntries)
        
        var coaching = ""
        
        // 現状分析（時間パターンを考慮）
        coaching += "【気分パターン分析】\n"
        coaching += generateMoodAnalysis(
            happyRatio: happyRatio,
            tiredRatio: tiredRatio,
            angryRatio: angryRatio,
            sleepyRatio: sleepyRatio,
            normalRatio: normalRatio,
            timePatterns: timePatterns,
            textInsights: textInsights
        )
        
        // 時間帯別インサイト
        if !timePatterns.insights.isEmpty {
            coaching += "\n【時間パターン】\n"
            for insight in timePatterns.insights {
                coaching += "• \(insight)\n"
            }
        }
        
        // テキスト分析インサイト
        if !textInsights.insights.isEmpty {
            coaching += "\n【記録内容からの洞察】\n"
            for insight in textInsights.insights {
                coaching += "• \(insight)\n"
            }
        }
        
        // 具体的改善提案（コンテキストを考慮）
        coaching += "\n【改善アクション】\n"
        let contextualAdvice = generateContextualAdvice(
            moodRatios: (happyRatio, tiredRatio, angryRatio, sleepyRatio, normalRatio),
            timePatterns: timePatterns,
            textInsights: textInsights
        )
        
        for (index, advice) in contextualAdvice.enumerated() {
            coaching += "\(index + 1). \(advice)\n"
        }
        
        // 継続性への言及
        coaching += generateContinuityMessage(totalEntries: totalEntries)
        
        return coaching
    }
    
    private func generateEnglishPersonalCoaching(entries allEntries: [MoodEntry], totalEntries: Int) -> String {
        // Basic mood statistics
        let happyCount = allEntries.filter { $0.moodEnum == .happy }.count
        let normalCount = allEntries.filter { $0.moodEnum == .normal }.count
        let tiredCount = allEntries.filter { $0.moodEnum == .tired }.count
        let angryCount = allEntries.filter { $0.moodEnum == .angry }.count
        let sleepyCount = allEntries.filter { $0.moodEnum == .sleepy }.count
        
        let happyRatio = Double(happyCount) / Double(totalEntries)
        let tiredRatio = Double(tiredCount) / Double(totalEntries)
        let angryRatio = Double(angryCount) / Double(totalEntries)
        let sleepyRatio = Double(sleepyCount) / Double(totalEntries)
        let normalRatio = Double(normalCount) / Double(totalEntries)
        
        // Time pattern analysis
        let timePatterns = analyzeTimePatterns(entries: allEntries)
        
        // Text analysis
        let textInsights = analyzeTextContent(entries: allEntries)
        
        var coaching = ""
        
        // Current status analysis
        coaching += "【Mood Pattern Analysis】\n"
        coaching += generateEnglishMoodAnalysis(
            happyRatio: happyRatio,
            tiredRatio: tiredRatio,
            angryRatio: angryRatio,
            sleepyRatio: sleepyRatio,
            normalRatio: normalRatio,
            timePatterns: timePatterns,
            textInsights: textInsights
        )
        
        // Time-based insights
        if !timePatterns.insights.isEmpty {
            coaching += "\n【Time Patterns】\n"
            for insight in timePatterns.insights {
                coaching += "• \(translateInsightToEnglish(insight))\n"
            }
        }
        
        // Text analysis insights
        if !textInsights.insights.isEmpty {
            coaching += "\n【Content Analysis Insights】\n"
            for insight in textInsights.insights {
                coaching += "• \(translateInsightToEnglish(insight))\n"
            }
        }
        
        // Improvement suggestions
        coaching += "\n【Action Items】\n"
        let contextualAdvice = generateEnglishContextualAdvice(
            moodRatios: (happyRatio, tiredRatio, angryRatio, sleepyRatio, normalRatio),
            timePatterns: timePatterns,
            textInsights: textInsights
        )
        
        for (index, advice) in contextualAdvice.enumerated() {
            coaching += "\(index + 1). \(advice)\n"
        }
        
        // Continuity message
        coaching += generateEnglishContinuityMessage(totalEntries: totalEntries)
        
        return coaching
    }
    
    // MARK: - Time Pattern Analysis
    
    private func analyzeTimePatterns(entries: [MoodEntry]) -> TimePatterns {
        let calendar = Calendar.current
        var morningEntries: [MoodEntry] = []
        var afternoonEntries: [MoodEntry] = []
        var eveningEntries: [MoodEntry] = []
        var nightEntries: [MoodEntry] = []
        
        for entry in entries {
            let hour = calendar.component(.hour, from: entry.date)
            switch hour {
            case 6..<12: morningEntries.append(entry)
            case 12..<17: afternoonEntries.append(entry)
            case 17..<22: eveningEntries.append(entry)
            default: nightEntries.append(entry)
            }
        }
        
        var insights: [String] = []
        
        // 朝の疲労分析
        let morningTiredRatio = Double(morningEntries.filter { $0.moodEnum == .tired || $0.moodEnum == .sleepy }.count) / Double(max(1, morningEntries.count))
        if morningTiredRatio > 0.6 {
            insights.append("朝の時間帯に疲労感が集中しています。睡眠の質や起床時間の見直しが重要です。")
        }
        
        // 夜の感情分析
        let eveningStressRatio = Double(eveningEntries.filter { $0.moodEnum == .angry || $0.moodEnum == .tired }.count) / Double(max(1, eveningEntries.count))
        if eveningStressRatio > 0.5 {
            insights.append("夜の時間帯にストレスや疲労が蓄積する傾向があります。夜間のリラックス時間の確保が効果的です。")
        }
        
        // 午後の落ち込み
        let afternoonLowRatio = Double(afternoonEntries.filter { $0.moodEnum == .tired || $0.moodEnum == .sleepy }.count) / Double(max(1, afternoonEntries.count))
        if afternoonLowRatio > 0.4 {
            insights.append("午後に体調が下がる傾向があります。昼食後の軽い散歩や適度な休憩が効果的です。")
        }
        
        // 夜更かしパターン
        let lateNightEntries = entries.filter { calendar.component(.hour, from: $0.date) >= 23 }
        if lateNightEntries.count > entries.count / 3 {
            insights.append("夜遅い時間の記録が多く見られます。早めの就寝を意識することで朝の気分改善が期待できます。")
        }
        
        return TimePatterns(
            morningMood: getMostFrequentMood(morningEntries),
            afternoonMood: getMostFrequentMood(afternoonEntries),
            eveningMood: getMostFrequentMood(eveningEntries),
            nightMood: getMostFrequentMood(nightEntries),
            insights: insights
        )
    }
    
    // MARK: - Text Content Analysis
    
    private func analyzeTextContent(entries: [MoodEntry]) -> TextInsights {
        var insights: [String] = []
        var stressKeywords: [String: Int] = [:]
        var positiveKeywords: [String: Int] = [:]
        var healthKeywords: [String: Int] = [:]
        
        // キーワード定義
        let stressWords = ["仕事", "忙しい", "プレッシャー", "締切", "会議", "残業", "疲れた", "ストレス", "イライラ", "大変"]
        let positiveWords = ["楽しい", "嬉しい", "達成", "成功", "良い", "最高", "幸せ", "満足", "充実", "リラックス"]
        let healthWords = ["運動", "散歩", "ジョギング", "ジム", "ヨガ", "睡眠", "休息", "瞑想", "マッサージ", "入浴"]
        
        let allTexts = entries.compactMap { $0.text?.lowercased() }.joined(separator: " ")
        
        // キーワードカウント
        for word in stressWords {
            let count = allTexts.components(separatedBy: word).count - 1
            if count > 0 { stressKeywords[word] = count }
        }
        
        for word in positiveWords {
            let count = allTexts.components(separatedBy: word).count - 1
            if count > 0 { positiveKeywords[word] = count }
        }
        
        for word in healthWords {
            let count = allTexts.components(separatedBy: word).count - 1
            if count > 0 { healthKeywords[word] = count }
        }
        
        // インサイト生成
        let totalStressCount = stressKeywords.values.reduce(0, +)
        let totalPositiveCount = positiveKeywords.values.reduce(0, +)
        let totalHealthCount = healthKeywords.values.reduce(0, +)
        
        if totalStressCount > Int(Double(totalEntries) * 0.3) {
            let topStressor = stressKeywords.max(by: { $0.value < $1.value })?.key ?? "仕事関連"
            insights.append("記録から「\(topStressor)」に関するストレスが頻繁に見られます。この分野での対処法を重点的に検討しましょう。")
        }
        
        if totalHealthCount > 0 {
            insights.append("健康的な活動への言及が見られます。これらの良い習慣を継続することが重要です。")
        } else if totalStressCount > totalPositiveCount {
            insights.append("記録にストレス関連の内容が多く、健康活動の言及が少ない傾向です。運動や休息の時間を意識的に作ることを検討してください。")
        }
        
        if totalPositiveCount > Int(Double(totalEntries) * 0.4) {
            insights.append("記録にポジティブな内容が多く含まれています。現在の良い状態を維持する要因を分析し、継続していきましょう。")
        }
        
        return TextInsights(
            stressIndicators: stressKeywords,
            positiveIndicators: positiveKeywords,
            healthIndicators: healthKeywords,
            insights: insights
        )
    }
    
    // MARK: - Helper Methods for Enhanced Analysis
    
    private func generateMoodAnalysis(happyRatio: Double, tiredRatio: Double, angryRatio: Double, sleepyRatio: Double, normalRatio: Double, timePatterns: TimePatterns, textInsights: TextInsights) -> String {
        var analysis = ""
        
        // 基本分析にコンテキストを追加
        if happyRatio > 0.6 {
            analysis += "非常に良好な精神状態を保てています（\(String(format: "%.0f", happyRatio * 100))%がポジティブ）。"
        } else if happyRatio > 0.3 && normalRatio > 0.4 {
            analysis += "安定した気分を保てており、適度にポジティブな瞬間もあります。"
        } else if tiredRatio > 0.4 {
            analysis += "疲労感が目立っています（\(String(format: "%.0f", tiredRatio * 100))%）。"
            // 時間帯コンテキストを追加
            if timePatterns.morningMood == .tired || timePatterns.morningMood == .sleepy {
                analysis += "特に朝の疲労が顕著で、睡眠の質に課題がありそうです。"
            }
        } else if angryRatio > 0.3 {
            analysis += "ストレス要因が多く見受けられます（\(String(format: "%.0f", angryRatio * 100))%がストレス関連）。"
        } else if sleepyRatio > 0.4 {
            analysis += "睡眠の問題が顕著です（\(String(format: "%.0f", sleepyRatio * 100))%）。"
        } else {
            analysis += "様々な気分の変化が見られます。"
        }
        
        return analysis + "\n"
    }
    
    private func generateContextualAdvice(moodRatios: (Double, Double, Double, Double, Double), timePatterns: TimePatterns, textInsights: TextInsights) -> [String] {
        let (happyRatio, tiredRatio, angryRatio, sleepyRatio, normalRatio) = moodRatios
        var advice: [(priority: Int, text: String)] = []
        
        // 睡眠問題（時間パターンを考慮）
        if sleepyRatio > 0.3 || tiredRatio > 0.4 || timePatterns.morningMood == .tired {
            if timePatterns.morningMood == .tired {
                advice.append((priority: 10, text: "朝の疲労が見られます。就寝時刻を1時間早め、寝室環境を整えてください"))
            } else {
                advice.append((priority: 10, text: "睡眠時間を7-8時間確保し、就寝2時間前はスマホを控える"))
            }
        }
        
        // ストレス管理（テキスト分析を考慮）
        if angryRatio > 0.25 {
            let hasWorkStress = textInsights.stressIndicators.keys.contains { ["仕事", "忙しい", "締切", "会議"].contains($0) }
            if hasWorkStress {
                advice.append((priority: 8, text: "仕事関連のストレスが見られます。作業の優先順位付けと適切な休憩時間の確保を意識してください"))
            } else {
                advice.append((priority: 8, text: "1日10分の瞑想や深呼吸を習慣化する"))
            }
        }
        
        // 疲労対策（時間パターンを考慮）
        if tiredRatio > 0.3 {
            if timePatterns.afternoonMood == .tired {
                advice.append((priority: 7, text: "午後の疲労が目立ちます。昼食後に15分程度の軽い散歩を取り入れてください"))
            } else {
                advice.append((priority: 7, text: "週3回、15分の軽い運動（散歩など）を取り入れる"))
            }
        }
        
        // ポジティブ習慣強化（テキスト分析を考慮）
        if happyRatio > 0.4 {
            advice.append((priority: 6, text: "現在の良い状態を維持するため、記録に現れるポジティブな活動を継続してください"))
        } else if normalRatio > 0.5 {
            if textInsights.healthIndicators.isEmpty {
                advice.append((priority: 6, text: "気分向上のため、運動や趣味など楽しめる活動を週2-3回取り入れてください"))
            } else {
                advice.append((priority: 6, text: "感謝日記を書き、1日3つの良かったことを記録する"))
            }
        }
        
        // 環境改善
        if timePatterns.eveningMood == .angry || textInsights.stressIndicators.count > 3 {
            advice.append((priority: 5, text: "夜の時間にリラックスできる環境を整え、ストレス発散の時間を作ってください"))
        }
        
        // 優先度順にソートして上位3つを返す
        let sortedAdvice = advice.sorted { $0.priority > $1.priority }
        return Array(sortedAdvice.prefix(3).map { $0.text })
    }
    
    private func getMostFrequentMood(_ entries: [MoodEntry]) -> Mood? {
        guard !entries.isEmpty else { return nil }
        
        let moodCounts = Dictionary(grouping: entries, by: { $0.moodEnum }).mapValues { $0.count }
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private func generateContinuityMessage(totalEntries: Int) -> String {
        if totalEntries >= 7 {
            return "\n✨ 継続的な記録により、時間パターンやテキスト分析を含む精密な分析が可能になっています。"
        } else if totalEntries >= 3 {
            return "\n📈 記録を続けることで、時間帯やテキスト内容を考慮したより詳細な分析とアドバイスを提供できます。"
        } else {
            return "\n🔄 より多くのデータが蓄積されると、個人に最適化されたコンテキスト分析を提供できます。"
        }
    }
    
    // MARK: - English Analysis Functions
    
    private func generateEnglishMoodAnalysis(happyRatio: Double, tiredRatio: Double, angryRatio: Double, sleepyRatio: Double, normalRatio: Double, timePatterns: TimePatterns, textInsights: TextInsights) -> String {
        var analysis = ""
        
        if happyRatio > 0.6 {
            analysis += "You're maintaining excellent mental well-being (\\(String(format: \"%.0f\", happyRatio * 100))% positive moods). "
        } else if happyRatio > 0.3 && normalRatio > 0.4 {
            analysis += "You're maintaining stable moods with moderate positive moments. "
        } else if tiredRatio > 0.4 {
            analysis += "Fatigue is prominent in your records (\\(String(format: \"%.0f\", tiredRatio * 100))%). "
            if timePatterns.morningMood == .tired || timePatterns.morningMood == .sleepy {
                analysis += "Morning fatigue is particularly noticeable, suggesting potential sleep quality issues. "
            }
        } else if angryRatio > 0.3 {
            analysis += "Stress factors are frequently observed (\\(String(format: \"%.0f\", angryRatio * 100))% stress-related). "
        } else if sleepyRatio > 0.4 {
            analysis += "Sleep issues are prominent (\\(String(format: \"%.0f\", sleepyRatio * 100))%). "
        } else {
            analysis += "Various mood changes are observed throughout your records. "
        }
        
        return analysis + "\\n"
    }
    
    private func generateEnglishContextualAdvice(moodRatios: (Double, Double, Double, Double, Double), timePatterns: TimePatterns, textInsights: TextInsights) -> [String] {
        let (happyRatio, tiredRatio, angryRatio, sleepyRatio, normalRatio) = moodRatios
        var advice: [(priority: Int, text: String)] = []
        
        // Sleep issues
        if sleepyRatio > 0.3 || tiredRatio > 0.4 || timePatterns.morningMood == .tired {
            if timePatterns.morningMood == .tired {
                advice.append((priority: 10, text: "Morning fatigue is evident. Try going to bed 1 hour earlier and optimize your sleep environment"))
            } else {
                advice.append((priority: 10, text: "Ensure 7-8 hours of sleep and avoid screens 2 hours before bedtime"))
            }
        }
        
        // Stress management
        if angryRatio > 0.25 {
            let hasWorkStress = textInsights.stressIndicators.keys.contains { ["work", "busy", "deadline", "meeting"].contains($0) }
            if hasWorkStress {
                advice.append((priority: 8, text: "Work-related stress is apparent. Focus on task prioritization and taking appropriate breaks"))
            } else {
                advice.append((priority: 8, text: "Practice 10 minutes of meditation or deep breathing daily"))
            }
        }
        
        // Fatigue management
        if tiredRatio > 0.3 {
            if timePatterns.afternoonMood == .tired {
                advice.append((priority: 7, text: "Afternoon fatigue is noticeable. Take a 15-minute light walk after lunch"))
            } else {
                advice.append((priority: 7, text: "Incorporate light exercise (walking) 3 times per week for 15 minutes"))
            }
        }
        
        // Positive habit reinforcement
        if happyRatio > 0.4 {
            advice.append((priority: 6, text: "Continue the positive activities mentioned in your records to maintain your current good state"))
        } else if normalRatio > 0.5 {
            if textInsights.healthIndicators.isEmpty {
                advice.append((priority: 6, text: "To improve mood, incorporate enjoyable activities like exercise or hobbies 2-3 times per week"))
            } else {
                advice.append((priority: 6, text: "Keep a gratitude journal and record 3 positive things daily"))
            }
        }
        
        // Environment improvement
        if timePatterns.eveningMood == .angry || textInsights.stressIndicators.count > 3 {
            advice.append((priority: 5, text: "Create a relaxing evening environment and allocate time for stress relief activities"))
        }
        
        // Return top 3 prioritized advice
        let sortedAdvice = advice.sorted { $0.priority > $1.priority }
        return Array(sortedAdvice.prefix(3).map { $0.text })
    }
    
    private func generateEnglishContinuityMessage(totalEntries: Int) -> String {
        if totalEntries >= 7 {
            return "\\n✨ Continuous recording enables precise analysis including time patterns and content analysis."
        } else if totalEntries >= 3 {
            return "\\n📈 Continued recording will provide more detailed analysis and advice considering time patterns and content."
        } else {
            return "\\n🔄 More data will enable personalized context analysis optimized for you."
        }
    }
    
    private func translateInsightToEnglish(_ insight: String) -> String {
        // Simple translation mapping for key insights
        if insight.contains("朝の時間帯に疲労感") {
            return "Morning fatigue is concentrated. Reviewing sleep quality and wake-up time is important."
        } else if insight.contains("夜の時間帯にストレスや疲労") {
            return "Stress and fatigue tend to accumulate in evening hours. Securing relaxation time is effective."
        } else if insight.contains("午後に体調が下がる") {
            return "Afternoon energy dips are observed. Light walks after lunch or appropriate rest can be effective."
        } else if insight.contains("夜遅い時間の記録") {
            return "Late-night entries are frequent. Earlier bedtime could improve morning mood."
        } else if insight.contains("ストレス関連の内容が多く") {
            return "Records contain many stress-related content. Consider conscious exercise and rest time."
        } else if insight.contains("健康的な活動への言及") {
            return "References to healthy activities are observed. Continuing these good habits is important."
        } else if insight.contains("ポジティブな内容が多く") {
            return "Records contain many positive contents. Analyze factors maintaining current good state and continue them."
        } else {
            // If no specific translation, return a generic English version
            return "Pattern analysis suggests areas for potential improvement in daily routines."
        }
    }
    
    // MARK: - Data Structures for Enhanced Analysis
    
    private struct TimePatterns {
        let morningMood: Mood?
        let afternoonMood: Mood?
        let eveningMood: Mood?
        let nightMood: Mood?
        let insights: [String]
    }
    
    private struct TextInsights {
        let stressIndicators: [String: Int]
        let positiveIndicators: [String: Int]
        let healthIndicators: [String: Int]
        let insights: [String]
    }
}

/// 統計カードコンポーネント
struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
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
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .offset(y: -2)
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

/// 機能紹介コンポーネント（統計画面用）
struct StatisticsFeatureRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                
                Text(description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// 統計期間の定義
enum StatisticsPeriod: CaseIterable {
    case week
    case month
    case threeMonths
    case year
    
    var displayName: String {
        switch self {
        case .week: return NSLocalizedString("statistics.period.week", comment: "")
        case .month: return NSLocalizedString("statistics.period.month", comment: "")
        case .threeMonths: return NSLocalizedString("statistics.period.three_months", comment: "")
        case .year: return NSLocalizedString("statistics.period.year", comment: "")
        }
    }
    
    var maxDays: Int {
        switch self {
        case .week: return 7
        case .month: return 31
        case .threeMonths: return 92
        case .year: return 365
        }
    }
    
    func dateRange(from date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let endDate = calendar.endOfDay(for: date)
        
        switch self {
        case .week:
            let startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: endDate)!
            return (startDate, endDate)
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
            return (startDate, endDate)
        case .threeMonths:
            let startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!
            return (startDate, endDate)
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
            return (startDate, endDate)
        }
    }
}

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let startOfDay = self.startOfDay(for: date)
        return self.date(byAdding: .day, value: 1, to: startOfDay)! - 1
    }
}

#Preview {
    StatisticsView()
}
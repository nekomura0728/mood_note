import Foundation
import SwiftData
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

/// データ管理コントローラー
@MainActor
class DataController: ObservableObject {
    /// SwiftDataコンテナ
    let container: ModelContainer
    
    /// モデルコンテキスト
    let context: ModelContext
    
    
    /// シングルトンインスタンス
    static let shared = DataController()
    
    /// イニシャライザー
    private init() {
        print("[DataController] Starting initialization...")
        
        do {
            let schema = Schema([
                MoodEntry.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            context = container.mainContext
            
            print("[DataController] ModelContainer created successfully")
            
            // 開発時用：初回起動時にサンプルデータを追加（デバッグビルドのみ）
            #if DEBUG
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.fetchAllEntries().isEmpty {
                    print("[DataController] Adding sample data...")
                    self.addSampleDataIfNeeded()
                } else {
                    print("[DataController] Existing entries found, skipping sample data")
                }
            }
            #endif
            
            print("[DataController] Initialization completed")
            
        } catch {
            print("[DataController] Failed to create ModelContainer: \(error)")
            print("[DataController] Error details: \(error.localizedDescription)")
            
            // フォールバック：インメモリー設定を試す
            do {
                print("[DataController] Attempting fallback to in-memory configuration...")
                let schema = Schema([MoodEntry.self])
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                container = try ModelContainer(for: schema, configurations: [fallbackConfig])
                context = container.mainContext
                print("[DataController] Fallback initialization successful")
            } catch {
                fatalError("Failed to create ModelContainer even with fallback: \(error)")
            }
        }
    }
    
    #if DEBUG
    /// サンプルデータを追加（開発用）
    private func addSampleDataIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        // 過去7日間のサンプルデータを追加
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            
            let sampleMoods: [Mood] = [.happy, .normal, .tired, .angry, .sleepy]
            let randomMood = sampleMoods.randomElement() ?? .normal
            let sampleTexts = [
                "良い1日でした！",
                "普通の日",
                "少し疲れました",
                "ストレスを感じた日",
                "眠い日でした"
            ]
            let randomText = sampleTexts.randomElement()
            
            let entry = MoodEntry(
                mood: randomMood,
                text: randomText,
                timestamp: date
            )
            
            context.insert(entry)
        }
        
        do {
            try context.save()
            updateWidgetData() // ウィジェット用データも更新
            print("Sample data added for development")
        } catch {
            print("Failed to save sample data: \(error)")
        }
    }
    #endif
    
    #if DEBUG
    /// コーチング機能デモ用サンプルデータを追加
    func addDebugSampleData() {
        let calendar = Calendar.current
        let now = Date()
        
        // パーソナルコーチング分析を明確に示すサンプルデータ
        let scenarios = [
            // 1. 朝の疲労パターン（睡眠の質問題）
            (mood: Mood.tired, hour: 7, text: "朝から疲れた。昨夜遅くまでスマホを見てしまった", days: [-1, -3, -5, -7]),
            (mood: Mood.sleepy, hour: 8, text: "全然眠れなかった。寝室が暑い", days: [-2, -4, -6]),
            
            // 2. 仕事ストレスパターン
            (mood: Mood.angry, hour: 17, text: "仕事で締切に追われてイライラ", days: [-1, -2, -3]),
            (mood: Mood.tired, hour: 19, text: "会議が多すぎて疲れた", days: [-4, -5]),
            (mood: Mood.angry, hour: 18, text: "残業続きでストレス溜まる", days: [-6, -8]),
            
            // 3. 午後の体調低下パターン
            (mood: Mood.tired, hour: 14, text: "昼食後に眠気が強い", days: [-1, -3, -5, -7, -9]),
            (mood: Mood.sleepy, hour: 15, text: "午後の会議で眠くなる", days: [-2, -4, -6, -8]),
            
            // 4. 夜更かしパターン
            (mood: Mood.sleepy, hour: 23, text: "夜遅いけど眠れない", days: [-1, -2, -4, -6, -8]),
            (mood: Mood.tired, hour: 0, text: "また夜更かししてしまった", days: [-3, -5, -7]),
            
            // 5. ポジティブ活動
            (mood: Mood.happy, hour: 10, text: "朝の散歩が気持ちいい", days: [-9, -10]),
            (mood: Mood.happy, hour: 20, text: "ヨガをしてリラックスできた", days: [-11]),
            (mood: Mood.happy, hour: 19, text: "ジムで運動して気分爽快", days: [-12]),
            
            // 6. 健康的な生活
            (mood: Mood.normal, hour: 21, text: "早めに休息を取る", days: [-10, -11, -13]),
            (mood: Mood.happy, hour: 12, text: "瞑想で心が落ち着いた", days: [-13, -14]),
            
            // 7. 混合パターン（改善の兆し）
            (mood: Mood.normal, hour: 9, text: "睡眠時間を増やしたら調子が良い", days: [-9, -10, -11]),
            (mood: Mood.happy, hour: 16, text: "仕事の優先順位を整理して楽になった", days: [-12, -13])
        ]
        
        // サンプルデータを追加
        for scenario in scenarios {
            for day in scenario.days {
                guard let date = calendar.date(byAdding: .day, value: day, to: now),
                      let entryTime = calendar.date(bySettingHour: scenario.hour, minute: Int.random(in: 0...59), second: 0, of: date) else { continue }
                
                let entry = MoodEntry(
                    mood: scenario.mood,
                    text: scenario.text,
                    timestamp: entryTime
                )
                
                context.insert(entry)
            }
        }
        
        do {
            try context.save()
            updateWidgetData()
            print("[DataController] Enhanced coaching demo sample data added successfully")
        } catch {
            print("[DataController] Failed to save enhanced sample data: \(error)")
            context.rollback()
        }
    }
    
    /// 重み付きランダムで気分を選択
    private func weightedRandomMood(weights: [Mood: Double]) -> Mood {
        let random = Double.random(in: 0...1)
        var cumulative = 0.0
        
        for (mood, weight) in weights {
            cumulative += weight
            if random <= cumulative {
                return mood
            }
        }
        
        return .normal // フォールバック
    }
    #endif
    
    // MARK: - Create
    
    /// 新しいエントリーを作成
    func createEntry(mood: Mood, text: String?) {
        print("[DataController] Creating entry with mood: \(mood.displayName)")
        
        do {
            let entry = MoodEntry(mood: mood, text: text)
            context.insert(entry)
            
            // コンテキスト保存
            try context.save()
            print("[DataController] Successfully saved entry to Core Data")
            
            // ウィジェット用データを更新（安全に実行）
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                do {
                    self.updateWidgetData()
                    print("[DataController] Widget data updated successfully")
                } catch {
                    print("[DataController] Failed to update widget data: \(error)")
                    // ウィジェット更新の失敗はエントリ作成の成功を妨げない
                }
            }
            
            print("[DataController] Successfully created entry: \(mood.displayName)")
        } catch {
            print("[DataController] Failed to create entry: \(error)")
            print("[DataController] Error details: \(error.localizedDescription)")
            
            // コンテキストをロールバック
            context.rollback()
        }
    }
    
    // MARK: - Read
    
    /// すべてのエントリーを取得
    func fetchAllEntries() -> [MoodEntry] {
        let descriptor = FetchDescriptor<MoodEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch entries: \(error)")
            return []
        }
    }
    
    /// 特定の日付のエントリーを取得
    func fetchEntries(for date: Date) -> [MoodEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<MoodEntry> { entry in
            entry.timestamp >= startOfDay && entry.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch entries for date: \(error)")
            return []
        }
    }
    
    /// 日付範囲のエントリーを取得
    func fetchEntries(from startDate: Date, to endDate: Date) -> [MoodEntry] {
        let predicate = #Predicate<MoodEntry> { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }
        
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch entries for date range: \(error)")
            return []
        }
    }
    
    /// 最新のエントリーを取得
    func fetchLatestEntry(for date: Date) -> MoodEntry? {
        fetchEntries(for: date).first
    }
    
    /// 今日のエントリー数を取得
    func getTodayEntryCount() -> Int {
        fetchEntries(for: Date()).count
    }
    
    /// 今日の最新のムードを取得
    func getTodayLatestMood() -> Mood? {
        fetchLatestEntry(for: Date())?.moodEnum
    }
    
    // MARK: - Update
    
    /// エントリーを更新
    func updateEntry(_ entry: MoodEntry, mood: Mood? = nil, text: String? = nil) {
        if let mood = mood {
            entry.mood = mood.rawValue
        }
        if let text = text {
            entry.text = text.prefix(140).description
        }
        do {
            try save()
        } catch {
            print("[DataController] Failed to update entry: \(error)")
        }
    }
    
    // MARK: - Delete
    
    /// エントリーを削除
    func deleteEntry(_ entry: MoodEntry) {
        context.delete(entry)
        do {
            try save()
        } catch {
            print("[DataController] Failed to delete entry: \(error)")
        }
    }
    
    /// 複数エントリーを削除
    func deleteEntries(_ entries: [MoodEntry]) {
        entries.forEach { context.delete($0) }
        do {
            try save()
        } catch {
            print("[DataController] Failed to delete entries: \(error)")
        }
    }
    
    // MARK: - Statistics
    
    /// 特定期間の気分統計を取得
    func getMoodStatistics(from startDate: Date, to endDate: Date) -> [Mood: Int] {
        let entries = fetchEntries(from: startDate, to: endDate)
        var statistics: [Mood: Int] = [:]
        
        for mood in Mood.allCases {
            statistics[mood] = 0
        }
        
        for entry in entries {
            if let mood = entry.moodEnum {
                statistics[mood]! += 1
            }
        }
        
        return statistics
    }
    
    /// 直近7日間のムードを取得（ウィジェット用）
    func getRecentMoods(days: Int = 7) -> [Mood?] {
        print("[DataController] Fetching recent moods for \(days) days...")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var moods: [Mood?] = []
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let latestEntry = fetchLatestEntry(for: date)
                let mood = latestEntry?.moodEnum
                moods.append(mood)
                print("[DataController] Day -\(i): \(mood?.displayName ?? "なし")")
            } else {
                moods.append(nil)
                print("[DataController] Day -\(i): 日付計算エラー")
            }
        }
        
        let result = moods.reversed()
        print("[DataController] Recent moods result: \(result.count) items")
        return Array(result)
    }
    
    // MARK: - Widget Support
    
    /// ウィジェット用のデータを更新
    private func updateWidgetData() {
        print("[DataController] Updating widget data...")
        
        do {
            // 今日の最新データを更新
            if let todayLatest = fetchLatestEntry(for: Date()),
               let mood = todayLatest.moodEnum {
                SharedDataManager.shared.saveTodayMood(
                    mood,
                    text: todayLatest.text
                )
                print("[DataController] Updated today's mood: \(mood.displayName)")
            } else {
                print("[DataController] No mood entry found for today")
            }
            
            // 直近7日間のデータを更新 - 安全な方式で
            let recentMoods = getRecentMoods(days: 7)
            
            // nil を含まない安全な配列に変換
            let safeMoodStrings: [String] = recentMoods.map { mood in
                if let mood = mood {
                    return mood.rawValue
                } else {
                    return "__EMPTY__" // nil の場合は特殊文字列で代替
                }
            }
            
            print("[DataController] Converted recent moods to safe strings: \(safeMoodStrings)")
            
            // 安全な配列として保存
            SharedDataManager.shared.saveRecentMoodsSafe(safeMoodStrings)
            
            // WidgetKitに更新を通知（バックグラウンドキューで実行）
            #if canImport(WidgetKit)
            DispatchQueue.global(qos: .utility).async {
                WidgetCenter.shared.reloadAllTimelines()
                print("[DataController] Widget timelines reloaded")
            }
            #endif
        } catch {
            print("[DataController] Failed to update widget data: \(error)")
        }
    }
    
    // MARK: - Private
    
    /// データを保存
    private func save() throws {
        do {
            try context.save()
            print("[DataController] Successfully saved data")
        } catch {
            print("[DataController] Failed to save context: \(error)")
            print("[DataController] Error details: \(error.localizedDescription)")
            
            // コンテキストをロールバック
            context.rollback()
            throw error
        }
    }
}
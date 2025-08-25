import Foundation

/// App Group を使用してウィジェットとデータを共有するマネージャー
class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let suiteName = "group.com.moodjournal.data"
    private let userDefaults: UserDefaults
    
    private init() {
        let suiteName = "group.com.moodjournal.data"
        #if DEBUG
        print("[SharedDataManager] Initializing with suite name: \(suiteName)")
        #endif
        
        // より安全な UserDefaults 初期化
        var userDefaults: UserDefaults? = nil
        var attempts = 0
        let maxAttempts = 3
        
        while userDefaults == nil && attempts < maxAttempts {
            attempts += 1
            
            do {
                if let appGroupDefaults = UserDefaults(suiteName: suiteName) {
                    userDefaults = appGroupDefaults
                    #if DEBUG
                    print("[SharedDataManager] Successfully created UserDefaults with App Group (attempt \(attempts))")
                    #endif
                } else {
                    #if DEBUG
                    print("[SharedDataManager] Failed to create App Group UserDefaults (attempt \(attempts))")
                    #endif
                    Thread.sleep(forTimeInterval: 0.1) // 短い待機
                }
            } catch {
                #if DEBUG
                print("[SharedDataManager] Exception creating UserDefaults (attempt \(attempts)): \(error)")
                #endif
            }
        }
        
        if let finalDefaults = userDefaults {
            self.userDefaults = finalDefaults
            
            // 初期化テスト（より安全に）
            let testKey = "init_test_\(Date().timeIntervalSince1970)"
            let testValue = "safe_test_value"
            
            do {
                finalDefaults.set(testValue, forKey: testKey)
                finalDefaults.synchronize() // 強制同期
                
                if finalDefaults.string(forKey: testKey) == testValue {
                    #if DEBUG
                    print("[SharedDataManager] App Group UserDefaults working correctly")
                    #endif
                    finalDefaults.removeObject(forKey: testKey)
                    finalDefaults.synchronize()
                } else {
                    #if DEBUG
                    print("[SharedDataManager] Warning: App Group UserDefaults test failed")
                    #endif
                }
            } catch {
                #if DEBUG
                print("[SharedDataManager] Error during UserDefaults test: \(error)")
                #endif
            }
            
        } else {
            #if DEBUG
            print("[SharedDataManager] Critical Error: Failed to create UserDefaults with suite after \(maxAttempts) attempts")
            print("[SharedDataManager] Falling back to standard UserDefaults")
            #endif
            self.userDefaults = UserDefaults.standard
        }
        
        // 起動時のクリーンアップ（より安全に）
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.cleanupCorruptedData()
        }
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let todayMood = "today_mood"
        static let todayText = "today_text"
        static let todayTimestamp = "today_timestamp"
        static let recentMoods = "recent_moods"
        static let lastUpdateTime = "last_update_time"
    }
    
    // MARK: - Today's Data
    
    /// 今日の最新気分を保存
    func saveTodayMood(_ mood: Mood, text: String? = nil) {
        userDefaults.set(mood.rawValue, forKey: Keys.todayMood)
        userDefaults.set(text, forKey: Keys.todayText)
        userDefaults.set(Date(), forKey: Keys.todayTimestamp)
        userDefaults.set(Date(), forKey: Keys.lastUpdateTime)
    }
    
    /// 今日の最新気分を取得
    func getTodayMood() -> (mood: Mood?, text: String?, timestamp: Date?) {
        guard let moodRawValue = userDefaults.string(forKey: Keys.todayMood),
              !moodRawValue.isEmpty,
              let mood = Mood(rawValue: moodRawValue) else {
            #if DEBUG
            print("[SharedDataManager] No valid mood found for today")
            #endif
            return (nil, nil, nil)
        }
        
        let text = userDefaults.string(forKey: Keys.todayText)
        let timestamp = userDefaults.object(forKey: Keys.todayTimestamp) as? Date
        
        #if DEBUG
        print("[SharedDataManager] Retrieved today's mood: \(mood.rawValue)")
        #endif
        return (mood, text, timestamp)
    }
    
    /// 今日の記録があるかチェック
    func hasTodayRecord() -> Bool {
        guard let timestamp = userDefaults.object(forKey: Keys.todayTimestamp) as? Date else {
            return false
        }
        
        return Calendar.current.isDateInToday(timestamp)
    }
    
    // MARK: - Recent Moods (for Home Screen Widget)
    
    /// 直近の気分データを保存（ウィジェット用）
    func saveRecentMoods(_ moods: [String?]) {
        #if DEBUG
        print("[SharedDataManager] Saving \(moods.count) recent moods...")
        #endif
        
        // 最新7日分に制限
        let limitedMoods = Array(moods.suffix(7))
        
        // nil値を完全に排除してから保存
        let safeMoods: [String] = limitedMoods.compactMap { mood in
            if let mood = mood, !mood.isEmpty {
                return mood
            } else {
                return "__EMPTY__" // nil や空文字列の場合は特殊な文字列で代替
            }
        }
        
        // 追加の安全チェック：配列が空でないことを確認
        let finalMoods = safeMoods.isEmpty ? ["__EMPTY__"] : safeMoods
        
        #if DEBUG
        print("[SharedDataManager] About to save moods: \(finalMoods)")
        #endif
        
        // UserDefaults に保存（nil要素が完全に除去された状態）
        userDefaults.set(finalMoods, forKey: Keys.recentMoods)
        userDefaults.set(Date(), forKey: Keys.lastUpdateTime)
        
        #if DEBUG
        print("[SharedDataManager] Successfully saved recent moods: \(finalMoods)")
        #endif
    }

    /// 安全な気分データ保存（nil を含まない文字列配列）
    func saveRecentMoodsSafe(_ moods: [String]) {
        #if DEBUG
        print("[SharedDataManager] Saving \(moods.count) recent moods (safe version)...")
        #endif
        
        // 最新7日分に制限
        let limitedMoods = Array(moods.suffix(7))
        
        // UserDefaults に直接保存（nil要素なし）
        userDefaults.set(limitedMoods, forKey: Keys.recentMoods)
        userDefaults.set(Date(), forKey: Keys.lastUpdateTime)
        
        #if DEBUG
        print("[SharedDataManager] Successfully saved safe recent moods: \(limitedMoods)")
        #endif
    }
    
    /// 直近の気分データを取得
    func getRecentMoods() -> [Mood?] {
        guard let moodStrings = userDefaults.array(forKey: Keys.recentMoods) as? [String] else {
            #if DEBUG
            print("[SharedDataManager] No recent moods found")
            #endif
            return []
        }
        
        let moods: [Mood?] = moodStrings.map { moodString in
            // 特殊な文字列は nil に戻す
            if moodString == "__EMPTY__" {
                return nil
            }
            return Mood(rawValue: moodString)
        }
        
        #if DEBUG
        print("[SharedDataManager] Retrieved \(moods.count) recent moods")
        #endif
        return moods
    }
    
    // MARK: - Update Management
    
    /// 最後の更新時刻を取得
    func getLastUpdateTime() -> Date? {
        return userDefaults.object(forKey: Keys.lastUpdateTime) as? Date
    }
    
    /// データをクリア（開発用）
    func clearAllData() {
        userDefaults.removeObject(forKey: Keys.todayMood)
        userDefaults.removeObject(forKey: Keys.todayText)
        userDefaults.removeObject(forKey: Keys.todayTimestamp)
        userDefaults.removeObject(forKey: Keys.recentMoods)
        userDefaults.removeObject(forKey: Keys.lastUpdateTime)
    }

    
    /// 破損したデータのクリーンアップ（初期化時に実行）
    private func cleanupCorruptedData() {
        #if DEBUG
        print("[SharedDataManager] Performing cleanup of corrupted data...")
        #endif
        
        do {
            // 既存の recent_moods をチェックして、問題があれば削除
            if let existingMoods = userDefaults.array(forKey: Keys.recentMoods) {
                #if DEBUG
                print("[SharedDataManager] Found existing recent moods data: \(existingMoods)")
                #endif
                
                // 配列に問題がないかチェック
                var hasProblems = false
                
                for (index, element) in existingMoods.enumerated() {
                    if element is NSNull {
                        #if DEBUG
                        print("[SharedDataManager] Found NSNull at index \(index)")
                        #endif
                        hasProblems = true
                        break
                    }
                    
                    // 文字列でない要素があるかチェック
                    if !(element is String) {
                        #if DEBUG
                        print("[SharedDataManager] Found non-string element at index \(index): \(type(of: element))")
                        #endif
                        hasProblems = true
                        break
                    }
                }
                
                if hasProblems {
                    #if DEBUG
                    print("[SharedDataManager] Found corrupted recent moods data, clearing...")
                    #endif
                    userDefaults.removeObject(forKey: Keys.recentMoods)
                    userDefaults.synchronize()
                    #if DEBUG
                    print("[SharedDataManager] Corrupted data cleared successfully")
                    #endif
                } else {
                    #if DEBUG
                    print("[SharedDataManager] Recent moods data is clean")
                    #endif
                }
            } else {
                #if DEBUG
                print("[SharedDataManager] No existing recent moods data found")
                #endif
            }
            
            // その他のキーもチェック
            let allKeys = [Keys.todayMood, Keys.todayText, Keys.todayTimestamp, Keys.lastUpdateTime]
            
            for key in allKeys {
                if let value = userDefaults.object(forKey: key) {
                    if value is NSNull {
                        #if DEBUG
                        print("[SharedDataManager] Found NSNull for key \(key), removing...")
                        #endif
                        userDefaults.removeObject(forKey: key)
                    }
                }
            }
            
            userDefaults.synchronize()
            #if DEBUG
            print("[SharedDataManager] Cleanup completed successfully")
            #endif
            
        } catch {
            #if DEBUG
            print("[SharedDataManager] Error during cleanup: \(error)")
            #endif
        }
    }
}
import WidgetKit
import SwiftUI

/// すべてのウィジェットをまとめるバンドル
@main
struct MoodJournalWidgetBundle: WidgetBundle {
    
    // 初期化時のエラーハンドリング
    init() {
        print("[WidgetBundle] Initializing MoodJournalWidgetBundle")
        
        // SharedDataManagerの初期化確認
        let _ = SharedDataManager.shared
        print("[WidgetBundle] SharedDataManager initialized successfully")
    }
    
    var body: some Widget {
        // 各ウィジェットを安全に初期化
        MoodHomeScreenWidget()
        MoodLockScreenWidget()
    }
}
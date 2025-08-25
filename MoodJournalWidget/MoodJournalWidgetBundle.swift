import WidgetKit
import SwiftUI

/// すべてのウィジェットをまとめるバンドル
@main
struct MoodJournalWidgetBundle: WidgetBundle {
    
    // 初期化時のエラーハンドリング
    init() {
        #if DEBUG
        print("[WidgetBundle] Initializing MoodJournalWidgetBundle")
        #endif
        
        // SharedDataManagerの初期化確認
        let _ = SharedDataManager.shared
        #if DEBUG
        print("[WidgetBundle] SharedDataManager initialized successfully")
        #endif
    }
    
    var body: some Widget {
        // 各ウィジェットを安全に初期化
        MoodHomeScreenWidget()
        MoodLockScreenWidget()
    }
}
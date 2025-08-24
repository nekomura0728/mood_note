import SwiftUI

@main
struct MoodJournalApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(DataController.shared.container)
        }
    }
}

// MARK: - プレビュー用のApp構造

#Preview {
    MainTabView()
        .modelContainer(DataController.shared.container)
}
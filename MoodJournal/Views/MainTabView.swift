import SwiftUI

/// メインタブビュー
struct MainTabView: View {
    @StateObject private var proManager = ProManager.shared
    @State private var selectedTab = 1 // 記録タブを初期選択
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // タイムライン
            TimelineView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text(LocalizedStringKey("tab.timeline"))
                }
                .tag(0)
            
            // 記録
            RecordView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text(LocalizedStringKey("tab.record"))
                }
                .tag(1)
            
            // カレンダー
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text(LocalizedStringKey("tab.calendar"))
                }
                .tag(2)
            
            // レポート
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text(LocalizedStringKey("tab.statistics"))
                }
                .tag(3)
            
            // 設定
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text(LocalizedStringKey("tab.settings"))
                }
                .tag(4)
        }
        .accentColor(.primary)
        .onAppear {
            // タブバーの外観をカスタマイズ
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
            
            // 選択されたタブのアイコン色
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue
            ]
            
            // 未選択タブのアイコン色
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray
            ]
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

#Preview {
    MainTabView()
}
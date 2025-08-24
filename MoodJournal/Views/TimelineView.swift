import SwiftUI

/// タイムライン表示画面
struct TimelineView: View {
    @StateObject private var dataController = DataController.shared
    @State private var entries: [MoodEntry] = []
    @State private var groupedEntries: [(Date, [MoodEntry])] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground.ignoresSafeArea()
                
                if entries.isEmpty {
                    emptyStateView
                } else {
                    timelineList
                }
            }
            .navigationTitle("タイムライン")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadEntries()
            }
            .refreshable {
                loadEntries()
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("まだ記録がありません")
                .font(Theme.titleFont)
                .foregroundColor(.primary)
            
            Text("気分を記録して\n思い出を残しましょう")
                .font(Theme.bodyFont)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(groupedEntries, id: \.0) { date, dayEntries in
                    VStack(alignment: .leading, spacing: 12) {
                        // 日付ヘッダー
                        dateHeader(for: date, entryCount: dayEntries.count)
                        
                        // その日のエントリー
                        VStack(spacing: 12) {
                            ForEach(dayEntries, id: \.id) { entry in
                                EntryCard(entry: entry, showDate: false)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    private func dateHeader(for date: Date, entryCount: Int) -> some View {
        HStack {
            Text(formatDate(date))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            // 記録数を右側に表示
            Text("\(entryCount)件の記録")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Helper Methods
    
    private func loadEntries() {
        isLoading = true
        entries = dataController.fetchAllEntries()
        groupedEntries = groupEntriesByDate(entries)
        isLoading = false
    }
    
    private func groupEntriesByDate(_ entries: [MoodEntry]) -> [(Date, [MoodEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
        
        return grouped.sorted { $0.key > $1.key } // 新しい日付順
    }
    
    private func dayEntries(for date: Date) -> [MoodEntry] {
        return groupedEntries.first { $0.0 == date }?.1 ?? []
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            formatter.dateFormat = "M月d日(E)"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    TimelineView()
}
import SwiftUI

/// タイムライン表示画面
struct TimelineView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var dataController = DataController.shared
    @State private var entries: [MoodEntry] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground(for: colorScheme).ignoresSafeArea()
                
                if entries.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("timeline.no_entries")
                                .font(Theme.titleFont)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(groupedEntries, id: \.key) { dateGroup in
                                // 日付ヘッダー
                                dateHeaderView(for: dateGroup.key)
                                    .padding(.horizontal, 20)
                                    .padding(.top, dateGroup.key == groupedEntries.first?.key ? 20 : 24)
                                    .padding(.bottom, 8)
                                
                                // エントリーリスト
                                VStack(spacing: 12) {
                                    ForEach(dateGroup.value, id: \.id) { entry in
                                        EntryCard(entry: entry, showDate: false)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.bottom, 12)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("timeline.title")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadEntries()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var groupedEntries: [(key: Date, value: [MoodEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    // MARK: - Helper Methods
    
    private func loadEntries() {
        entries = dataController.fetchAllEntries()
    }
    
    private func dateHeaderView(for date: Date) -> some View {
        HStack {
            Text(formatDateHeader(date))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(countText(for: date))
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.cardBackground(for: colorScheme).opacity(0.3))
        )
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return NSLocalizedString("date.today", comment: "")
        } else if calendar.isDateInYesterday(date) {
            return NSLocalizedString("date.yesterday", comment: "")
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    private func countText(for date: Date) -> String {
        let count = groupedEntries.first { $0.key == date }?.value.count ?? 0
        let format = NSLocalizedString("timeline.entry_count", comment: "")
        return String.localizedStringWithFormat(format, count)
    }
}

#Preview {
    TimelineView()
}
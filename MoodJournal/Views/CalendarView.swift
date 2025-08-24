import SwiftUI

/// カレンダー表示画面
struct CalendarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var dataController = DataController.shared
    @State private var currentDate = Date()
    @State private var selectedDate: Date? = nil
    @State private var dayEntries: [MoodEntry] = []
    @State private var showDayDetail = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground(for: colorScheme).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 月切り替えヘッダー
                    monthHeader
                    
                    // カレンダーグリッド
                    calendarGrid
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle(LocalizedStringKey("calendar.title"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showDayDetail) {
                dayDetailView
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Views
    
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(UIColor.systemBackground))
                            .shadow(radius: 2)
                    )
            }
            
            Spacer()
            
            Text(monthYearText)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(UIColor.systemBackground))
                            .shadow(radius: 2)
                    )
            }
        }
    }
    
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // 曜日ヘッダー
            HStack {
                ForEach(weekdayHeaders, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // 日付グリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isCurrentMonth: calendar.isDate(date, equalTo: currentDate, toGranularity: .month),
                        isToday: calendar.isDateInToday(date),
                        mood: getMoodForDate(date)
                    ) {
                        selectDate(date)
                    }
                }
            }
        }
        .padding(16)
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
    
    private var dayDetailView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // ヘッダー
            if let selectedDate = selectedDate {
                HStack {
                    Text(formatSelectedDate(selectedDate))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(LocalizedStringKey("calendar.close")) {
                        showDayDetail = false
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .padding(.horizontal)
                .padding(.top, 20) // 上部の余白を追加
            }
            
            // エントリー一覧
            if dayEntries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text(LocalizedStringKey("calendar.no_record"))
                        .font(Theme.bodyFont)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(dayEntries, id: \.id) { entry in
                            EntryCard(entry: entry, showDate: false)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            Spacer()
        }
        .background(Theme.gradientBackground(for: colorScheme).ignoresSafeArea())
    }
    
    // MARK: - Computed Properties
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: currentDate)
    }
    
    private var weekdayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    private var calendarDays: [Date] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentDate),
              let firstOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start,
              monthRange.count > 0 && monthRange.count <= 31 else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromPreviousMonth = max(0, (firstWeekday - 1) % 7)
        
        var days: [Date] = []
        
        // 前月の末尾日付を追加
        if daysFromPreviousMonth > 0 {
            for i in (1...daysFromPreviousMonth).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: firstOfMonth) {
                    days.append(date)
                }
            }
        }
        
        // 現在の月の日付を追加
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // 次月の初頭日付を追加（6週間分になるまで）
        let remainingDays = 42 - days.count
        let lastDayOfMonth = days.last ?? firstOfMonth
        for i in 1...remainingDays {
            if let date = calendar.date(byAdding: .day, value: i, to: lastDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // MARK: - Helper Methods
    
    private func previousMonth() {
        withAnimation {
            currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
    }
    
    private func selectDate(_ date: Date) {
        selectedDate = date
        dayEntries = dataController.fetchEntries(for: date)
        showDayDetail = true
    }
    
    private func getMoodForDate(_ date: Date) -> Mood? {
        return dataController.fetchLatestEntry(for: date)?.moodEnum
    }
    
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if calendar.isDateInToday(date) {
            return NSLocalizedString("date.today", comment: "")
        } else if calendar.isDateInYesterday(date) {
            return NSLocalizedString("date.yesterday", comment: "")
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

/// カレンダー日付セルビュー
struct CalendarDayView: View {
    @Environment(\.colorScheme) private var colorScheme
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let mood: Mood?
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium, design: .rounded))
                    .foregroundColor(textColor)
                
                if let mood = mood {
                    Text(mood.emoji)
                        .font(.system(size: 12))
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)
                }
            }
            .frame(width: 40, height: 50)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isToday ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.5)
        } else if isToday {
            return .primary
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return Color.blue.opacity(0.1)
        } else if mood != nil {
            return Color.moodColor(for: mood!, colorScheme: colorScheme).opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        isToday ? .blue : .clear
    }
}

#Preview {
    CalendarView()
}
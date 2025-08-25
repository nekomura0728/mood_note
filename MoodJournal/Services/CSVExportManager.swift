import Foundation
import UIKit

/// CSVエクスポート管理マネージャー（Pro版機能）
@MainActor
class CSVExportManager {
    static let shared = CSVExportManager()
    
    private init() {}
    
    // MARK: - Export Methods
    
    /// 全データをCSVエクスポート
    func exportAllData() async -> URL? {
        let dataController = await DataController.shared
        let entries = await dataController.fetchAllEntries()
        
        return createCSVFile(from: entries, filename: "mood_journal_all_data")
    }
    
    /// 指定期間のデータをCSVエクスポート
    func exportData(from startDate: Date, to endDate: Date) async -> URL? {
        let dataController = await DataController.shared
        let entries = await dataController.fetchEntries(from: startDate, to: endDate)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startString = dateFormatter.string(from: startDate)
        let endString = dateFormatter.string(from: endDate)
        
        return createCSVFile(from: entries, filename: "mood_journal_\(startString)_to_\(endString)")
    }
    
    /// 統計データをCSVエクスポート
    func exportStatistics(period: StatisticsPeriod) async -> URL? {
        let dataController = await DataController.shared
        let now = Date()
        let (startDate, endDate) = period.dateRange(from: now)
        
        let statistics = await dataController.getMoodStatistics(from: startDate, to: endDate)
        
        return createStatisticsCSVFile(statistics: statistics, period: period)
    }
    
    // MARK: - Private Methods
    
    /// エントリーデータからCSVファイルを作成
    private func createCSVFile(from entries: [MoodEntry], filename: String) -> URL? {
        var csvContent = "日付,時刻,気分,気分名,テキスト\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ja_JP")
        timeFormatter.dateFormat = "HH:mm:ss"
        
        for entry in entries.sorted(by: { $0.timestamp < $1.timestamp }) {
            let date = dateFormatter.string(from: entry.timestamp)
            let time = timeFormatter.string(from: entry.timestamp)
            let moodEmoji = entry.moodEnum?.emoji ?? ""
            let moodName = entry.moodEnum?.displayName ?? ""
            let text = cleanTextForCSV(entry.text ?? "")
            
            csvContent += "\(date),\(time),\(moodEmoji),\(moodName),\"\(text)\"\n"
        }
        
        return saveCSVFile(content: csvContent, filename: filename)
    }
    
    /// 統計データからCSVファイルを作成
    private func createStatisticsCSVFile(statistics: [Mood: Int], period: StatisticsPeriod) -> URL? {
        var csvContent = "気分,気分名,回数,割合(%)\n"
        
        let totalCount = statistics.values.reduce(0, +)
        
        for mood in Mood.allCases {
            let count = statistics[mood] ?? 0
            let percentage = totalCount > 0 ? Double(count) / Double(totalCount) * 100 : 0
            
            csvContent += "\(mood.emoji),\(mood.displayName),\(count),\(String(format: "%.2f", percentage))\n"
        }
        
        let filename = "mood_statistics_\(period.displayName.replacingOccurrences(of: "ヶ", with: ""))"
        return saveCSVFile(content: csvContent, filename: filename)
    }
    
    /// CSVファイルをドキュメントフォルダに保存
    private func saveCSVFile(content: String, filename: String) -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                           in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsPath.appendingPathComponent("\(filename).csv")
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            #if DEBUG
            print("CSV保存エラー: \(error)")
            #endif
            return nil
        }
    }
    
    /// CSVテキスト用のクリーンアップ
    private func cleanTextForCSV(_ text: String) -> String {
        return text.replacingOccurrences(of: "\"", with: "\"\"")
                  .replacingOccurrences(of: "\n", with: " ")
                  .replacingOccurrences(of: "\r", with: " ")
    }
}

// MARK: - Share Helper

extension CSVExportManager {
    /// CSVファイルを共有
    nonisolated func shareCSVFile(_ fileURL: URL, from viewController: UIViewController) {
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // iPadでの表示調整
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.frame.midX,
                                      y: viewController.view.frame.midY,
                                      width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    /// SwiftUIからの共有用ヘルパー
    nonisolated func shareCSVFile(_ fileURL: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        shareCSVFile(fileURL, from: rootViewController)
    }
}

// MARK: - Export Options

enum ExportOption: String, CaseIterable {
    case allData = "all_data"
    case lastMonth = "last_month"
    case lastThreeMonths = "last_three_months"
    case lastYear = "last_year"
    case statistics = "statistics"
    
    var displayName: String {
        switch self {
        case .allData: return "すべてのデータ"
        case .lastMonth: return "過去1ヶ月"
        case .lastThreeMonths: return "過去3ヶ月"
        case .lastYear: return "過去1年"
        case .statistics: return "統計データ"
        }
    }
    
    var description: String {
        switch self {
        case .allData: return "記録したすべての気分データ"
        case .lastMonth: return "過去1ヶ月の気分データ"
        case .lastThreeMonths: return "過去3ヶ月の気分データ"
        case .lastYear: return "過去1年の気分データ"
        case .statistics: return "気分の統計情報"
        }
    }
    
    func createFileURL() async -> URL? {
        let exportManager = CSVExportManager.shared
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .allData:
            return await exportManager.exportAllData()
            
        case .lastMonth:
            guard let startDate = calendar.date(byAdding: .month, value: -1, to: now) else { return nil }
            return await exportManager.exportData(from: startDate, to: now)
            
        case .lastThreeMonths:
            guard let startDate = calendar.date(byAdding: .month, value: -3, to: now) else { return nil }
            return await exportManager.exportData(from: startDate, to: now)
            
        case .lastYear:
            guard let startDate = calendar.date(byAdding: .year, value: -1, to: now) else { return nil }
            return await exportManager.exportData(from: startDate, to: now)
            
        case .statistics:
            return await exportManager.exportStatistics(period: .month)
        }
    }
}
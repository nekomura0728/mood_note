import Foundation
import SwiftUI

/// Pro版機能の管理クラス
@MainActor
class ProManager: ObservableObject {
    @Published var isPro: Bool = false
    @Published var purchaseDate: Date?
    
    static let shared = ProManager()
    static let proPrice: Decimal = 300 // ¥300買い切り
    
    private init() {
        loadProStatus()
    }
    
    func checkProStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: "is_pro_user")
    }
    
    func unlockProFeatures() {
        isPro = true
        purchaseDate = Date()
        UserDefaults.standard.set(true, forKey: "is_pro_user")
        UserDefaults.standard.set(Date(), forKey: "pro_purchase_date")
        
        #if DEBUG
        print("[ProManager] Pro features unlocked!")
        #endif
        
        // オブジェクトの更新を通知
        objectWillChange.send()
    }
    
    func isFeatureAvailable(_ feature: ProFeature) -> Bool {
        return isPro
    }
    
    private func loadProStatus() {
        isPro = UserDefaults.standard.bool(forKey: "is_pro_user")
        if let date = UserDefaults.standard.object(forKey: "pro_purchase_date") as? Date {
            purchaseDate = date
        }
    }
    
    // デバッグ用: Pro版をリセット
    func resetProStatus() {
        isPro = false
        purchaseDate = nil
        UserDefaults.standard.removeObject(forKey: "is_pro_user")
        UserDefaults.standard.removeObject(forKey: "pro_purchase_date")
        objectWillChange.send()
    }
}

/// Pro版機能の種類
enum ProFeature: String, CaseIterable {
    case weeklyInsights = "weekly_insights"      // 週次まとめ
    case personalCoaching = "personal_coaching"   // パーソナルコーチング
    case detailedReports = "detailed_reports"     // 詳細レポート（旧統計）
    
    var displayName: String {
        switch self {
        case .weeklyInsights: return "週次インサイト"
        case .personalCoaching: return "パーソナルコーチ"
        case .detailedReports: return "詳細レポート"
        }
    }
    
    var description: String {
        switch self {
        case .weeklyInsights: return "1週間の気分を振り返り、温かいコメントでまとめます"
        case .personalCoaching: return "気分パターンを分析し、具体的なアドバイスを提供します"
        case .detailedReports: return "長期間の気分傾向を詳細に分析・可視化します"
        }
    }
    
    var icon: String {
        switch self {
        case .weeklyInsights: return "doc.text.magnifyingglass"
        case .personalCoaching: return "person.crop.circle.badge.checkmark"
        case .detailedReports: return "chart.line.uptrend.xyaxis"
        }
    }
}
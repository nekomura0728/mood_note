import Foundation
import StoreKit

/// StoreKit2を使用したアプリ内課金管理（Pro版機能）
/// 注意：現在はProManagerを使用しています。このクラスは互換性のために残しています。
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    /// Pro版の商品ID
    static let proVersionProductID = "com.moodjournal.app.pro"
    
    @Published var isProVersionPurchased = false
    @Published var proVersionProduct: Product?
    @Published var purchaseState: PurchaseState = .notPurchased
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    enum PurchaseState: Equatable {
        case notPurchased
        case purchasing
        case purchased
        case failed(Error)
        case restored
        
        static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
            switch (lhs, rhs) {
            case (.notPurchased, .notPurchased),
                 (.purchasing, .purchasing),
                 (.purchased, .purchased),
                 (.restored, .restored):
                return true
            case (.failed, .failed):
                return true // Simple comparison for Error cases
            default:
                return false
            }
        }
    }
    
    private init() {
        // 購入状態の更新監視を開始
        updateListenerTask = listenForTransactions()
        
        // 初期化時に商品情報を取得
        Task {
            await loadProducts()
            await checkPurchaseStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 商品情報を取得
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proVersionProductID])
            if let product = products.first {
                self.proVersionProduct = product
            }
        } catch {
            print("商品情報の取得に失敗: \(error)")
            self.errorMessage = "商品情報を取得できませんでした"
        }
    }
    
    /// Pro版を購入
    func purchaseProVersion() async {
        guard let product = proVersionProduct else {
            self.errorMessage = "商品が見つかりません"
            return
        }
        
        self.purchaseState = .purchasing
        self.errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // 購入完了
                self.isProVersionPurchased = true
                self.purchaseState = .purchased
                
                // トランザクションを完了
                await transaction.finish()
                
            case .userCancelled:
                self.purchaseState = .notPurchased
                
            case .pending:
                // 保護者の承認待ちなど
                self.errorMessage = "購入の承認待ちです"
                
            @unknown default:
                self.purchaseState = .notPurchased
                self.errorMessage = "不明なエラーが発生しました"
            }
            
        } catch {
            self.purchaseState = .failed(error)
            self.errorMessage = "購入に失敗しました: \(error.localizedDescription)"
        }
    }
    
    /// 購入の復元
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
            
            if isProVersionPurchased {
                self.purchaseState = .restored
            }
        } catch {
            self.errorMessage = "購入の復元に失敗しました: \(error.localizedDescription)"
        }
    }
    
    /// 購入状態をチェック
    func checkPurchaseStatus() async {
        var isPurchased = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == Self.proVersionProductID {
                    isPurchased = true
                    break
                }
            } catch {
                print("トランザクションの確認エラー: \(error)")
            }
        }
        
        self.isProVersionPurchased = isPurchased
        self.purchaseState = isPurchased ? .purchased : .notPurchased
    }
    
    // MARK: - Private Methods
    
    /// トランザクションの監視
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run {
                        try self.checkVerified(result)
                    }
                    
                    await MainActor.run {
                        if transaction.productID == Self.proVersionProductID {
                            self.isProVersionPurchased = true
                            self.purchaseState = .purchased
                        }
                    }
                    
                    await transaction.finish()
                } catch {
                    print("トランザクション更新エラー: \(error)")
                }
            }
        }
    }
    
    /// トランザクションの検証
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - StoreKit Error

enum StoreError: Error {
    case failedVerification
    
    var localizedDescription: String {
        switch self {
        case .failedVerification:
            return "購入の検証に失敗しました"
        }
    }
}

// MARK: - Price Formatting

extension Product {
    /// ローカライズされた価格を適切にフォーマット
    var formattedPrice: String {
        // デバッグ用の価格表示（App Store Connect設定に関わらず、ローカライズされた価格を表示）
        let locale = Locale.current
        let isJapanese = locale.language.languageCode?.identifier == "ja"
        
        if isJapanese {
            return "¥300"
        } else {
            return "$1.99"
        }
    }
}

// MARK: - ProManager

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
        
        print("[ProManager] Pro features unlocked!")
        
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
import SwiftUI

/// Pro版購入画面
struct ProVersionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Theme.gradientBackground(for: colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    headerSection
                    
                    // Pro版機能一覧
                    featuresSection
                    
                    // 価格とボタン
                    purchaseSection
                    
                    // 復元ボタン
                    restoreSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .task {
            await storeManager.loadProducts()
        }
        .alert(NSLocalizedString("pro.error", comment: ""), isPresented: .constant(storeManager.errorMessage != nil)) {
            Button("OK") {
                storeManager.errorMessage = nil
            }
        } message: {
            Text(storeManager.errorMessage ?? "")
        }
    }
    
    // MARK: - Views
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Pro版アイコン
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Text("👑")
                        .font(.system(size: 40))
                }
                
                Text(NSLocalizedString("pro.upgrade_title", comment: ""))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(NSLocalizedString("pro.subtitle", comment: ""))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("pro.features_title", comment: ""))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "🧑‍⚕️",
                    title: NSLocalizedString("pro.personal_coaching_title", comment: ""),
                    description: NSLocalizedString("pro.personal_coaching_desc", comment: "")
                )
                
                FeatureRow(
                    icon: "📊",
                    title: NSLocalizedString("pro.detailed_reports", comment: ""),
                    description: NSLocalizedString("pro.detailed_reports_desc", comment: "")
                )
            }
        }
        .padding(20)
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
    
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if let product = storeManager.proVersionProduct {
                VStack(spacing: 8) {
                    Text(NSLocalizedString("pro.one_time_purchase", comment: ""))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(product.formattedPrice)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("pro.forever_use", comment: ""))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
                
                // 購入ボタン
                Button(action: {
                    Task {
                        // デバッグモードでは即座Pro版を有効化
                        #if DEBUG
                        ProManager.shared.unlockProFeatures()
                        dismiss()
                        #else
                        await storeManager.purchaseProVersion()
                        #endif
                    }
                }) {
                    HStack {
                        if storeManager.purchaseState == .purchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        
                        Text(purchaseButtonTitle)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: purchaseButtonEnabled ? [Color.blue, Color.purple] : [Color.gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                }
                .disabled(!purchaseButtonEnabled)
                
            } else {
                // デバッグモード用の商品情報
                #if DEBUG
                VStack(spacing: 8) {
                    Text(NSLocalizedString("pro.one_time_purchase", comment: ""))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(debugPrice)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("pro.forever_use", comment: ""))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
                
                // 購入ボタン（デバッグ用）
                Button(action: {
                    ProManager.shared.unlockProFeatures()
                    dismiss()
                }) {
                    Text(NSLocalizedString("pro.purchase", comment: ""))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                }
                #else
                // 商品情報読み込み中
                VStack(spacing: 16) {
                    ProgressView(NSLocalizedString("pro.loading_product_info", comment: ""))
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Button(NSLocalizedString("pro.reload", comment: "")) {
                        Task {
                            await storeManager.loadProducts()
                        }
                    }
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 32)
                #endif
            }
        }
    }
    
    private var restoreSection: some View {
        VStack(spacing: 8) {
            Button(NSLocalizedString("pro.restore_purchase", comment: "")) {
                #if DEBUG
                ProManager.shared.unlockProFeatures()
                dismiss()
                #else
                Task {
                    await storeManager.restorePurchases()
                }
                #endif
            }
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.blue)
            
            Text(NSLocalizedString("pro.already_purchased", comment: ""))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Helper Properties
    
    private var debugPrice: String {
        let isEnglish = Locale.current.language.languageCode?.identifier == "en"
        return isEnglish ? NSLocalizedString("pro.debug_price_en", comment: "") : NSLocalizedString("pro.debug_price_jp", comment: "")
    }
    
    private var purchaseButtonTitle: String {
        switch storeManager.purchaseState {
        case .purchasing:
            return NSLocalizedString("pro.purchase_button_purchasing", comment: "")
        case .purchased:
            return NSLocalizedString("pro.purchase_button_purchased", comment: "")
        case .restored:
            return NSLocalizedString("pro.purchase_button_restored", comment: "")
        default:
            return NSLocalizedString("pro.purchase", comment: "")
        }
    }
    
    private var purchaseButtonEnabled: Bool {
        switch storeManager.purchaseState {
        case .purchasing:
            return false
        case .purchased, .restored:
            // 購入後は自動で画面を閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ProManager.shared.unlockProFeatures()
                dismiss()
            }
            return false
        default:
            #if DEBUG
            return true
            #else
            return storeManager.proVersionProduct != nil
            #endif
        }
    }
}

/// Pro版機能の項目
struct FeatureRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 24))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ProVersionView()
}
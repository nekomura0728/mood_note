import SwiftUI

/// Pro版購入画面
struct ProVersionView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Theme.gradientBackground.ignoresSafeArea()
            
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
        .alert("エラー", isPresented: .constant(storeManager.errorMessage != nil)) {
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
                
                Text("Pro版にアップグレード")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("パーソナルコーチと詳細レポートで気分を深く理解")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pro版の機能")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "🧑‍⚕️",
                    title: "パーソナルコーチング",
                    description: "気分パターンと時間帯を分析し、具体的なアドバイスを提供"
                )
                
                FeatureRow(
                    icon: "📊",
                    title: "詳細レポート",
                    description: "長期間の気分傾向を詳細に分析・可視化"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
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
                    Text("買い切り価格")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(product.formattedPrice)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("一度購入すれば永続利用可能")
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
                    Text("買い切り価格")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("¥300")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("一度購入すれば永続利用可能")
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
                    Text("Pro版を購入")
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
                    ProgressView("商品情報を読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Button("再読み込み") {
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
            Button("購入を復元") {
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
            
            Text("既に購入済みの場合はこちら")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Helper Properties
    
    private var purchaseButtonTitle: String {
        switch storeManager.purchaseState {
        case .purchasing:
            return "購入中..."
        case .purchased:
            return "購入済み"
        case .restored:
            return "復元済み"
        default:
            return "Pro版を購入"
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
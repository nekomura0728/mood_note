import SwiftUI
import StoreKit

/// Pro版アップグレード画面
struct ProUpgradeView: View {
    @StateObject private var proManager = ProManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // ヘッダー
                        headerSection
                        
                        // 機能一覧
                        featuresSection
                        
                        // 価格と購入ボタン
                        purchaseSection
                        
                        // 復元ボタン
                        restoreSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Pro版にアップグレード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("きぶん日記 Pro")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("より詳しく気分を理解し、\n自分と向き合うためのツールを解放します")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 20) {
            ForEach(ProFeature.allCases, id: \.self) { feature in
                FeatureCard(feature: feature)
            }
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: 20) {
            // 価格表示
            VStack(spacing: 8) {
                HStack {
                    Text("¥300")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("買い切り")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                
                Text("月額課金なし・追加料金なし")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .fill(Theme.cardBackground)
                    .shadow(
                        color: .black.opacity(Theme.cardShadowOpacity),
                        radius: Theme.cardShadowRadius,
                        x: 0, y: 2
                    )
            )
            
            // 購入ボタン
            Button(action: purchasePro) {
                HStack(spacing: 12) {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isPurchasing ? "処理中..." : "Pro版を購入する")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isPurchasing || proManager.isPro)
            .scaleEffect(isPurchasing ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPurchasing)
        }
    }
    
    // MARK: - Restore Section
    
    private var restoreSection: some View {
        VStack(spacing: 16) {
            Button("購入を復元") {
                restorePurchases()
            }
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
            
            Text("購入に問題がある場合は復元をお試しください")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private func purchasePro() {
        isPurchasing = true
        
        // 実際のアプリではStoreKitを使用
        // 今回はデモ用の実装
        Task {
            do {
                // 購入処理をシミュレート
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待機
                
                // 成功をシミュレート
                await MainActor.run {
                    proManager.unlockProFeatures()
                    isPurchasing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = "購入に失敗しました。もう一度お試しください。"
                    showError = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        // 実際のアプリではStoreKitの復元機能を使用
        // デモ用の実装
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
            
            await MainActor.run {
                // 既に購入済みの場合は復元成功
                if UserDefaults.standard.bool(forKey: "is_pro_user") {
                    proManager.unlockProFeatures()
                    dismiss()
                } else {
                    errorMessage = "復元する購入が見つかりませんでした。"
                    showError = true
                }
            }
        }
    }
}

/// 機能カードコンポーネント
struct FeatureCard: View {
    let feature: ProFeature
    
    var body: some View {
        HStack(spacing: 16) {
            // アイコン
            Image(systemName: feature.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color(hex: iconColor))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: iconColor).opacity(0.1))
                )
            
            // テキスト
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .fill(Theme.cardBackground)
                .shadow(
                    color: .black.opacity(Theme.cardShadowOpacity),
                    radius: Theme.cardShadowRadius,
                    x: 0, y: 2
                )
        )
    }
    
    private var iconColor: String {
        switch feature {
        case .weeklyInsights: return "#4CAF50"
        case .personalCoaching: return "#2196F3"
        case .detailedReports: return "#FF9800"
        }
    }
}

#Preview {
    ProUpgradeView()
}
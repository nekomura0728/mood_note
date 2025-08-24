import SwiftUI

/// Pro機能ハブ画面
struct ProFeaturesView: View {
    @StateObject private var proManager = ProManager.shared
    @State private var showUpgradeSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground.ignoresSafeArea()
                
                if proManager.isPro {
                    proFeaturesContent
                } else {
                    upgradePromptContent
                }
            }
            .navigationTitle("Pro機能")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showUpgradeSheet) {
                ProUpgradeView()
            }
        }
    }
    
    // MARK: - Pro Features Content
    
    private var proFeaturesContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ヘッダー
                proStatusHeader
                
                // 機能カード一覧
                LazyVStack(spacing: 16) {
                    // 週次インサイト
                    NavigationLink(destination: WeeklyInsightsView()) {
                        ProFeatureCard(
                            feature: .weeklyInsights,
                            isUnlocked: true
                        )
                    }
                    
                    // パーソナルコーチング
                    NavigationLink(destination: PersonalCoachingView()) {
                        ProFeatureCard(
                            feature: .personalCoaching,
                            isUnlocked: true
                        )
                    }
                    
                    // 詳細レポート
                    NavigationLink(destination: DetailedReportsView()) {
                        ProFeatureCard(
                            feature: .detailedReports,
                            isUnlocked: true
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Upgrade Prompt Content
    
    private var upgradePromptContent: some View {
        VStack(spacing: 32) {
            // ヘッダー
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 8) {
                    Text("きぶん日記 Pro")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("より深く自分を理解する")
                        .font(.system(size: 18, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            // 機能紹介
            VStack(spacing: 16) {
                ForEach(ProFeature.allCases, id: \.self) { feature in
                    ProFeatureCard(
                        feature: feature,
                        isUnlocked: false
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // アップグレードボタン
            Button(action: { showUpgradeSheet = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Pro版にアップグレード")
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
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Pro Status Header
    
    private var proStatusHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pro版有効")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if let purchaseDate = proManager.purchaseDate {
                        Text("購入日: \(purchaseDate, formatter: dateFormatter)")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Text("すべてのPro機能をお楽しみください")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        return formatter
    }
}

/// Pro機能カード
struct ProFeatureCard: View {
    let feature: ProFeature
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // アイコン
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: iconColor).opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(hex: iconColor))
                
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                        .offset(x: 15, y: -15)
                }
            }
            
            // テキスト
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(feature.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                }
                
                Text(feature.description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // 矢印（アンロック済みの場合のみ）
            if isUnlocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
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
        .opacity(isUnlocked ? 1.0 : 0.7)
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
    ProFeaturesView()
}
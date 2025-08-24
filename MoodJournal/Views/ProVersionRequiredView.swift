import SwiftUI

/// Pro版が必要な機能にアクセスした際の案内画面
struct ProVersionRequiredView: View {
    @State private var isPresentingProVersion = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // メインアイコン
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 120, height: 120)
                            
                            Text("👑")
                                .font(.system(size: 60))
                        }
                        
                        Text("Pro版限定機能")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("この機能をご利用いただくには\nPro版へのアップグレードが必要です")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    // 機能プレビュー
                    VStack(spacing: 20) {
                        FeaturePreviewRow(
                            icon: "📊",
                            title: "詳細な統計分析",
                            description: "気分の変化を期間別にグラフで確認"
                        )
                        
                        FeaturePreviewRow(
                            icon: "📁",
                            title: "CSVエクスポート",
                            description: "データを外部アプリで分析可能"
                        )
                        
                        FeaturePreviewRow(
                            icon: "🎨",
                            title: "追加テーマ",
                            description: "お好みの色合いでカスタマイズ"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // アップグレードボタン
                    VStack(spacing: 12) {
                        Button(action: {
                            isPresentingProVersion = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 16))
                                
                                Text("Pro版にアップグレード")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
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
                        
                        Text("買い切り価格でずっと使える")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $isPresentingProVersion) {
            ProVersionView()
        }
    }
}

/// 機能プレビュー行
struct FeaturePreviewRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                )
            
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
            
            Image(systemName: "lock.fill")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ProVersionRequiredView()
}
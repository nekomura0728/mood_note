import SwiftUI

/// Pro版が必要な機能にアクセスした際の案内画面
struct ProVersionRequiredView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPresentingProVersion = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.gradientBackground(for: colorScheme).ignoresSafeArea()
                
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
                        
                        Text(NSLocalizedString("pro_required.title", comment: ""))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("pro_required.description", comment: ""))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    // 機能プレビュー
                    VStack(spacing: 20) {
                        FeaturePreviewRow(
                            icon: "📊",
                            title: NSLocalizedString("pro_required.detailed_analytics", comment: ""),
                            description: NSLocalizedString("pro_required.detailed_analytics_desc", comment: "")
                        )
                        
                        FeaturePreviewRow(
                            icon: "📁",
                            title: NSLocalizedString("pro_required.csv_export", comment: ""),
                            description: NSLocalizedString("pro_required.csv_export_desc", comment: "")
                        )
                        
                        FeaturePreviewRow(
                            icon: "🎨",
                            title: NSLocalizedString("pro_required.additional_themes", comment: ""),
                            description: NSLocalizedString("pro_required.additional_themes_desc", comment: "")
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
                                
                                Text(NSLocalizedString("pro_required.upgrade", comment: ""))
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
                        
                        Text(NSLocalizedString("pro_required.one_time_price", comment: ""))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("statistics.title")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $isPresentingProVersion) {
            ProVersionView()
        }
    }
}

/// 機能プレビュー行
struct FeaturePreviewRow: View {
    @Environment(\.colorScheme) private var colorScheme
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
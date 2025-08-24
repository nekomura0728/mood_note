import SwiftUI

/// アプリのテーマ設定
struct Theme {
    /// パステルカラーパレット（ライトモード用）
    static let pastelPeach = Color(hex: "FFE5B4")
    static let pastelSkyBlue = Color(hex: "B4E5FF")
    static let pastelLavender = Color(hex: "E5D4FF")
    static let pastelCoral = Color(hex: "FFB4B4")
    static let pastelMint = Color(hex: "B4FFE5")
    
    /// ダークモード用の深いカラー
    static let darkPeach = Color(hex: "8B6B47")
    static let darkSkyBlue = Color(hex: "4A7A8C")
    static let darkLavender = Color(hex: "6B5B8C")
    static let darkCoral = Color(hex: "8B4545")
    static let darkMint = Color(hex: "4A8B70")
    
    /// グラデーション背景（動的）
    static func gradientBackground(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1A1A2E"),  // 深い紺
                    Color(hex: "16213E"),  // 深い青
                    Color(hex: "0F3460")   // ミッドナイトブルー
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FFE5E5"),
                    Color(hex: "E5F3FF"),
                    Color(hex: "F0E5FF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    /// カード背景（動的）
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color(hex: "2C2C3E").opacity(0.95)
        } else {
            return Color.white.opacity(0.95)
        }
    }
    
    /// テキストの補助色（動的）
    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.7)
        } else {
            return Color.black.opacity(0.6)
        }
    }
    
    /// 影の設定（動的）
    static let cardShadowRadius: CGFloat = 8
    static func cardShadowOpacity(for colorScheme: ColorScheme) -> Double {
        return colorScheme == .dark ? 0.3 : 0.1
    }
    
    /// コーナー半径
    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 12
    
    /// フォント
    static let titleFont = Font.system(size: 24, weight: .bold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .regular, design: .rounded)
    
    /// アニメーション
    static let defaultAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Moodに対応したテーマカラーを取得（ダークモード対応）
    static func moodColor(for mood: Mood, colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color(hex: mood.darkThemeColor)
        } else {
            return Color(hex: mood.themeColor)
        }
    }
    
    /// 彩度を調整したColorを返す
    func adjustedSaturation(_ multiplier: Double) -> Color {
        // SwiftUIのColorをUIColorに変換
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // HSB値を取得
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // 彩度を調整（最大1.0に制限）
        let adjustedSaturation = min(saturation * CGFloat(multiplier), 1.0)
        
        // 新しいColorを作成して返す
        return Color(UIColor(hue: hue, saturation: adjustedSaturation, brightness: brightness, alpha: alpha))
    }
}
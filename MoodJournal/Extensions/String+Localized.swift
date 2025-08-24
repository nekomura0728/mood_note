import Foundation
import SwiftUI

extension String {
    /// NSLocalizedStringのSwiftUI用ヘルパー
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// パラメータ付きローカライゼーション
    func localized(_ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
import Foundation
import SwiftUI

/// 轻量设计系统：暖灰纸面 + 陶土橙强调色，全部界面共用。
enum AppTheme {
    static let canvas = Color(red: 0.957, green: 0.945, blue: 0.925)
    static let paper = Color(red: 0.988, green: 0.980, blue: 0.965)
    static let card = Color(red: 0.996, green: 0.992, blue: 0.984)
    static let ink = Color(red: 0.129, green: 0.118, blue: 0.102)
    static let clay = Color(red: 0.706, green: 0.365, blue: 0.200)
    static let sage = Color(red: 0.298, green: 0.400, blue: 0.325)
    static let gold = Color(red: 0.760, green: 0.604, blue: 0.294)
    static let hairline = Color.black.opacity(0.07)
}

extension Color {
    /// 支持 "#B45D33" / "B45D33" 两种写法；解析失败时回退到灰色。
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        _ = Scanner(string: cleaned).scanHexInt64(&value)

        guard cleaned.count == 6 else {
            self.init(red: 0.5, green: 0.5, blue: 0.5)
            return
        }

        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}

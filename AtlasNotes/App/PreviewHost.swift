import Foundation
import SwiftUI

/// CI/预览专用入口：通过启动参数 `-previewScreen <library|insights|settings>`
/// 直接渲染目标界面，便于 simctl 截图，不经过任何人工点击。
enum PreviewScreen: String {
    case library
    case insights
    case settings

    static var launchArgument: PreviewScreen? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-previewScreen"),
              arguments.indices.contains(index + 1) else {
            return nil
        }
        return PreviewScreen(rawValue: arguments[index + 1])
    }
}

struct PreviewHost: View {
    let screen: PreviewScreen

    var body: some View {
        switch screen {
        case .library:
            RootView()
        case .insights:
            NavigationStack {
                InsightsView()
            }
        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }
}

import SwiftUI

@main
struct AtlasNotesApp: App {
    @State private var store = MemoStore.seeded()

    var body: some Scene {
        WindowGroup {
            Group {
                if let screen = PreviewScreen.launchArgument {
                    PreviewHost(screen: screen)
                } else {
                    RootView()
                }
            }
            .environment(store)
            .tint(AppTheme.clay)
        }
    }
}

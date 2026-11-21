import SwiftUI

/// iPad 主界面：三栏结构（笔记本 / 笔记列表 / 编辑器）。
struct RootView: View {
    @Environment(MemoStore.self) private var store
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 240, ideal: 272, max: 320)
        } content: {
            NoteListView()
                .navigationSplitViewColumnWidth(min: 320, ideal: 372, max: 440)
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .background(AppTheme.canvas)
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let id = store.selectedMemoID, let memo = store.memo(id: id) {
            NoteDetailView(memo: memo)
                .id(id)
        } else {
            ContentUnavailableView {
                Label("选择一篇笔记", systemImage: "sidebar.right")
            } description: {
                Text("从中间列表选择笔记，或点击右上角的新建按钮。")
            }
            .background(AppTheme.canvas)
        }
    }
}

#Preview("图书馆 · iPad") {
    RootView()
        .environment(MemoStore.seeded())
}

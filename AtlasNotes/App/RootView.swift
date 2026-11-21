import SwiftUI

/// iPad 主界面：三栏结构（笔记本 / 笔记列表 / 编辑器）。
struct RootView: View {
    @Environment(MemoStore.self) private var store
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        GeometryReader { proxy in
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView()
                    .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
            } content: {
                NoteListView()
                    .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 420)
            } detail: {
                detailColumn
            }
            .navigationSplitViewStyle(.balanced)
            .background(AppTheme.canvas)
            .onAppear {
                updateColumns(for: proxy.size.width)
            }
            .onChange(of: proxy.size.width) { _, width in
                updateColumns(for: width)
            }
        }
    }

    /// 竖屏/窄分屏隐藏侧边栏，只保留列表 + 详情，避免详情栏被压到不可读。
    private func updateColumns(for width: CGFloat) {
        columnVisibility = width < 900 ? .doubleColumn : .all
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

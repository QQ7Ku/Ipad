import SwiftUI

struct NoteListView: View {
    @Environment(MemoStore.self) private var store

    var body: some View {
        @Bindable var model = store

        List(selection: $model.selectedMemoID) {
            ForEach(model.visibleMemos) { memo in
                MemoRow(
                    memo: memo,
                    notebook: model.notebook(id: memo.notebookID)
                )
                .tag(memo.id)
                .listRowSeparatorTint(AppTheme.hairline)
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if model.visibleMemos.isEmpty {
                ContentUnavailableView(
                    "没有匹配的笔记",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("换一个关键词，或关闭“仅显示收藏”。")
                )
            }
        }
        .navigationTitle(columnTitle)
        .searchable(text: $model.searchText, prompt: "搜索标题、正文或标签")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("排序方式", selection: $model.sortOrder) {
                        ForEach(MemoStore.SortOrder.allCases) { order in
                            Text(order.label).tag(order)
                        }
                    }

                    Divider()

                    Toggle("仅显示收藏", isOn: $model.showFavoritesOnly)
                } label: {
                    Label("筛选与排序", systemImage: "line.3.horizontal.decrease.circle")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.addMemo()
                } label: {
                    Label("新建笔记", systemImage: "square.and.pencil")
                }
            }
        }
        .onChange(of: model.notebookSelection) { _, _ in
            model.ensureSelectionIsVisible()
        }
        .onChange(of: model.showFavoritesOnly) { _, _ in
            model.ensureSelectionIsVisible()
        }
        .onChange(of: model.sortOrder) { _, _ in
            model.ensureSelectionIsVisible()
        }
    }

    private var columnTitle: String {
        guard let selection = store.notebookSelection,
              case let .notebook(id) = selection,
              let notebook = store.notebook(id: id) else {
            return "全部笔记"
        }
        return notebook.name
    }
}

private struct MemoRow: View {
    let memo: Memo
    let notebook: Notebook?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(memo.title)
                    .font(.headline)
                    .lineLimit(1)

                if memo.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.gold)
                }

                Spacer(minLength: 0)

                Text(memo.updatedAt, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(memo.excerpt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 6) {
                if let notebook {
                    Label(notebook.name, systemImage: notebook.symbol)
                        .font(.caption2)
                        .foregroundStyle(Color(hex: notebook.colorHex))
                }

                ForEach(memo.tags.prefix(2), id: \.self) { tag in
                    TagChip(text: tag)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview("笔记列表 · iPad") {
    NavigationStack {
        NoteListView()
            .environment(MemoStore.seeded())
    }
}

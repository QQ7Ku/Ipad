import SwiftUI

struct NoteDetailView: View {
    @Environment(MemoStore.self) private var store
    @AppStorage("editorFontSize") private var editorFontSize: Double = 18

    @State private var draft: Memo

    init(memo: Memo) {
        _draft = State(initialValue: memo)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                metaLine
                titleField
                tagRow
                Divider()
                editor
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 30)
            .frame(maxWidth: 840, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(AppTheme.paper.ignoresSafeArea())
        .onChange(of: draft) { _, newValue in
            store.update(newValue)
        }
    }

    private var metaLine: some View {
        HStack(spacing: 10) {
            if let notebook = store.notebook(id: draft.notebookID) {
                Label(notebook.name, systemImage: notebook.symbol)
                    .foregroundStyle(Color(hex: notebook.colorHex))
            }

            Text("·")
            Text(draft.updatedAt, format: .dateTime.year().month().day().hour().minute())
            Text("·")
            Text("\(draft.characterCount) 字")

            Spacer()

            Button {
                draft.isFavorite.toggle()
            } label: {
                Image(systemName: draft.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(draft.isFavorite ? AppTheme.gold : Color.secondary)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var titleField: some View {
        TextField("无标题", text: $draft.title, axis: .vertical)
            .font(.system(size: 34, weight: .bold, design: .serif))
            .foregroundStyle(AppTheme.ink)
            .textFieldStyle(.plain)
            .lineLimit(1...3)
    }

    private var availableTags: [String] {
        store.tagStats
            .map(\.tag)
            .filter { !draft.tags.contains($0) }
    }

    private var tagRow: some View {
        HStack(spacing: 8) {
            ForEach(draft.tags, id: \.self) { tag in
                TagChip(text: tag)
            }

            Menu {
                if availableTags.isEmpty {
                    Text("暂无其他标签")
                } else {
                    ForEach(availableTags, id: \.self) { tag in
                        Button(tag) {
                            draft.tags.append(tag)
                        }
                    }
                }
            } label: {
                Label("添加标签", systemImage: "plus")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.clay)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.clay.opacity(0.10), in: Capsule())
            }
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if draft.body.isEmpty {
                Text("开始书写…")
                    .font(.system(size: CGFloat(editorFontSize), design: .serif))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
                    .padding(.leading, 6)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $draft.body)
                .font(.system(size: CGFloat(editorFontSize), design: .serif))
                .lineSpacing(7)
                .foregroundStyle(AppTheme.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 460)
        }
    }
}

#Preview("编辑器 · iPad") {
    let store = MemoStore.seeded()
    NavigationStack {
        NoteDetailView(memo: store.memos[0])
            .environment(store)
    }
}

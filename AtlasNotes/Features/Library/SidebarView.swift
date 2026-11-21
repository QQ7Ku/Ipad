import SwiftUI

struct SidebarView: View {
    @Environment(MemoStore.self) private var store
    @State private var showsInsights = false
    @State private var showsSettings = false

    var body: some View {
        @Bindable var model = store

        List(selection: $model.notebookSelection) {
            Section {
                Label("全部笔记", systemImage: "tray.full")
                    .tag(NotebookSelection.all)
                    .badge(model.memos.count)
            } header: {
                Text("工作台")
            }

            Section {
                ForEach(model.notebooks) { notebook in
                    Label {
                        Text(notebook.name)
                    } icon: {
                        Image(systemName: notebook.symbol)
                            .foregroundStyle(Color(hex: notebook.colorHex))
                    }
                    .badge(model.memoCount(in: notebook.id))
                    .tag(NotebookSelection.notebook(notebook.id))
                }
            } header: {
                Text("笔记本")
            } footer: {
                Text("\(model.notebooks.count) 个笔记本 · \(model.memos.count) 篇笔记")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Atlas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.addNotebook()
                } label: {
                    Label("新建笔记本", systemImage: "folder.badge.plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    showsInsights = true
                } label: {
                    Label("写作洞察", systemImage: "chart.bar.xaxis")
                        .frame(maxWidth: .infinity)
                }

                Button {
                    showsSettings = true
                } label: {
                    Label("设置", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .padding(12)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showsInsights) {
            NavigationStack {
                InsightsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") { showsInsights = false }
                        }
                    }
            }
            .environment(model)
        }
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") { showsSettings = false }
                        }
                    }
            }
            .environment(model)
        }
    }
}

#Preview("侧边栏 · iPad") {
    NavigationSplitView {
        SidebarView()
            .environment(MemoStore.seeded())
    } detail: {
        Text("详情占位")
    }
}

import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(MemoStore.self) private var store
    @AppStorage("editorFontSize") private var editorFontSize: Double = 18
    @State private var showsResetConfirmation = false

    var body: some View {
        @Bindable var model = store

        Form {
            Section("编辑器") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("正文字号")
                        Spacer()
                        Text("\(Int(editorFontSize)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $editorFontSize, in: 14...26, step: 1)
                }

                Toggle("仅显示收藏笔记", isOn: $model.showFavoritesOnly)
            }

            Section("数据") {
                LabeledContent("笔记本", value: "\(model.notebooks.count)")
                LabeledContent("笔记", value: "\(model.memos.count)")
                LabeledContent("总字数", value: model.totalCharacters.formatted())

                Button("重置为示例数据", role: .destructive) {
                    showsResetConfirmation = true
                }
            }

            Section("关于") {
                LabeledContent("应用", value: "Atlas Notes")
                LabeledContent("版本", value: versionString)
                LabeledContent("最低系统", value: "iPadOS 17.0")
                LabeledContent("构建方式", value: "GitHub Actions · 未签名 IPA")

                Text("应用内数据仅用于界面演示，不包含网络请求、账户体系与用户追踪。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
        .confirmationDialog(
            "重置示例数据？",
            isPresented: $showsResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("重置", role: .destructive) {
                model.resetToSeed()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("当前编辑内容将被示例数据替换，且不可撤销。")
        }
    }

    private var versionString: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(shortVersion) (\(build))"
    }
}

#Preview("设置 · iPad") {
    NavigationStack {
        SettingsView()
            .environment(MemoStore.seeded())
    }
}

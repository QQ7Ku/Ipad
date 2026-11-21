import Charts
import Foundation
import SwiftUI

struct InsightsView: View {
    @Environment(MemoStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                statGrid
                notebookChart
                activityChart
                tagCloud
            }
            .padding(32)
            .frame(maxWidth: 1040, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(AppTheme.canvas.ignoresSafeArea())
        .navigationTitle("写作洞察")
    }

    private var header: some View {
        Text("从笔记本、更新频率与标签三个维度，观察你的写作节奏。")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var statGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 190), spacing: 16)],
            spacing: 16
        ) {
            StatCard(
                title: "笔记总量",
                value: "\(store.memos.count)",
                caption: "分布在 \(store.notebooks.count) 个笔记本",
                symbol: "doc.text",
                tint: AppTheme.clay
            )

            StatCard(
                title: "累计字数",
                value: store.totalCharacters.formatted(),
                caption: "不含空白字符",
                symbol: "text.alignleft",
                tint: AppTheme.sage
            )

            StatCard(
                title: "收藏",
                value: "\(store.favoriteCount)",
                caption: "值得反复阅读的条目",
                symbol: "star",
                tint: AppTheme.gold
            )

            StatCard(
                title: "标签",
                value: "\(Set(store.memos.flatMap(\.tags)).count)",
                caption: "跨笔记本的主题线索",
                symbol: "tag",
                tint: AppTheme.ink
            )
        }
    }

    private var notebookChart: some View {
        card(title: "笔记本分布", subtitle: "每个笔记本的笔记数量") {
            Chart(store.notebookStats) { stat in
                BarMark(
                    x: .value("笔记数", stat.count),
                    y: .value("笔记本", stat.name)
                )
                .foregroundStyle(Color(hex: stat.colorHex))
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text("\(stat.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: max(CGFloat(store.notebookStats.count) * 48, 132))
        }
    }

    private var activityChart: some View {
        card(title: "最近 7 天更新", subtitle: "按最后编辑日期统计") {
            Chart(store.dailyActivity) { point in
                AreaMark(
                    x: .value("日期", point.date, unit: .day),
                    y: .value("更新", point.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.clay.opacity(0.30), AppTheme.clay.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("日期", point.date, unit: .day),
                    y: .value("更新", point.count)
                )
                .foregroundStyle(AppTheme.clay)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...max(store.dailyActivity.map(\.count).max() ?? 0, 3))
            .frame(height: 220)
        }
    }

    private var tagCloud: some View {
        card(title: "常用标签", subtitle: "按出现次数排序") {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120), spacing: 10)],
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(store.tagStats.prefix(10)) { stat in
                    HStack(spacing: 6) {
                        TagChip(text: stat.tag)
                        Text("\(stat.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private func card<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.card,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AppTheme.hairline)
        )
    }
}

#Preview("写作洞察 · iPad") {
    NavigationStack {
        InsightsView()
            .environment(MemoStore.seeded())
    }
}

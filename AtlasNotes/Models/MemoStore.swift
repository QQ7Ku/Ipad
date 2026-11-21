import Foundation
import Observation

/// 应用级状态。示例数据在内存中维护，启动时固定注入，便于 #Preview 与 CI 截图复现。
@Observable
final class MemoStore {
    enum SortOrder: String, CaseIterable, Identifiable {
        case updated
        case created
        case title

        var id: String { rawValue }

        var label: String {
            switch self {
            case .updated: "最近更新"
            case .created: "最近创建"
            case .title: "标题排序"
            }
        }
    }

    var notebooks: [Notebook]
    var memos: [Memo]
    var notebookSelection: NotebookSelection? = .all
    var selectedMemoID: Memo.ID?
    var searchText: String = ""
    var showFavoritesOnly: Bool = false
    var sortOrder: SortOrder = .updated

    init(notebooks: [Notebook], memos: [Memo]) {
        self.notebooks = notebooks
        self.memos = memos
        self.selectedMemoID = memos.max(by: { $0.updatedAt < $1.updatedAt })?.id
    }

    // MARK: - 查询

    var selectedNotebookID: Notebook.ID? {
        guard let selection = notebookSelection,
              case let .notebook(id) = selection else {
            return nil
        }
        return id
    }

    var visibleMemos: [Memo] {
        var items = memos

        if let notebookID = selectedNotebookID {
            items = items.filter { $0.notebookID == notebookID }
        }
        if showFavoritesOnly {
            items = items.filter(\.isFavorite)
        }

        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !keyword.isEmpty {
            items = items.filter { memo in
                memo.title.localizedCaseInsensitiveContains(keyword)
                    || memo.body.localizedCaseInsensitiveContains(keyword)
                    || memo.tags.contains { $0.localizedCaseInsensitiveContains(keyword) }
            }
        }

        switch sortOrder {
        case .updated:
            items.sort { $0.updatedAt > $1.updatedAt }
        case .created:
            items.sort { $0.createdAt > $1.createdAt }
        case .title:
            items.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        }
        return items
    }

    func memo(id: Memo.ID) -> Memo? {
        memos.first { $0.id == id }
    }

    func notebook(id: Notebook.ID) -> Notebook? {
        notebooks.first { $0.id == id }
    }

    func memoCount(in notebookID: Notebook.ID) -> Int {
        memos.filter { $0.notebookID == notebookID }.count
    }

    var totalCharacters: Int {
        memos.reduce(0) { $0 + $1.characterCount }
    }

    var favoriteCount: Int {
        memos.filter(\.isFavorite).count
    }

    var tagStats: [TagStat] {
        let grouped = Dictionary(grouping: memos.flatMap(\.tags), by: { $0 })
        return grouped
            .map { TagStat(tag: $0.key, count: $0.value.count) }
            .sorted { lhs, rhs in
                lhs.count == rhs.count ? lhs.tag < rhs.tag : lhs.count > rhs.count
            }
    }

    var notebookStats: [NotebookStat] {
        notebooks.compactMap { notebook in
            let count = memoCount(in: notebook.id)
            guard count > 0 else { return nil }
            return NotebookStat(
                id: notebook.id,
                name: notebook.name,
                colorHex: notebook.colorHex,
                count: count
            )
        }
    }

    /// 最近 7 天按更新日期聚合，缺失日期补 0，保证折线图连续。
    var dailyActivity: [DailyActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }
            let count = memos.filter { calendar.isDate($0.updatedAt, inSameDayAs: date) }.count
            return DailyActivity(id: date, count: count)
        }
    }

    // MARK: - 写入

    func update(_ memo: Memo) {
        guard let index = memos.firstIndex(where: { $0.id == memo.id }) else { return }
        guard memos[index] != memo else { return }
        var updated = memo
        updated.updatedAt = .now
        memos[index] = updated
    }

    func addNotebook() {
        let notebook = Notebook(
            name: "新笔记本 \(notebooks.count + 1)",
            symbol: "folder",
            colorHex: "#8A6E52"
        )
        notebooks.append(notebook)
        notebookSelection = .notebook(notebook.id)
        selectedMemoID = nil
    }

    func addMemo() {
        guard let notebookID = selectedNotebookID ?? notebooks.first?.id else { return }
        let memo = Memo(
            title: "未命名笔记",
            body: "",
            notebookID: notebookID,
            tags: []
        )
        memos.append(memo)
        selectedMemoID = memo.id
    }

    func ensureSelectionIsVisible() {
        let visible = visibleMemos
        if let selectedMemoID, visible.contains(where: { $0.id == selectedMemoID }) {
            return
        }
        selectedMemoID = visible.first?.id
    }

    func resetToSeed() {
        let seed = MemoStore.seeded()
        notebooks = seed.notebooks
        memos = seed.memos
        notebookSelection = .all
        selectedMemoID = seed.selectedMemoID
        searchText = ""
        showFavoritesOnly = false
        sortOrder = .updated
    }
}

// MARK: - 图表数据

struct NotebookStat: Identifiable {
    let id: Notebook.ID
    let name: String
    let colorHex: String
    let count: Int
}

struct DailyActivity: Identifiable {
    let id: Date
    let count: Int
}

struct TagStat: Identifiable {
    let tag: String
    let count: Int
    var id: String { tag }
}

// MARK: - 示例数据

extension MemoStore {
    static func seeded() -> MemoStore {
        let calendar = Calendar.current

        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
        }

        let product = Notebook(name: "产品手记", symbol: "square.grid.2x2", colorHex: "#B45D33")
        let research = Notebook(name: "研究资料", symbol: "books.vertical", colorHex: "#4C6653")
        let life = Notebook(name: "生活随笔", symbol: "leaf", colorHex: "#C29A4B")

        let memos: [Memo] = [
            Memo(
                title: "把复杂留给系统，把简单留给用户",
                body: """
                好的工具不应该要求用户先学习一套方法论。界面要像一张干净的书桌：需要的东西伸手可及，不需要的东西安静地退到背景里。

                在 iPad 上，空间是优势也是责任。三栏布局让笔记本、笔记列表与正文同时可见，但每一栏都必须克制，只保留当前决策需要的信息。

                这条原则会继续约束后续的交互：少一个按钮，多一次顺畅的呼吸。
                """,
                notebookID: product.id,
                tags: ["产品", "原则"],
                isFavorite: true,
                createdAt: daysAgo(12),
                updatedAt: daysAgo(0)
            ),
            Memo(
                title: "iPad 端写作流调研",
                body: """
                访谈了 5 位以 iPad 为主要写作设备的用户，高频动作集中在：快速捕捉、跨应用引用、长文改写。

                痛点不是功能缺失，而是切换成本。键盘快捷键、外接鼠标与触控三种输入方式需要在同一屏内自然共存。

                下一步验证：把“新建笔记”固定为两指轻点手势是否会被误触。
                """,
                notebookID: product.id,
                tags: ["调研", "iPad"],
                createdAt: daysAgo(6),
                updatedAt: daysAgo(1)
            ),
            Memo(
                title: "NavigationSplitView 三栏布局笔记",
                body: """
                NavigationSplitView 的平衡样式最适合 iPad 横屏：侧边栏、内容列表、详情三栏同时存在。

                关键细节：
                1. 每栏都设置 navigationSplitViewColumnWidth，避免旋转时比例跳变。
                2. 详情页使用稳定 id，切换笔记时重建编辑器状态。
                3. 在内容列表上使用 searchable，搜索框会进入导航栏，给正文让出空间。
                """,
                notebookID: research.id,
                tags: ["SwiftUI", "布局"],
                isFavorite: true,
                createdAt: daysAgo(9),
                updatedAt: daysAgo(2)
            ),
            Memo(
                title: "Swift Charts 的叙事顺序",
                body: """
                图表不是数据仓库，而是叙事工具。先给结论，再给细节。

                洞察页的顺序：总量卡片 → 笔记本分布 → 近七天更新 → 标签云。读者先知道规模，再理解结构，最后看到节奏。

                颜色只承担一项职责：区分笔记本。其他图形统一使用低饱和中性色，避免视觉噪音。
                """,
                notebookID: research.id,
                tags: ["SwiftUI", "图表", "设计"],
                createdAt: daysAgo(15),
                updatedAt: daysAgo(3)
            ),
            Memo(
                title: "本周复盘：节奏比速度更重要",
                body: """
                这周完成了三件事：整理调研记录、重写编辑器信息层级、把截图流程自动化。

                真正拖慢进度的不是难题，而是反复切换上下文。把同类任务堆在一起处理，效率明显更高。

                下周只保留一个目标：让笔记从空白到可读的时间缩短到 30 秒以内。
                """,
                notebookID: life.id,
                tags: ["复盘", "专注"],
                createdAt: daysAgo(5),
                updatedAt: daysAgo(4)
            ),
            Memo(
                title: "秋季阅读清单",
                body: """
                《设计中的设计》——重新理解“无”的价值。
                《The Craftsman》——手艺与重复劳动的区别。
                《写作这回事》——把初稿和修改彻底分开。
                《禅与摩托车维修艺术》——质量无法被定义，但可以被感知。
                """,
                notebookID: life.id,
                tags: ["阅读"],
                createdAt: daysAgo(20),
                updatedAt: daysAgo(6)
            ),
            Memo(
                title: "设计系统：颜色与留白",
                body: """
                主色使用陶土橙，只在可操作元素上出现；大面积背景保持暖灰，让长文阅读更柔和。

                间距采用 8 的倍数：8 / 16 / 24 / 32。卡片圆角 22，按钮圆角 12，形成清晰层级。

                留白不是空缺，而是为注意力划出的边界。
                """,
                notebookID: product.id,
                tags: ["设计", "颜色"],
                createdAt: daysAgo(10),
                updatedAt: daysAgo(2)
            ),
            Memo(
                title: "关于专注的三个实验",
                body: """
                实验一：把手机放到另一个房间，单次专注时长从 18 分钟提升到 41 分钟。

                实验二：写作前先写三行提纲，开始成本显著下降。

                实验三：关闭所有非人际通知，焦虑感下降，但没有影响真正重要的事情。

                结论：专注不是意志力问题，而是环境设计问题。
                """,
                notebookID: life.id,
                tags: ["专注", "复盘"],
                isFavorite: true,
                createdAt: daysAgo(3),
                updatedAt: daysAgo(0)
            )
        ]

        return MemoStore(
            notebooks: [product, research, life],
            memos: memos
        )
    }
}

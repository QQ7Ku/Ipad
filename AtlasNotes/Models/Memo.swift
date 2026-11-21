import Foundation

/// 单篇笔记。正文使用纯文本，保证在 iPad 上编辑与云端编译都不依赖数据库迁移。
struct Memo: Identifiable, Hashable {
    let id: UUID
    var title: String
    var body: String
    var notebookID: Notebook.ID
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        notebookID: Notebook.ID,
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.notebookID = notebookID
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 列表摘要：压平换行，避免多行截断时出现空行。
    var excerpt: String {
        let flattened = body
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return flattened.isEmpty ? "空笔记" : flattened
    }

    /// 中英文混排下比按空格分词更稳定的字数统计。
    var characterCount: Int {
        body.filter { !$0.isWhitespace && !$0.isNewline }.count
    }
}

/// 侧边栏筛选值。使用枚举而不是可选值，保证“全部笔记”可以被明确选中。
enum NotebookSelection: Hashable {
    case all
    case notebook(Notebook.ID)
}

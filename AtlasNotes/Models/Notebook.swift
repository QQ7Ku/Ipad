import Foundation

/// 笔记本：笔记的一级归类，颜色用于侧边栏图标与图表。
struct Notebook: Identifiable, Hashable {
    let id: UUID
    var name: String
    var symbol: String
    var colorHex: String

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        colorHex: String
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
    }
}

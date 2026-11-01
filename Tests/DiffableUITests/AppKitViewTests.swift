#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import Diffable
import Testing
@testable import DiffableUI

private let algorithms: [DiffAlgorithm] = [.heckel, .myers]

@MainActor
@Suite("NSMenu")
struct NSMenuDiffTests {
    @Test("menu items follow the models", arguments: algorithms)
    func followsModels(algorithm: DiffAlgorithm) {
        var generator = Seeded(seed: 51)
        for _ in 0 ..< 300 {
            let old = randomRows(maxCount: 8, using: &generator)
            let new = mutated(old, using: &generator)
            let menu = NSMenu()
            old.forEach { menu.addItem(NSMenuItem(
                title: "\($0.id):\($0.value)",
                action: nil,
                keyEquivalent: ""
            )) }

            menu.applyDiff(
                from: old,
                to: new,
                algorithm: algorithm,
                makeItem: { NSMenuItem(
                    title: "\($0.id):\($0.value)",
                    action: nil,
                    keyEquivalent: ""
                ) },
                update: { item, row in item.title = "\(row.id):\(row.value)" }
            )

            #expect(
                menu.items.map(\.title) == new.map { "\($0.id):\($0.value)" },
                "\(old.map(\.id)) → \(new.map(\.id))"
            )
        }
    }

    @Test("an untouched item keeps its identity")
    func keepsUntouchedItem() {
        let menu = NSMenu()
        let old = rows("abc")
        old.forEach { menu.addItem(NSMenuItem(title: $0.id, action: nil, keyEquivalent: "")) }
        let kept = menu.items[1]

        menu.applyDiff(
            from: old,
            to: rows("xbc"),
            makeItem: { NSMenuItem(title: $0.id, action: nil, keyEquivalent: "") },
            update: { _, _ in }
        )

        #expect(menu.items[1] === kept)
    }
}

@MainActor
@Suite("NSStackView")
struct NSStackViewDiffTests {
    @Test("arranged views follow the models", arguments: algorithms)
    func followsModels(algorithm: DiffAlgorithm) {
        var generator = Seeded(seed: 52)
        func makeView(_ row: Row) -> NSView {
            let view = NSView()
            view.identifier = NSUserInterfaceItemIdentifier("\(row.id):\(row.value)")
            return view
        }
        for _ in 0 ..< 300 {
            let old = randomRows(maxCount: 8, using: &generator)
            let new = mutated(old, using: &generator)
            let stack = NSStackView()
            old.forEach { stack.addArrangedSubview(makeView($0)) }

            stack.applyDiff(from: old, to: new, algorithm: algorithm, makeView: makeView) { view, row in
                view.identifier = NSUserInterfaceItemIdentifier("\(row.id):\(row.value)")
            }

            #expect(stack.arrangedSubviews.compactMap { $0.identifier?.rawValue } == new
                .map { "\($0.id):\($0.value)" })
            #expect(stack.subviews.count == new.count)
        }
    }

    @Test("a reordered view is reused, not recreated")
    func reusesViews() {
        let stack = NSStackView()
        let old = rows("abc")
        for row in old {
            let view = NSView()
            view.identifier = NSUserInterfaceItemIdentifier(row.id)
            stack.addArrangedSubview(view)
        }
        let first = stack.arrangedSubviews[0]

        stack.applyDiff(from: old, to: rows("bca"), makeView: { _ in NSView() }, update: { _, _ in })

        #expect(stack.arrangedSubviews.last === first)
    }
}

private final class RowSource: NSObject, NSTableViewDataSource {
    var rows: [Row] = []
    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }
}

@MainActor
@Suite("NSTableView")
struct NSTableViewDiffTests {
    private func makeTable(_ source: RowSource) -> NSTableView {
        let table = NSTableView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
        table.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("c")))
        table.dataSource = source
        table.reloadData()
        return table
    }

    @Test("the row count stays consistent through random diffs", arguments: algorithms)
    func consistentRowCount(algorithm: DiffAlgorithm) {
        var generator = Seeded(seed: 53)
        let source = RowSource()
        let table = makeTable(source)

        for _ in 0 ..< 300 {
            let old = source.rows
            let new = mutated(
                old.isEmpty ? randomRows(maxCount: 8, using: &generator) : old,
                using: &generator
            )

            table.applyDiff(
                from: old,
                to: new,
                algorithm: algorithm,
                animations: NSTableView.DiffAnimations(insert: [], remove: [])
            ) {
                source.rows = new
            }

            #expect(table.numberOfRows == new.count, "\(old.map(\.id)) → \(new.map(\.id))")
        }
    }

    @Test("an empty table receives rows")
    func fillsEmptyTable() {
        let source = RowSource()
        let table = makeTable(source)

        table.applyDiff(from: [], to: rows("abc")) { source.rows = rows("abc") }

        #expect(table.numberOfRows == 3)
    }
}

private final class PathBox: NSObject {
    let path: TreePath

    init(_ path: TreePath) {
        self.path = path
    }

    override func isEqual(_ object: Any?) -> Bool {
        (object as? PathBox)?.path == path
    }

    override var hash: Int {
        path.hashValue
    }
}

private struct Entry: DiffableTree {
    let name: String
    var size = 0
    var children: [Entry] = []

    var primaryKeyValue: String {
        name
    }

    static func == (lhs: Entry, rhs: Entry) -> Bool {
        lhs.name == rhs.name && lhs.size == rhs.size
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name); hasher.combine(size)
    }
}

private final class OutlineSource: NSObject, NSOutlineViewDataSource {
    var roots: [Entry] = []

    private func children(of item: Any?) -> [Entry] {
        guard let box = item as? PathBox else { return roots }

        var level = roots
        var found: Entry?
        for component in box.path.components {
            found = level.first { $0.name == component }
            level = found?.children ?? []
        }
        return found?.children ?? []
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {
        children(of: item).count
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        isItemExpandable item: Any
    ) -> Bool {
        !children(of: item).isEmpty
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let parent = (item as? PathBox)?.path.components ?? []
        return PathBox(TreePath(parent + [children(of: item)[index].name]))
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        objectValueFor tableColumn: NSTableColumn?,
        byItem item: Any?
    ) -> Any? {
        nil
    }
}

@MainActor
@Suite("NSOutlineView")
struct NSOutlineViewDiffTests {
    private func makeOutline(_ source: OutlineSource) -> NSOutlineView {
        let outline = NSOutlineView(frame: NSRect(x: 0, y: 0, width: 200, height: 400))
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("c"))
        outline.addTableColumn(column)
        outline.outlineTableColumn = column
        outline.dataSource = source
        outline.reloadData()
        return outline
    }

    private func visibleRows(_ nodes: [Entry], parent: [String], outline: NSOutlineView) -> Int {
        nodes.reduce(0) { total, node in
            let path = parent + [node.name]
            let expanded = outline.isItemExpanded(PathBox(TreePath(path)))
            return total + 1 + (expanded ? visibleRows(node.children, parent: path, outline: outline) : 0)
        }
    }

    @Test("top level inserts, deletes and moves keep the row count consistent", arguments: algorithms)
    func topLevel(algorithm: DiffAlgorithm) {
        var generator = Seeded(seed: 54)
        let source = OutlineSource()
        let outline = makeOutline(source)

        for _ in 0 ..< 200 {
            let old = source.roots
            let ids = (old.isEmpty ? randomRows(maxCount: 6, using: &generator) : mutated(
                old.map { Row(id: $0.name, value: $0.size) },
                using: &generator
            ))
            let new = ids.map { Entry(name: $0.id, size: $0.value) }

            outline.applyDiff(
                from: old,
                to: new,
                algorithm: algorithm,
                animations: NSTableView.DiffAnimations(insert: [], remove: []),
                item: { PathBox($0) },
                updateData: { source.roots = new }
            )

            #expect(outline.numberOfRows == new.count, "\(old.map(\.name)) → \(new.map(\.name))")
        }
    }

    @Test("a child inserted and another removed inside an expanded folder")
    func nestedChanges() {
        let source = OutlineSource()
        source.roots = [
            Entry(name: "src", children: [Entry(name: "a"), Entry(name: "b")]),
            Entry(name: "docs")
        ]
        let outline = makeOutline(source)
        outline.expandItem(PathBox(TreePath(["src"])))
        #expect(outline.numberOfRows == 4)

        let old = source.roots
        let new = [
            Entry(name: "src", children: [Entry(name: "b"), Entry(name: "c"), Entry(name: "d")]),
            Entry(name: "docs")
        ]

        outline.applyDiff(
            from: old,
            to: new,
            animations: NSTableView.DiffAnimations(insert: [], remove: []),
            item: { PathBox($0) },
            updateData: { source.roots = new }
        )

        #expect(outline.numberOfRows == visibleRows(new, parent: [], outline: outline))
        #expect(outline.numberOfRows == 5)
    }
}

private final class ItemSource: NSObject, NSCollectionViewDataSource {
    var rows: [Row] = []
    func collectionView(
        _ collectionView: NSCollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        rows.count
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("cell"), for: indexPath)
    }
}

private final class CellItem: NSCollectionViewItem {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 40, height: 40))
    }
}

@MainActor
@Suite("NSCollectionView")
struct NSCollectionViewDiffTests {
    @Test("the item count stays consistent through a diff")
    func consistentItemCount() async {
        let source = ItemSource()
        let collection = NSCollectionView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 40, height: 40)
        collection.collectionViewLayout = layout
        collection.register(CellItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("cell"))
        collection.dataSource = source
        source.rows = rows("abcd")
        collection.reloadData()

        let new = rows("bcxd")
        await withCheckedContinuation { continuation in
            collection.applyDiff(
                from: source.rows,
                to: new,
                updateData: { source.rows = new },
                completion: { continuation.resume() }
            )
        }

        #expect(collection.numberOfItems(inSection: 0) == 4)
    }
}

#endif

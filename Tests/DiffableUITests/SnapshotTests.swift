#if (canImport(UIKit) || canImport(AppKit)) && !os(watchOS)
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import Diffable
import Testing
@testable import DiffableUI

private struct Folder: DiffableTree {
    let name: String
    var size = 0
    var children: [Folder] = []

    var id: String {
        name
    }

    static func == (lhs: Folder, rhs: Folder) -> Bool {
        lhs.name == rhs.name && lhs.size == rhs.size
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name); hasher.combine(size)
    }
}

@Suite("Snapshots")
struct SnapshotTests {
    @Test("a sectioned snapshot has one section per section and unique item ids")
    func sectionedSnapshot() {
        guard #available(iOS 13.0, tvOS 13.0, macOS 10.15.1, *) else { return }

        let sections = [
            Group(title: "Inbox", children: rows("12")),
            Group(title: "Sent", children: rows("12"))
        ]

        let snapshot = NSDiffableDataSourceSnapshot<DiffID, SnapshotItemID>(sections: sections)

        #expect(snapshot.sectionIdentifiers == ["Inbox", "Sent"])
        #expect(snapshot.numberOfItems == 4)
        #expect(snapshot.itemIdentifiers(inSection: "Sent").map(\.item) == ["1", "2"])
        #expect(Set(snapshot.itemIdentifiers).count == 4)
    }

    @Test("the snapshot of an edit still describes the new data")
    func editedSnapshot() {
        guard #available(iOS 13.0, tvOS 13.0, macOS 10.15.1, *) else { return }

        let old = [Group(title: "Inbox", children: rows("12"))]
        let new = [Group(title: "Inbox", header: 1, children: rows("12", value: 1))]

        let snapshot = NSDiffableDataSourceSnapshot<DiffID, SnapshotItemID>(from: old, to: new)

        #expect(snapshot.sectionIdentifiers == ["Inbox"])
        #expect(snapshot.numberOfItems == 2)
    }

    @Test("updatedPaths lists the nodes whose own content changed")
    func updatedPaths() {
        let old = [Folder(name: "root", children: [Folder(name: "a", size: 1), Folder(name: "b")])]
        let new = [Folder(
            name: "root",
            children: [Folder(name: "a", size: 2), Folder(name: "b"), Folder(name: "c")]
        )]

        #expect(old.updatedPaths(to: new) == [TreePath(["root", "a"])])
    }

#if canImport(UIKit)
    @available(iOS 14.0, tvOS 14.0, *)
    @Test("an outline snapshot nests children under their parent and expands what is asked")
    func outlineSnapshot() {
        let roots = [Folder(
            name: "root",
            children: [Folder(name: "src", children: [Folder(name: "a")]), Folder(name: "docs")]
        )]

        let snapshot = NSDiffableDataSourceSectionSnapshot<TreePath>(
            roots: roots,
            expanded: [TreePath(["root"])]
        )

        #expect(snapshot.items.count == 4)
        #expect(snapshot.rootItems == [TreePath(["root"])])
        #expect(snapshot.parent(of: TreePath(["root", "src", "a"])) == TreePath(["root", "src"]))
        #expect(snapshot.isExpanded(TreePath(["root"])))
        #expect(!snapshot.isExpanded(TreePath(["root", "src"])))
        #expect(snapshot.visibleItems.count == 3)
    }
#endif
}

private struct Group: DiffableTree {
    let title: String
    var header = 0
    var children: [Row] = []

    var id: String {
        title
    }

    static func == (lhs: Group, rhs: Group) -> Bool {
        lhs.title == rhs.title && lhs.header == rhs.header
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title); hasher.combine(header)
    }
}
#endif

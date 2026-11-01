import Diffable
import Testing
@testable import DiffableUI

private struct Node: DiffableTree {
    let name: String
    var size = 0
    var children: [Node] = []

    var id: String {
        name
    }

    static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.name == rhs.name && lhs.size == rhs.size
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name); hasher.combine(size)
    }
}

@Suite("ListChanges")
struct ListChangesTests {
    @Test("built from the array diff")
    func fromDiff() {
        let changes = rows("abc").listChanges(to: rows("bcd"))
        #expect(changes.deletions == [0])
        #expect(changes.insertions == [2])
        #expect(!changes.isEmpty)
    }

    @Test("no change is empty")
    func empty() {
        #expect(rows("abc").listChanges(to: rows("abc")).isEmpty)
    }

    @Test("index sets")
    func indexSets() {
        let changes = ListChanges(updates: [3], insertions: [1, 2], deletions: [0])
        #expect(changes.insertionIndexes == [1, 2])
        #expect(changes.deletionIndexes == [0])
        #expect(changes.updateIndexes == [3])
    }

    @Test("built from one level of tree siblings")
    func fromSiblings() {
        let old = [Node(name: "a"), Node(name: "b"), Node(name: "c", size: 1)]
        let new = [Node(name: "b"), Node(name: "c", size: 2), Node(name: "a"), Node(name: "d")]

        let changes = ListChanges(siblings: old.treeDiff(new))

        #expect(changes.insertions == [3])
        #expect(changes.updates == [1])
        #expect(changes.deletions.isEmpty)
        #expect(changes.moves.count == 1)
        #expect(changes.moves[0].from == 0 && changes.moves[0].to == 2)
    }

    @Test("TreePath")
    func treePath() {
        let path = TreePath(["root", "src", "a.swift"])
        #expect(path.description == "root/src/a.swift")
        #expect(path.parent == TreePath(["root", "src"]))
        #expect(TreePath(["root"]).parent == nil)
    }

    @Test("TreePath components can be any id, not only strings")
    func treePathWithMixedIds() {
        let path = TreePath([1, "src", 2])
        #expect(path.description == "1/src/2")
        #expect(path.parent == TreePath([1, "src"]))
        #expect(TreePath([1]) != TreePath(["1"]))
    }
}

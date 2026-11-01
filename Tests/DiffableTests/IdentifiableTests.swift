import Foundation
import Testing
@testable import Diffable

private struct Message: Identifiable, Diffable {
    let id: UUID
    var text: String
}

private struct IntNode: DiffableTree {
    let id: Int
    var size = 0
    var children: [IntNode] = []

    static func == (lhs: IntNode, rhs: IntNode) -> Bool {
        lhs.id == rhs.id && lhs.size == rhs.size
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(size)
    }
}

private struct ByInt: Diffable {
    let id: Int
}

private struct ByString: Diffable {
    let id: String
}

@Suite("Identifiable ids")
struct IdentifiableTests {
    @Test("a model that is already Identifiable only has to add Diffable", arguments: algorithms)
    func uuidModel(algorithm: DiffAlgorithm) {
        let first = Message(id: UUID(), text: "a")
        let second = Message(id: UUID(), text: "b")
        let third = Message(id: UUID(), text: "c")

        let result = [first, second].diff([Message(id: first.id, text: "a2"), second, third], algorithm: algorithm)

        #expect(result.updates == [0])
        #expect(result.insertions == [2])
        #expect(result.deletions.isEmpty)
        #expect(result.moves.isEmpty)
    }

    @Test("the ids 1 and \"1\" are different identities")
    func intAndStringIdsDoNotCollide() {
        #expect(DiffID(1) != DiffID("1"))
        #expect(DiffID(1) == DiffID(1))
        #expect(DiffID(1).hashValue == DiffID(1).hashValue)
    }

    @Test("literals convert to DiffID")
    func literals() {
        let text: DiffID = "src"
        let number: DiffID = 42
        #expect(text == DiffID("src"))
        #expect(number == DiffID(42))
        #expect(["a", "b"] as [DiffID] == [DiffID("a"), DiffID("b")])
    }

    @Test("wrapping a DiffID does not change its identity")
    func nestedWrapping() {
        #expect(DiffID(DiffID("a")) == DiffID("a"))
        #expect(DiffID(DiffID("a")).hashValue == DiffID("a").hashValue)
    }

    @Test("description prints the wrapped id")
    func description() {
        #expect(DiffID("src").description == "src")
        #expect(DiffID(7).description == "7")
        #expect(UUID().diffIDDescriptionMatches)
    }

    @Test("AnyDiffable keeps different types apart even when the ids look alike")
    func typedAnyDiffable() {
        let old: [AnyDiffable] = [AnyDiffable(ByInt(id: 1))]
        let new: [AnyDiffable] = [AnyDiffable(ByString(id: "1"))]

        let result = old.diff(new)

        #expect(result.deletions == [0])
        #expect(result.insertions == [0])
        #expect(result.updates.isEmpty)
    }

    @Test("tree paths hold the real ids", arguments: algorithms)
    func treePathsHoldRealIds(algorithm: DiffAlgorithm) {
        let old = IntNode(id: 1, children: [IntNode(id: 2, size: 1), IntNode(id: 3)])
        let new = IntNode(id: 1, children: [IntNode(id: 2, size: 2), IntNode(id: 3)])

        let changes = old.treeDiff(to: new, algorithm: algorithm)

        #expect(changes.count == 1)
        #expect(changes[0].key == 1)
        #expect(changes[0].children[0].path == [1, 2])
        #expect(changes[0].children[0].kind == .update)
    }

    @Test("a tree diff can be produced in a task and returned to the caller (TreeChange is Sendable)")
    func treeChangeCrossesTasks() async {
        let old = [IntNode(id: 1, children: [IntNode(id: 2)])]
        let new = [IntNode(id: 1, children: [IntNode(id: 2), IntNode(id: 3)])]

        let changes = await Task.detached { old.treeDiff(new) }.value

        #expect(changes.first?.children.first?.kind == .insert)
        #expect(changes.first?.children.first?.path == [1, 3])
    }

    @Test("DiffID is Sendable and usable as a dictionary key")
    func dictionaryKey() async {
        let table: [DiffID: Int] = [DiffID("a"): 1, DiffID(2): 2]
        let value = await Task.detached { table[DiffID(2)] }.value
        #expect(value == 2)
        #expect(table[DiffID("a")] == 1)
    }
}

private extension UUID {
    var diffIDDescriptionMatches: Bool {
        DiffID(self).description == uuidString
    }
}

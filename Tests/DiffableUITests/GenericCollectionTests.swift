import Diffable
import Testing
@testable import DiffableUI

private struct Item: DiffableTree {
    let id: String
    var header = 0
    var children: [Row] = []

    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id && lhs.header == rhs.header
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(header)
    }
}

@Suite("DiffableUI on any random-access collection")
struct GenericCollectionTests {
    @Test("listChanges on slices equals listChanges on arrays", arguments: [DiffAlgorithm.heckel, .myers])
    func listChangesOnSlices(algorithm: DiffAlgorithm) {
        let old = rows("abcdef")
        let new = rows("xbcdyf")

        let fromSlices = old[1...].listChanges(to: new[1...], algorithm: algorithm)
        let fromArrays = Array(old[1...]).listChanges(to: Array(new[1...]), algorithm: algorithm)

        #expect(fromSlices.deletions == fromArrays.deletions)
        #expect(fromSlices.insertions == fromArrays.insertions)
        #expect(fromSlices.updates == fromArrays.updates)
        #expect(fromSlices.moves.map { [$0.from, $0.to] } == fromArrays.moves.map { [$0.from, $0.to] })
    }

    @Test("listChanges between a ContiguousArray and a slice")
    func mixedTypes() {
        let changes = ContiguousArray(rows("abc")).listChanges(to: rows("abcd")[...])
        #expect(changes.insertions == [3])
    }

    @Test("listChanges on a Range-like empty collection")
    func emptyCollections() {
        #expect(EmptyCollection<Row>().listChanges(to: rows("ab")).insertions == [0, 1])
        #expect(rows("ab")[...].listChanges(to: EmptyCollection<Row>()).deletions == [0, 1])
    }

    @Test("sectionedChanges on a ContiguousArray")
    func sectionedChangesOnContiguousArray() {
        let old = ContiguousArray([Item(id: "A", children: rows("ab")), Item(id: "B", children: rows("c"))])
        let new = ContiguousArray([Item(id: "A", children: rows("abx")), Item(id: "B", children: rows("c"))])

        let changes = old.sectionedChanges(to: new)

        #expect(changes.itemInsertions == [ItemPosition(section: 0, item: 2)])
        #expect(changes.sectionDeletions.isEmpty)
    }

    @Test("sectionedChanges on slices equals arrays")
    func sectionedChangesOnSlices() {
        let old = [Item(id: "skip"), Item(id: "A", children: rows("a")), Item(id: "B", children: rows("b"))]
        let new = [Item(id: "skip"), Item(id: "B", children: rows("b")), Item(id: "A", children: rows("a"))]

        let fromSlices = old[1...].sectionedChanges(to: new[1...])
        let fromArrays = Array(old[1...]).sectionedChanges(to: Array(new[1...]))

        #expect(fromSlices.sectionMoves.map { [$0.from, $0.to] } == fromArrays.sectionMoves.map { [$0.from, $0.to] })
        #expect(fromSlices.sectionDeletions == fromArrays.sectionDeletions)
        #expect(fromSlices.isEmpty == fromArrays.isEmpty)
    }

    @Test("SequentialPlan from a generic collection diff replays to the new list", arguments: [DiffAlgorithm.heckel, .myers])
    func sequentialPlanFromSlices(algorithm: DiffAlgorithm) {
        let old = rows("abcdef")[1...]
        let new = rows("xbfdea")[2...]

        let changes = old.listChanges(to: new, algorithm: algorithm)
        let plan = SequentialPlan(changes: changes, oldCount: old.count, newCount: new.count)

        var current: [String?] = old.map(\.id)
        for operation in plan.operations {
            switch operation {
            case let .remove(index):
                current.remove(at: index)
            case let .insert(index):
                current.insert(nil, at: index)
            case let .move(from, to):
                let value = current.remove(at: from)
                current.insert(value, at: to)
            }
        }
        #expect(zip(current, new).map { $0 ?? $1.id } == new.map(\.id))
    }
}

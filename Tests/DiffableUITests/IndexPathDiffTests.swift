#if !os(Linux)
import Foundation
import Testing
import Diffable
import DiffableUI

private struct Item: Diffable {
    let id: String
    var value = 0
    var primaryKeyValue: String { id }
}

private func items(_ ids: String, value: Int = 0) -> [Item] { ids.map { Item(id: String($0), value: value) } }

typealias IndexPathChanges = (updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(IndexPath, IndexPath)])

@Suite struct IndexPathDiffTests {

    @Test func mapsIndexesToTheGivenSection() {
        let changes: IndexPathChanges = items("abc").diff(items("bcd"), forSection: 2)

        #expect(changes.deletions == [IndexPath(item: 0, section: 2)])
        #expect(changes.insertions == [IndexPath(item: 2, section: 2)])
        #expect(changes.moves.isEmpty)
    }

    @Test func defaultSectionIsZero() {
        let changes: IndexPathChanges = items("a").diff(items("ab"))
        #expect(changes.insertions == [IndexPath(item: 1, section: 0)])
    }

    @Test func movesAreOldToNew() {
        let changes: IndexPathChanges = items("abcd").diff(items("bcda"), forSection: 1)

        #expect(changes.moves.count == 1)
        #expect(changes.moves[0].0 == IndexPath(item: 0, section: 1))
        #expect(changes.moves[0].1 == IndexPath(item: 3, section: 1))
    }

    @Test func updatesUseTheNewIndex() {
        let changes: IndexPathChanges = [Item(id: "a"), Item(id: "b")].diff([Item(id: "a"), Item(id: "b", value: 1)])
        #expect(changes.updates == [IndexPath(item: 1, section: 0)])
    }

    @Test func myersAlgorithmHasNoMoves() {
        let changes: IndexPathChanges = items("abcd").diff(items("bcda"), forSection: 0, algorithm: .myers)
        #expect(changes.moves.isEmpty)
        #expect(changes.deletions.count == 1 && changes.insertions.count == 1)
    }

    @Test func emptyArrays() {
        let changes: IndexPathChanges = [Item]().diff([])
        #expect(changes.updates.isEmpty && changes.insertions.isEmpty && changes.deletions.isEmpty && changes.moves.isEmpty)
    }

    @Test func matchesTheIntegerApi() {
        let integers = items("abcde").diff(items("cdxab"))
        let paths: IndexPathChanges = items("abcde").diff(items("cdxab"))

        #expect(paths.deletions.map(\.item) == integers.deletions)
        #expect(paths.insertions.map(\.item) == integers.insertions)
        #expect(paths.updates.map(\.item) == integers.updates)
        #expect(paths.moves.map { [$0.0.item, $0.1.item] } == integers.moves.map { [$0.0, $0.1] })
    }
}
#endif

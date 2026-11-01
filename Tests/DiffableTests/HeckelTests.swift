import Testing
@testable import Diffable

@Suite("Heckel")
struct HeckelTests {
    @Test("moving one item to the end is ONE move, not one per shifted item")
    func singleMove() {
        let result = items("abcd").diff(items("bcda"))
        #expect(result.moves.count == 1)
        #expect(result.moves.first?.0 == 0 && result.moves.first?.1 == 3)
        #expect(result.insertions.isEmpty && result.deletions.isEmpty)
    }

    @Test("moving one item to the front is ONE move")
    func singleMoveToFront() {
        let result = items("abcd").diff(items("dabc"))
        #expect(result.moves.count == 1)
        #expect(result.moves.first?.0 == 3 && result.moves.first?.1 == 0)
    }

    @Test("a swap needs one move")
    func swap() {
        #expect(items("ab").diff(items("ba")).moves.count == 1)
    }

    @Test("a full reverse of n items keeps one item and moves n-1")
    func reverse() {
        #expect(items("abcdef").diff(items("fedcba")).moves.count == 5)
    }

    @Test("moves are minimal for every permutation of 6 items")
    func permutationsAreMinimal() {
        var generator = SeededGenerator(seed: 7)
        let base = ["a", "b", "c", "d", "e", "f"]
        for _ in 0 ..< 300 {
            let shuffled = base.shuffled(using: &generator)
            let old = base.map { TestItem(id: $0) }
            let new = shuffled.map { TestItem(id: $0) }
            let oldIndexes = shuffled.map { base.firstIndex(of: $0)! } // base contains every shuffled element

            let result = old.diff(new)

            #expect(result.moves.count == base.count - longestIncreasingLength(oldIndexes), "\(shuffled)")
        }
    }

    @Test("an item that is moved and edited reports both")
    func movedAndUpdated() {
        let old = [TestItem(id: "a", value: 1), TestItem(id: "b"), TestItem(id: "c")]
        let new = [TestItem(id: "b"), TestItem(id: "c"), TestItem(id: "a", value: 2)]

        let result = old.diff(new)

        #expect(result.moves.count == 1)
        #expect(result.updates == [2])
    }

    @Test("unique keys sitting next to an anchor are all matched, nothing is deleted")
    func anchorsDoNotCreateNoise() {
        let result = items("xabcy").diff(items("abc"))
        #expect(result.deletions == [0, 4])
        #expect(result.insertions.isEmpty && result.moves.isEmpty)
    }

    @Test("the first element is expanded from its anchor (pass 4 starts at index 0)")
    func firstElementExpansion() {
        let result = items("axb").diff(items("axxb"))
        #expect(result.insertions.count == 1)
        #expect(result.deletions.isEmpty)
    }

    @Test(
        "duplicates are never anchors but still diff coherently",
        arguments: [("aab", "aba"), ("aaa", "aa"), ("abab", "baba")]
    )
    func duplicates(pair: (String, String)) {
        let old = items(pair.0)
        let new = items(pair.1)
        var diff = Diff()
        let outcome = replay(diff.process(old: old, new: new), old: old, new: new)
        #expect(outcome.problems.isEmpty, "\(outcome.problems)")
    }

    @Test("a longer run of unchanged items around one edit is untouched")
    func blockOfUnchangedItems() {
        let result = items("abcdefghij").diff(items("abcdeXghij"))
        #expect(result.deletions == [5])
        #expect(result.insertions == [5])
        #expect(result.moves.isEmpty)
    }

    @Test("LIS positions: empty, single, increasing, decreasing, mixed", arguments: [
        ([Int](), 0), ([5], 1), ([1, 2, 3, 4], 4), ([4, 3, 2, 1], 1), ([1, 2, 3, 0], 3), ([3, 1, 2, 5, 4], 3),
        (
            [2, 2, 2],
            1
        )
    ])
    func longestIncreasingSubsequence(values: [Int], expectedLength: Int) {
        let positions = Diff.longestIncreasingSubsequence(values)
        let picked = positions.sorted().map { values[$0] }

        #expect(positions.count == expectedLength)
        #expect(zip(picked, picked.dropFirst()).allSatisfy { $0 < $1 })
    }
}

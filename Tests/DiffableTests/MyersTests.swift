import Testing
@testable import Diffable

@Suite("Myers") struct MyersTests {

    @Test("never emits a move", arguments: edgeCases)
    func neverMoves(edit: EditCase) {
        let steps = Myers().process(old: items(edit.old), new: items(edit.new))
        #expect(steps.allSatisfy { if case .move = $0 { return false } else { return true } })
    }

    @Test("a rotation is one delete plus one insert")
    func rotation() {
        let result = items("abcd").diff(items("bcda"), algorithm: .myers)
        #expect(result.deletions.count == 1 && result.insertions.count == 1 && result.moves.isEmpty)
    }

    @Test("the script is the shortest possible (fewest edits) on every edge case", arguments: edgeCases)
    func shortestOnEdgeCases(edit: EditCase) {
        let lcs = longestCommonSubsequenceLength(edit.old.map(String.init), edit.new.map(String.init))
        let result = items(edit.old).diff(items(edit.new), algorithm: .myers)
        #expect(result.deletions.count == edit.old.count - lcs)
        #expect(result.insertions.count == edit.new.count - lcs)
    }

    @Test("the script is the shortest possible on random arrays with duplicates")
    func shortestOnRandomArrays() {
        var generator = SeededGenerator(seed: 11)
        for _ in 0..<1_500 {
            let old = randomItemsWithDuplicates(maxCount: 10, alphabetSize: 4, using: &generator)
            let new = randomItemsWithDuplicates(maxCount: 10, alphabetSize: 4, using: &generator)
            let lcs = longestCommonSubsequenceLength(old.map(\.id), new.map(\.id))

            let result = old.diff(new, algorithm: .myers)

            #expect(result.deletions.count == old.count - lcs, "\(ids(old)) → \(ids(new))")
            #expect(result.insertions.count == new.count - lcs, "\(ids(old)) → \(ids(new))")
        }
    }

    @Test("completely different large arrays still finish")
    func completelyDifferent() {
        let old = (0..<300).map { TestItem(id: "o\($0)") }
        let new = (0..<300).map { TestItem(id: "n\($0)") }
        let result = old.diff(new, algorithm: .myers)
        #expect(result.deletions.count == 300 && result.insertions.count == 300)
    }
}

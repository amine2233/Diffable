import Testing
@testable import Diffable

@Suite("Both algorithms")
struct AlgorithmTests {
    @Test("replaying the steps on old rebuilds new", arguments: algorithms, edgeCases)
    func replayRebuildsNew(algorithm: DiffAlgorithm, edit: EditCase) {
        let old = items(edit.old)
        let new = items(edit.new)

        let outcome = replay(algorithm.process(old: old, new: new), old: old, new: new)

        #expect(outcome.problems.isEmpty, "\(outcome.problems)")
        #expect(ids(outcome.result) == edit.new)
    }

    @Test("identical arrays produce no step", arguments: algorithms, ["", "a", "abc", "aaa", "abcabc"])
    func identicalArraysProduceNoStep(algorithm: DiffAlgorithm, content: String) {
        #expect(algorithm.process(old: items(content), new: items(content)).isEmpty)
    }

    @Test("a changed value on the same key is only an update", arguments: algorithms)
    func updateKeepsIdentity(algorithm: DiffAlgorithm) {
        let old = [TestItem(id: "a", value: 1), TestItem(id: "b", value: 1)]
        let new = [TestItem(id: "a", value: 1), TestItem(id: "b", value: 2)]

        let result = old.diff(new, algorithm: algorithm)

        #expect(result.updates == [1])
        #expect(result.insertions.isEmpty && result.deletions.isEmpty && result.moves.isEmpty)
    }

    @Test("empty to empty", arguments: algorithms)
    func emptyToEmpty(algorithm: DiffAlgorithm) {
        let result = [TestItem]().diff([], algorithm: algorithm)
        #expect(result.insertions.isEmpty && result.deletions.isEmpty && result.updates.isEmpty && result
            .moves.isEmpty)
    }

    @Test("deletions are OLD indexes, insertions are NEW indexes", arguments: algorithms)
    func indexSpaces(algorithm: DiffAlgorithm) {
        let result = items("abc").diff(items("bcd"), algorithm: algorithm)
        #expect(result.deletions == [0])
        #expect(result.insertions == [2])
    }

    @Test("every step index stays inside its array", arguments: algorithms, edgeCases)
    func indexesInRange(algorithm: DiffAlgorithm, edit: EditCase) {
        let result = items(edit.old).diff(items(edit.new), algorithm: algorithm)
        #expect(result.deletions.allSatisfy { $0 >= 0 && $0 < edit.old.count })
        #expect((result.insertions + result.updates).allSatisfy { $0 >= 0 && $0 < edit.new.count })
        #expect(result.moves
            .allSatisfy { $0.0 >= 0 && $0.0 < edit.old.count && $0.1 >= 0 && $0.1 < edit.new.count })
    }

    @Test("a large array with a few edits is handled", arguments: algorithms)
    func largeArray(algorithm: DiffAlgorithm) {
        let old = (0 ..< 10_000).map { TestItem(id: String($0)) }
        var new = old
        new.remove(at: 9_000)
        new.remove(at: 5_000)
        new.insert(TestItem(id: "x"), at: 100)

        let outcome = replay(algorithm.process(old: old, new: new), old: old, new: new)

        #expect(outcome.problems.isEmpty, "\(outcome.problems)")
        #expect(outcome.deletionCount == 2 && outcome.insertionCount == 1)
    }

    @Test("a reused Diff gives the same answer twice")
    func heckelInstanceCanBeReused() {
        var diff = Diff()
        let first = diff.process(old: items("ab"), new: items("ba"))
        let second = diff.process(old: items("ab"), new: items("ba"))
        #expect(first.map(\.debugDescription) == second.map(\.debugDescription))
    }

    @Test("DiffStep debug descriptions")
    func debugDescriptions() {
        #expect(DiffStep.insert(index: 1, value: 7).debugDescription == "+1@7")
        #expect(DiffStep.delete(index: 2, value: 7).debugDescription == "-2@7")
        #expect(DiffStep.move(from: 0, to: 3, value: 7).debugDescription == "0>3@7")
        #expect(DiffStep.update(index: 4, value: 7).debugDescription == "!4@7")
    }
}

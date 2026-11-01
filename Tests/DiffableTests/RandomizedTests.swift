import Testing
@testable import Diffable

@Suite("Randomized properties (seeded, reproducible)") struct RandomizedTests {

    @Test("unique keys: replay rebuilds new", arguments: algorithms)
    func uniqueKeys(algorithm: DiffAlgorithm) {
        var generator = SeededGenerator(seed: 1)
        let alphabet = ["a", "b", "c", "d", "e", "f", "g"]
        for _ in 0..<3_000 {
            let old = randomUniqueItems(alphabet: alphabet, using: &generator)
            let new = randomUniqueItems(alphabet: alphabet, using: &generator)

            let outcome = replay(algorithm.process(old: old, new: new), old: old, new: new)

            #expect(outcome.problems.isEmpty, "\(ids(old)) → \(ids(new)): \(outcome.problems)")
        }
    }

    @Test("duplicate keys: replay rebuilds new", arguments: algorithms)
    func duplicateKeys(algorithm: DiffAlgorithm) {
        var generator = SeededGenerator(seed: 2)
        for _ in 0..<3_000 {
            let old = randomItemsWithDuplicates(maxCount: 10, alphabetSize: 3, using: &generator)
            let new = randomItemsWithDuplicates(maxCount: 10, alphabetSize: 3, using: &generator)

            let outcome = replay(algorithm.process(old: old, new: new), old: old, new: new)

            #expect(outcome.problems.isEmpty, "\(ids(old)) → \(ids(new)): \(outcome.problems)")
        }
    }

    @Test("small edits of an array (delete, edit, shuffle, insert)", arguments: algorithms)
    func mutations(algorithm: DiffAlgorithm) {
        var generator = SeededGenerator(seed: 3)
        for _ in 0..<2_000 {
            let old = randomUniqueItems(alphabet: (0..<12).map(String.init), using: &generator)
            let new = mutate(old, using: &generator)

            let outcome = replay(algorithm.process(old: old, new: new), old: old, new: new)

            #expect(outcome.problems.isEmpty, "\(ids(old)) → \(ids(new)): \(outcome.problems)")
        }
    }

    @Test("diffing an array with itself gives nothing", arguments: algorithms)
    func selfDiff(algorithm: DiffAlgorithm) {
        var generator = SeededGenerator(seed: 4)
        for _ in 0..<500 {
            let array = randomItemsWithDuplicates(maxCount: 12, alphabetSize: 4, using: &generator)
            #expect(algorithm.process(old: array, new: array).isEmpty, "\(ids(array))")
        }
    }

    @Test("Myers is the optimum: Heckel, with each move counted as delete+insert, is never shorter")
    func myersIsTheOptimum() {
        var generator = SeededGenerator(seed: 5)
        for _ in 0..<1_500 {
            let old = randomItemsWithDuplicates(maxCount: 9, alphabetSize: 4, using: &generator)
            let new = randomItemsWithDuplicates(maxCount: 9, alphabetSize: 4, using: &generator)

            let heckel = old.diff(new, algorithm: .heckel)
            let myers = old.diff(new, algorithm: .myers)

            #expect(myers.deletions.count + myers.insertions.count
                        <= heckel.deletions.count + heckel.insertions.count + 2 * heckel.moves.count, "\(ids(old)) → \(ids(new))")
        }
    }

    @Test("Heckel with unique keys: deleted = only in old, inserted = only in new (a reorder is a move, never delete+insert)")
    func algorithmsAgreeOnUniqueKeys() {
        var generator = SeededGenerator(seed: 6)
        let alphabet = ["a", "b", "c", "d", "e", "f"]
        for _ in 0..<1_500 {
            let old = randomUniqueItems(alphabet: alphabet, using: &generator)
            let new = randomUniqueItems(alphabet: alphabet, using: &generator)
            let oldOnly = Set(old.map(\.id)).subtracting(new.map(\.id))
            let newOnly = Set(new.map(\.id)).subtracting(old.map(\.id))

            let result = old.diff(new, algorithm: .heckel)
            #expect(Set(result.deletions.map { old[$0].id }) == oldOnly, "\(ids(old)) → \(ids(new))")
            #expect(Set(result.insertions.map { new[$0].id }) == newOnly, "\(ids(old)) → \(ids(new))")
        }
    }
}

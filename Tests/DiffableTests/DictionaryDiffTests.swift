import Foundation
import Testing
@testable import Diffable

@Suite("Diff on Dictionary")
struct DictionaryDiffTests {
    @Test("insertions, deletions and updates")
    func basic() {
        let changes = ["a": 1, "b": 2, "c": 3].diff(["b": 2, "c": 30, "d": 4])

        #expect(changes.deletions == ["a": 1])
        #expect(changes.insertions == ["d": 4])
        #expect(changes.updates == ["c": .init(old: 3, new: 30)])
        #expect(!changes.isEmpty)
    }

    @Test("identical and empty dictionaries")
    func edgeCases() {
        #expect(["a": 1].diff(["a": 1]).isEmpty)
        #expect([String: Int]().diff([:]).isEmpty)
        #expect([String: Int]().diff(["a": 1]).insertions == ["a": 1])
        #expect(["a": 1].diff([:]).deletions == ["a": 1])
    }

    @Test("only keys change, only values change")
    func keysOnlyAndValuesOnly() {
        let keys = ["a": 1].diff(["b": 1])
        #expect(keys.deletions == ["a": 1] && keys.insertions == ["b": 1] && keys.updates.isEmpty)

        let values = ["a": 1, "b": 2].diff(["a": 10, "b": 20])
        #expect(values.updates.count == 2)
        #expect(values.insertions.isEmpty && values.deletions.isEmpty)
    }

    @Test("diffing a dictionary with itself is empty, and the result is Equatable")
    func idempotentAndEquatable() {
        let dictionary = ["a": 1, "b": 2]
        #expect(dictionary.diff(dictionary).isEmpty)
        #expect(dictionary.diff(dictionary) == DictionaryChanges<String, Int>())
        #expect(["a": 1].diff(["a": 2]) == DictionaryChanges(updates: ["a": .init(old: 1, new: 2)]))
    }

    @Test("non-string keys and structured values")
    func otherTypes() {
        let intKeys = [1: "one", 2: "two"].diff([2: "TWO", 3: "three"])
        #expect(intKeys.deletions == [1: "one"])
        #expect(intKeys.updates == [2: .init(old: "two", new: "TWO")])
        #expect(intKeys.insertions == [3: "three"])

        let arrays = ["a": [1, 2], "b": [3]].diff(["a": [1, 2], "b": [3, 4]])
        #expect(arrays.updates == ["b": .init(old: [3], new: [3, 4])])

        let diffableValues = ["k": TestItem(id: "x", value: 1)].diff(["k": TestItem(id: "x", value: 2)])
        #expect(diffableValues.updates["k"]?.new.value == 2)
    }

    @Test("a key whose value is nil is not confused with a missing key")
    func optionalValues() {
        let old: [String: Int?] = ["a": nil, "b": 1]
        let new: [String: Int?] = ["a": 1, "b": nil]

        let changes = old.diff(new)

        #expect(changes.updates.count == 2)
        #expect(changes.insertions.isEmpty && changes.deletions.isEmpty)
        #expect(["a": nil as Int?].diff([:]).deletions.count == 1)
        #expect([:].diff(["a": nil as Int?]).insertions.count == 1)
        #expect(["a": nil as Int?].diff(["a": nil as Int?]).isEmpty)
    }

    @Test("the diff is symmetric: insertions and deletions swap, updates swap old and new")
    func symmetry() {
        var generator = SeededGenerator(seed: 85)
        let keys = ["a", "b", "c", "d", "e"]
        for _ in 0 ..< 500 {
            let first = randomDictionary(keys: keys, using: &generator)
            let second = randomDictionary(keys: keys, using: &generator)

            let forward = first.diff(second)
            let backward = second.diff(first)

            #expect(forward.insertions == backward.deletions)
            #expect(forward.deletions == backward.insertions)
            #expect(forward.updates.mapValues(\.old) == backward.updates.mapValues(\.new))
            #expect(forward.updates.mapValues(\.new) == backward.updates.mapValues(\.old))
        }
    }

    @Test("the three key sets never overlap and cover every changed key")
    func keySetsAreDisjoint() {
        var generator = SeededGenerator(seed: 86)
        let keys = ["a", "b", "c", "d", "e", "f"]
        for _ in 0 ..< 500 {
            let old = randomDictionary(keys: keys, using: &generator)
            let new = randomDictionary(keys: keys, using: &generator)

            let changes = old.diff(new)
            let inserted = Set(changes.insertions.keys)
            let deleted = Set(changes.deletions.keys)
            let updated = Set(changes.updates.keys)

            #expect(inserted.isDisjoint(with: deleted) && inserted.isDisjoint(with: updated) && deleted.isDisjoint(with: updated))
            let changed = Set(keys).filter { old[$0] != new[$0] }
            #expect(inserted.union(deleted).union(updated) == changed)
        }
    }

    @Test("applying the changes to the old dictionary gives the new one")
    func randomOracle() {
        var generator = SeededGenerator(seed: 74)
        let keys = ["a", "b", "c", "d", "e", "f"]
        for _ in 0 ..< 1_500 {
            let old = randomDictionary(keys: keys, using: &generator)
            let new = randomDictionary(keys: keys, using: &generator)

            let changes = old.diff(new)

            var rebuilt = old
            for key in changes.deletions.keys { rebuilt[key] = nil }
            for (key, update) in changes.updates { rebuilt[key] = update.new }
            for (key, value) in changes.insertions { rebuilt[key] = value }
            #expect(rebuilt == new, "\(old) -> \(new)")
            #expect(changes.updates.allSatisfy { $0.value.old != $0.value.new })
            #expect(changes.deletions.allSatisfy { old[$0.key] == $0.value && new[$0.key] == nil })
            #expect(changes.insertions.allSatisfy { new[$0.key] == $0.value && old[$0.key] == nil })
        }
    }

    @Test("a large dictionary diff finishes")
    func large() {
        var old: [Int: Int] = [:]
        for index in 0 ..< 30_000 { old[index] = index }
        var new = old
        new[5] = -1
        new[7] = nil
        new[99_999] = 1

        let changes = old.diff(new)

        #expect(changes.updates.count == 1 && changes.deletions.count == 1 && changes.insertions.count == 1)
    }

    @Test("DictionaryChanges defaults and isEmpty")
    func resultType() {
        #expect(DictionaryChanges<String, Int>().isEmpty)
        #expect(!DictionaryChanges<String, Int>(insertions: ["a": 1]).isEmpty)
        #expect(!DictionaryChanges<String, Int>(deletions: ["a": 1]).isEmpty)
        #expect(!DictionaryChanges<String, Int>(updates: ["a": .init(old: 1, new: 2)]).isEmpty)
    }

    @Test("the result can cross tasks")
    func sendable() async {
        let old = ["a": 1]
        let new = ["a": 2, "b": 1]
        let changes = await Task.detached { old.diff(new) }.value
        #expect(changes.updates["a"] == .init(old: 1, new: 2))
        #expect(changes.insertions == ["b": 1])
    }
}

private func randomDictionary(keys: [String], using generator: inout SeededGenerator) -> [String: Int] {
    var result: [String: Int] = [:]
    for key in keys where Bool.random(using: &generator) {
        result[key] = Int.random(in: 0 ... 2, using: &generator)
    }
    return result
}

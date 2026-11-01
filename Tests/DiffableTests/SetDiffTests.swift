import Foundation
import Testing
@testable import Diffable

private struct Article: Diffable {
    let id: Int
}

private struct Video: Diffable {
    let id: Int
}

private struct Point: Hashable {
    let x: Int
    let y: Int
}

@Suite("Diff on Set")
struct SetDiffTests {
    // MARK: plain Hashable elements

    @Test("plain Hashable elements: insertions and deletions")
    func plainSet() {
        let changes = Set([1, 2, 3]).diff(Set([2, 3, 4]))
        #expect(changes.deletions == [1])
        #expect(changes.insertions == [4])
        #expect(changes.updates.isEmpty)
        #expect(!changes.isEmpty)
    }

    @Test("identical, empty and disjoint sets")
    func edgeCases() {
        #expect(Set([1, 2]).diff(Set([1, 2])).isEmpty)
        #expect(Set<Int>().diff(Set<Int>()).isEmpty)
        #expect(Set<Int>().diff(Set([1])).insertions == [1])
        #expect(Set([1]).diff(Set<Int>()).deletions == [1])
        let disjoint = Set([1, 2]).diff(Set([3, 4]))
        #expect(disjoint.deletions == [1, 2] && disjoint.insertions == [3, 4])
    }

    @Test("strings, tuples-like structs and optionals")
    func otherElementTypes() {
        #expect(Set(["a", "b"]).diff(Set(["b", "c"])).insertions == ["c"])
        #expect(Set([Point(x: 0, y: 0), Point(x: 1, y: 1)]).diff(Set([Point(x: 1, y: 1)])).deletions == [Point(x: 0, y: 0)])
        let optionals: Set<Int?> = [nil, 1]
        #expect(optionals.diff([1, 2]).deletions == [nil])
    }

    @Test("diffing a set with itself is empty, and the result is Equatable")
    func idempotentAndEquatable() {
        let set: Set = [1, 2, 3]
        #expect(set.diff(set).isEmpty)
        #expect(set.diff(set) == SetChanges<Int>())
        #expect(Set([1]).diff([2]) == SetChanges(insertions: [2], deletions: [1]))
    }

    @Test("a plain set diff is symmetric: insertions and deletions swap")
    func plainSymmetry() {
        var generator = SeededGenerator(seed: 81)
        for _ in 0 ..< 500 {
            let first = Set((0 ..< Int.random(in: 0 ... 8, using: &generator)).map { _ in Int.random(in: 0 ..< 10, using: &generator) })
            let second = Set((0 ..< Int.random(in: 0 ... 8, using: &generator)).map { _ in Int.random(in: 0 ..< 10, using: &generator) })

            let forward = first.diff(second)
            let backward = second.diff(first)

            #expect(forward.insertions == backward.deletions)
            #expect(forward.deletions == backward.insertions)
        }
    }

    @Test("plain sets: applying the changes rebuilds the new set")
    func randomPlainOracle() {
        var generator = SeededGenerator(seed: 73)
        for _ in 0 ..< 1_000 {
            let old = Set((0 ..< Int.random(in: 0 ... 8, using: &generator)).map { _ in Int.random(in: 0 ..< 10, using: &generator) })
            let new = Set((0 ..< Int.random(in: 0 ... 8, using: &generator)).map { _ in Int.random(in: 0 ..< 10, using: &generator) })

            let changes = old.diff(new)

            #expect(old.subtracting(changes.deletions).union(changes.insertions) == new)
            #expect(changes.insertions.isDisjoint(with: old))
            #expect(changes.deletions.isDisjoint(with: new))
        }
    }

    // MARK: Diffable elements

    @Test("Diffable elements: an edited element is one update")
    func updates() {
        let old: Set = [TestItem(id: "shoes", value: 1), TestItem(id: "hat", value: 2)]
        let new: Set = [TestItem(id: "shoes", value: 3), TestItem(id: "bag", value: 1)]

        let changes = old.diff(new)

        #expect(changes.updates == [.init(old: TestItem(id: "shoes", value: 1), new: TestItem(id: "shoes", value: 3))])
        #expect(changes.deletions == [TestItem(id: "hat", value: 2)])
        #expect(changes.insertions == [TestItem(id: "bag", value: 1)])
    }

    @Test("several updates at once, with an unchanged element left out")
    func severalUpdates() {
        let old: Set = [TestItem(id: "a", value: 1), TestItem(id: "b", value: 1), TestItem(id: "c", value: 1)]
        let new: Set = [TestItem(id: "a", value: 2), TestItem(id: "b", value: 2), TestItem(id: "c", value: 1)]

        let changes = old.diff(new)

        #expect(changes.updates.count == 2)
        #expect(Set(changes.updates.map(\.new.id)) == ["a", "b"])
        #expect(changes.insertions.isEmpty && changes.deletions.isEmpty)
    }

    @Test("an element with the same id and the same content is unchanged")
    func unchanged() {
        let item = TestItem(id: "a", value: 1)
        #expect(Set([item]).diff(Set([TestItem(id: "a", value: 1)])).isEmpty)
    }

    @Test("a Diffable update has the same old and new id")
    func updateKeepsId() {
        let changes = Set([TestItem(id: "a", value: 1)]).diff(Set([TestItem(id: "a", value: 9)]))
        #expect(changes.updates.first?.old.id == changes.updates.first?.new.id)
        #expect(changes.updates.first?.old != changes.updates.first?.new)
    }

    @Test("the same number with two different types is not an update")
    func idsOfDifferentTypesAreNotPaired() {
        let old: Set<AnyDiffable> = [AnyDiffable(Article(id: 1))]
        let new: Set<AnyDiffable> = [AnyDiffable(Video(id: 1))]

        let changes = old.diff(new)

        #expect(changes.updates.isEmpty)
        #expect(changes.insertions.count == 1 && changes.deletions.count == 1)
    }

    @Test("Diffable sets: applying the changes rebuilds the new set")
    func randomOracle() {
        var generator = SeededGenerator(seed: 72)
        let alphabet = ["a", "b", "c", "d", "e", "f", "g"]
        for _ in 0 ..< 1_500 {
            let old = Set(randomUniqueItems(alphabet: alphabet, using: &generator))
            let new = Set(randomUniqueItems(alphabet: alphabet, using: &generator))

            let changes = old.diff(new)

            var rebuilt = old.subtracting(changes.deletions).subtracting(changes.updates.map(\.old))
            rebuilt.formUnion(changes.insertions)
            rebuilt.formUnion(changes.updates.map(\.new))
            #expect(rebuilt == new, "\(old.map(\.id).sorted()) -> \(new.map(\.id).sorted())")
            #expect(changes.updates.allSatisfy { $0.old.id == $0.new.id && $0.old != $0.new })
            #expect(Set(changes.insertions.map(\.id)).isDisjoint(with: changes.deletions.map(\.id)))
        }
    }

    @Test("duplicate ids in a set still rebuild the new set")
    func duplicateIds() {
        var generator = SeededGenerator(seed: 82)
        for _ in 0 ..< 1_000 {
            let old = Set(randomItemsWithDuplicates(maxCount: 8, alphabetSize: 3, using: &generator))
            let new = Set(randomItemsWithDuplicates(maxCount: 8, alphabetSize: 3, using: &generator))

            let changes = old.diff(new)

            var rebuilt = old.subtracting(changes.deletions).subtracting(changes.updates.map(\.old))
            rebuilt.formUnion(changes.insertions)
            rebuilt.formUnion(changes.updates.map(\.new))
            #expect(rebuilt == new)
        }
    }

    @Test("a Diffable diff is symmetric: updates swap old and new")
    func diffableSymmetry() {
        var generator = SeededGenerator(seed: 83)
        let alphabet = ["a", "b", "c", "d", "e"]
        for _ in 0 ..< 500 {
            let first = Set(randomUniqueItems(alphabet: alphabet, using: &generator))
            let second = Set(randomUniqueItems(alphabet: alphabet, using: &generator))

            let forward = first.diff(second)
            let backward = second.diff(first)

            #expect(forward.insertions == backward.deletions)
            #expect(forward.deletions == backward.insertions)
            #expect(Set(forward.updates.map(\.old)) == Set(backward.updates.map(\.new)))
            #expect(Set(forward.updates.map(\.new)) == Set(backward.updates.map(\.old)))
        }
    }

    @Test("the counts add up: unchanged + inserted + updated = size of the new set")
    func countsAddUp() {
        var generator = SeededGenerator(seed: 84)
        let alphabet = ["a", "b", "c", "d", "e", "f"]
        for _ in 0 ..< 500 {
            let old = Set(randomUniqueItems(alphabet: alphabet, using: &generator))
            let new = Set(randomUniqueItems(alphabet: alphabet, using: &generator))

            let changes = old.diff(new)
            let unchanged = old.intersection(new).count

            #expect(unchanged + changes.insertions.count + changes.updates.count == new.count)
        }
    }

    @Test("a large set diff finishes")
    func large() {
        let old = Set((0 ..< 20_000).map { TestItem(id: String($0), value: 0) })
        var new = old
        new.remove(TestItem(id: "5", value: 0))
        new.insert(TestItem(id: "5", value: 1))
        new.insert(TestItem(id: "extra", value: 0))
        new.remove(TestItem(id: "7", value: 0))

        let changes = old.diff(new)

        #expect(changes.updates.count == 1)
        #expect(changes.insertions.count == 1)
        #expect(changes.deletions.count == 1)
    }

    // MARK: result type

    @Test("SetChanges defaults and isEmpty")
    func resultType() {
        let empty = SetChanges<Int>()
        #expect(empty.isEmpty)
        #expect(!SetChanges<Int>(insertions: [1]).isEmpty)
        #expect(!SetChanges<Int>(deletions: [1]).isEmpty)
        #expect(!SetChanges<Int>(updates: [.init(old: 1, new: 2)]).isEmpty)
    }

    @Test("the result can cross tasks")
    func sendable() async {
        let old: Set = [1, 2]
        let new: Set = [2, 3]
        let changes = await Task.detached { old.diff(new) }.value
        #expect(changes.insertions == [3] && changes.deletions == [1])
    }

    @Test("a Diffable result can cross tasks")
    func diffableSendable() async {
        let old: Set = [TestItem(id: "a", value: 1)]
        let new: Set = [TestItem(id: "a", value: 2)]
        let changes = await Task.detached { old.diff(new) }.value
        #expect(changes.updates.count == 1)
    }
}

import Foundation
import Testing
@testable import Diffable

private func flat(
    _ changes: (updates: [Int], insertions: [Int], deletions: [Int], moves: [(Int, Int)])
) -> [[Int]] {
    [changes.updates, changes.insertions, changes.deletions, changes.moves.flatMap { [$0.0, $0.1] }]
}

private struct Shifted: RandomAccessCollection {
    let base: [TestItem]
    let start: Int

    var startIndex: Int { start }
    var endIndex: Int { start + base.count }

    subscript(position: Int) -> TestItem {
        base[position - start]
    }
}

@Suite("Diff on any random-access collection")
struct RandomAccessCollectionDiffTests {
    @Test("a Range of Diffable values")
    func range() {
        let changes = (0 ..< 3).diff(1 ..< 4)
        #expect(changes.deletions == [0])
        #expect(changes.insertions == [2])
        #expect(changes.updates.isEmpty && changes.moves.isEmpty)
    }

    @Test("an empty collection on either side")
    func emptySides() {
        #expect(EmptyCollection<Int>().diff([1, 2]).insertions == [0, 1])
        #expect([1, 2][...].diff(EmptyCollection<Int>()).deletions == [0, 1])
        #expect(EmptyCollection<Int>().diff(EmptyCollection<Int>()).insertions.isEmpty)
    }

    @Test("two empty slices of different arrays")
    func emptySlices() {
        let changes = items("abc")[3...].diff(items("xyz")[3...])
        #expect(flat(changes) == [[], [], [], []])
    }

    @Test("indexes are offsets, not collection indexes", arguments: algorithms)
    func sliceOffsets(algorithm: DiffAlgorithm) {
        let old = items("abcdef")
        let new = items("xbcdyf")

        let slices = old[1...].diff(new[1...], algorithm: algorithm)
        let arrays = Array(old[1...]).diff(Array(new[1...]), algorithm: algorithm)

        #expect(flat(slices) == flat(arrays))
        #expect(slices.deletions.allSatisfy { $0 < 5 })
    }

    @Test("a collection whose startIndex is far from 0 still reports offsets", arguments: algorithms)
    func customStartIndex(algorithm: DiffAlgorithm) {
        let old = Shifted(base: items("abc"), start: 100)
        let new = Shifted(base: items("bcd"), start: -40)

        let changes = old.diff(new, algorithm: algorithm)

        #expect(changes.deletions == [0])
        #expect(changes.insertions == [2])
    }

    @Test("a reversed view is compared in its visible order")
    func reversedView() {
        #expect(items("abc").reversed().diff(items("cba")).insertions.isEmpty)
        #expect(flat(items("abc").reversed().diff(items("cba"))) == [[], [], [], []])
        #expect(items("abc").reversed().diff(items("abc")).moves.count == 2)
    }

    @Test("dropFirst and dropLast views", arguments: algorithms)
    func droppedViews(algorithm: DiffAlgorithm) {
        let changes = items("abcd").dropFirst().diff(items("abcd").dropLast(), algorithm: algorithm)
        #expect(changes.deletions == [2])
        #expect(changes.insertions == [0])
    }

    @Test("ContiguousArray and Array give the same result", arguments: algorithms)
    func contiguousArray(algorithm: DiffAlgorithm) {
        var generator = SeededGenerator(seed: 71)
        for _ in 0 ..< 300 {
            let old = randomItemsWithDuplicates(maxCount: 9, alphabetSize: 4, using: &generator)
            let new = randomItemsWithDuplicates(maxCount: 9, alphabetSize: 4, using: &generator)

            let generic = ContiguousArray(old).diff(ContiguousArray(new), algorithm: algorithm)
            let concrete = old.diff(new, algorithm: algorithm)

            #expect(flat(generic) == flat(concrete), "\(ids(old)) -> \(ids(new))")
        }
    }

    @Test("random slices equal the diff of the copied arrays", arguments: algorithms)
    func randomSlices(algorithm: DiffAlgorithm) {
        var generator = SeededGenerator(seed: 75)
        for _ in 0 ..< 300 {
            let old = randomItemsWithDuplicates(maxCount: 10, alphabetSize: 4, using: &generator)
            let new = randomItemsWithDuplicates(maxCount: 10, alphabetSize: 4, using: &generator)
            let cutOld = Int.random(in: 0 ... old.count, using: &generator)
            let cutNew = Int.random(in: 0 ... new.count, using: &generator)

            let slices = old[cutOld...].diff(new[cutNew...], algorithm: algorithm)
            let arrays = Array(old[cutOld...]).diff(Array(new[cutNew...]), algorithm: algorithm)

            #expect(flat(slices) == flat(arrays))
        }
    }

    @Test("two different collection types can be compared")
    func mixedTypes() {
        #expect(ContiguousArray(items("abc")).diff(items("abcd")[...]).insertions == [3])
        #expect(Shifted(base: items("ab"), start: 7).diff(items("ab")).deletions.isEmpty)
        #expect((1 ... 3).diff([2, 3, 4]).deletions == [0])
    }

    @Test("the one-argument overload uses Heckel, Myers never reports a move")
    func defaultAlgorithm() {
        let slice = items("abcd")[...]
        let moved = items("bcda")[...]
        #expect(slice.diff(moved).moves.count == 1)
        #expect(slice.diff(moved, algorithm: .myers).moves.isEmpty)
    }

    @Test("updates are detected through a generic collection", arguments: algorithms)
    func updates(algorithm: DiffAlgorithm) {
        let old = [TestItem(id: "a", value: 1), TestItem(id: "b")]
        let new = [TestItem(id: "a", value: 2), TestItem(id: "b")]
        #expect(ContiguousArray(old).diff(new[...], algorithm: algorithm).updates == [0])
    }

    @Test("a large slice is handled", arguments: algorithms)
    func largeSlice(algorithm: DiffAlgorithm) {
        let old = (0 ..< 8_000).map { TestItem(id: String($0)) }
        var new = old
        new.remove(at: 4_000)
        new.insert(TestItem(id: "x"), at: 10)

        let changes = old[500...].diff(new[500...], algorithm: algorithm)

        #expect(changes.deletions.count == 1 && changes.insertions.count == 1)
    }

    @Test("the result can cross tasks")
    func sendable() async {
        let old = items("abc")
        let new = items("abd")[...]
        let changes = await Task.detached { old[...].diff(new) }.value
        #expect(changes.insertions == [2] && changes.deletions == [2])
    }
}

@Suite("Tree diff on any random-access collection")
struct RandomAccessCollectionTreeDiffTests {
    @Test("a slice of trees equals the same trees in an array", arguments: algorithms)
    func slice(algorithm: DiffAlgorithm) {
        let old = [file("skip"), folder("src", file("a", size: 1))]
        let new = [file("skip"), folder("src", file("a", size: 2))]

        let fromSlices = old[1...].treeDiff(new[1...], algorithm: algorithm)
        let fromArrays = Array(old[1...]).treeDiff(Array(new[1...]), algorithm: algorithm)

        #expect(fromSlices == fromArrays)
        #expect(fromSlices[0].children[0].path == ["src", "a"])
        #expect(fromSlices[0].children[0].kind == .update)
    }

    @Test("ContiguousArray of trees", arguments: algorithms)
    func contiguous(algorithm: DiffAlgorithm) {
        let old = ContiguousArray([folder("a", file("x")), folder("b")])
        let new = ContiguousArray([folder("a", file("x"), file("y")), folder("b")])

        let changes = old.treeDiff(new, algorithm: algorithm)

        #expect(changes.count == 1)
        #expect(changes[0].children.map(\.kind) == [.insert])
    }

    @Test("an empty slice of trees")
    func empty() {
        let empty = [Node]()[...]
        #expect(empty.treeDiff(empty).isEmpty)
        #expect(empty.treeDiff([file("a")][...]).map(\.kind) == [.insert])
    }

    @Test("random trees: slices equal arrays", arguments: algorithms)
    func randomTrees(algorithm: DiffAlgorithm) {
        var generator = SeededGenerator(seed: 76)
        for _ in 0 ..< 300 {
            let old = randomTree(depth: 2, using: &generator)
            let new = mutateTree(old, depth: 2, shuffle: algorithm == .heckel, using: &generator)

            #expect(ContiguousArray(old).treeDiff(ContiguousArray(new), algorithm: algorithm)
                == old.treeDiff(new, algorithm: algorithm))
        }
    }
}

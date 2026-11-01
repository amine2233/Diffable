import Diffable
import Testing
@testable import DiffableUI

private func replay(_ plan: SequentialPlan, on old: [Row], new: [Row]) -> [String] {
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
    return zip(current, new).map { $0 ?? $1.id }
}

private func plan(from old: [Row], to new: [Row], algorithm: DiffAlgorithm) -> SequentialPlan {
    SequentialPlan(
        changes: old.listChanges(to: new, algorithm: algorithm),
        oldCount: old.count,
        newCount: new.count
    )
}

@Suite("SequentialPlan")
struct SequentialPlanTests {
    static let pairs: [[String]] = [
        ["", ""], ["", "abc"], ["abc", ""], ["abc", "abc"], ["abc", "cba"], ["abcd", "bcda"], [
            "abcd",
            "dabc"
        ],
        ["abcd", "badc"], ["abcde", "edcba"], ["abc", "xabc"], ["abc", "abcx"], ["abcd", "bd"], [
            "abcdef",
            "fxbyd"
        ],
        ["abcd", "dxbc"], ["abc", "xyz"]
    ]

    static let algorithms: [DiffAlgorithm] = [.heckel, .myers]

    @Test("replaying the plan rebuilds the new list", arguments: pairs, algorithms)
    func replayRebuildsNew(pair: [String], algorithm: DiffAlgorithm) {
        let old = rows(pair[0])
        let new = rows(pair[1])

        let result = replay(plan(from: old, to: new, algorithm: algorithm), on: old, new: new)

        #expect(result == new.map(\.id), "\(pair)")
    }

    @Test("random lists", arguments: algorithms)
    func randomLists(algorithm: DiffAlgorithm) {
        var generator = Seeded(seed: 31)
        for _ in 0 ..< 3_000 {
            let old = randomRows(maxCount: 9, using: &generator)
            let new = mutated(old, using: &generator)
            let current = plan(from: old, to: new, algorithm: algorithm)

            #expect(
                replay(current, on: old, new: new) == new.map(\.id),
                "\(old.map(\.id)) → \(new.map(\.id)) \(current.operations)"
            )
        }
    }

    @Test("random lists with duplicate keys", arguments: algorithms)
    func randomListsWithDuplicates(algorithm: DiffAlgorithm) {
        var generator = Seeded(seed: 32)
        for _ in 0 ..< 2_000 {
            let old = (0 ..< Int.random(in: 0 ... 8, using: &generator)).map { _ in Row(id: String(Int.random(
                in: 0 ..< 3,
                using: &generator
            ))) }
            let new = (0 ..< Int.random(in: 0 ... 8, using: &generator)).map { _ in Row(id: String(Int.random(
                in: 0 ..< 3,
                using: &generator
            ))) }
            let current = plan(from: old, to: new, algorithm: algorithm)

            #expect(
                replay(current, on: old, new: new) == new.map(\.id),
                "\(old.map(\.id)) → \(new.map(\.id)) \(current.operations)"
            )
        }
    }

    @Test("removals come first and in descending order")
    func removalsFirst() {
        let current = plan(from: rows("abcd"), to: rows("bd"), algorithm: .heckel)
        #expect(current.operations == [.remove(2), .remove(0)])
    }

    @Test("a list with only content updates has no operation")
    func noOperation() {
        let current = plan(from: rows("abc"), to: rows("abc", value: 1), algorithm: .heckel)
        #expect(current.operations.isEmpty)
    }
}

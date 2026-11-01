import Testing
@testable import Diffable

struct TestItem: Diffable {
    let id: String
    var value = 0
    var primaryKeyValue: String { id }
}

func items(_ ids: String, value: Int = 0) -> [TestItem] {
    ids.map { TestItem(id: String($0), value: value) }
}

func ids(_ items: [TestItem]) -> String {
    items.map(\.id).joined()
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct EditCase: Sendable, CustomTestStringConvertible {
    let old: String
    let new: String
    var testDescription: String { "\"\(old)\" → \"\(new)\"" }
}

let edgeCases: [EditCase] = [
    ("", ""), ("", "abc"), ("abc", ""), ("abc", "abc"),
    ("a", "a"), ("a", "b"), ("a", "aa"), ("aa", "a"),
    ("abc", "xyz"), ("abc", "cba"), ("abc", "bac"), ("ab", "ba"),
    ("abcd", "bcda"), ("abcd", "dabc"), ("abcdef", "defabc"), ("abcdef", "fedcba"),
    ("abc", "abcd"), ("abc", "xabc"), ("abc", "axbc"),
    ("abcd", "bcd"), ("abcd", "abc"), ("abcd", "acd"),
    ("aaa", "aaa"), ("aaa", "aa"), ("aa", "aaa"),
    ("abab", "baba"), ("aabb", "bbaa"), ("abcabc", "cbacba"),
    ("ab", "abab"), ("abab", "ab"), ("axa", "aax"), ("xaa", "aax"),
    ("abcde", "edcba"), ("abcde", "aXcXe"), ("abcde", "bdace")
].map { EditCase(old: $0.0, new: $0.1) }

let algorithms: [DiffAlgorithm] = [.heckel, .myers]

struct Replay {
    var result: [TestItem]
    var problems: [String]
    var updatedIndexes: Set<Int>
    var moveCount: Int
    var deletionCount: Int
    var insertionCount: Int
}

func replay(_ steps: [DiffStep<TestItem>], old: [TestItem], new: [TestItem]) -> Replay {
    var problems: [String] = []
    var deleted = Set<Int>()
    var movedFrom = Set<Int>()
    var updated = Set<Int>()
    var slots = [TestItem?](repeating: nil, count: new.count)
    var moves = 0
    var insertions = 0

    func place(_ item: TestItem, at index: Int, _ what: String) {
        guard slots.indices.contains(index) else {
            problems.append("\(what) target \(index) out of range")
            return
        }
        if slots[index] != nil { problems.append("\(what) target \(index) used twice") }
        slots[index] = item
    }

    for step in steps {
        switch step {
        case .delete(let index, _):
            if !old.indices.contains(index) { problems.append("delete \(index) out of range") }
            if !deleted.insert(index).inserted { problems.append("delete \(index) twice") }
        case .insert(let index, let value):
            insertions += 1
            if new.indices.contains(index), new[index] != value { problems.append("insert value mismatch at \(index)") }
            place(value, at: index, "insert")
        case .move(let from, let to, _):
            moves += 1
            guard old.indices.contains(from) else {
                problems.append("move from \(from) out of range")
                continue
            }
            if !movedFrom.insert(from).inserted { problems.append("move from \(from) twice") }
            place(old[from], at: to, "move")
        case .update(let index, let value):
            if new.indices.contains(index), new[index] != value { problems.append("update value mismatch at \(index)") }
            if !updated.insert(index).inserted { problems.append("update \(index) twice") }
        }
    }

    var survivors = old.enumerated()
        .filter { !deleted.contains($0.offset) && !movedFrom.contains($0.offset) }
        .map(\.element)
        .makeIterator()

    for index in slots.indices where slots[index] == nil {
        slots[index] = survivors.next()
    }
    if survivors.next() != nil { problems.append("more survivors than free slots") }

    let result = slots.compactMap { $0 }
    if result.count != new.count { problems.append("rebuilt \(result.count) items, expected \(new.count)") }

    var expectedUpdates = Set<Int>()
    for index in new.indices where index < result.count {
        if result[index].id != new[index].id {
            problems.append("slot \(index) holds \(result[index].id), expected \(new[index].id)")
        } else if result[index] != new[index] {
            expectedUpdates.insert(index)
        }
    }
    if expectedUpdates != updated { problems.append("updates \(updated.sorted()) expected \(expectedUpdates.sorted())") }

    return Replay(result: result, problems: problems, updatedIndexes: updated, moveCount: moves, deletionCount: deleted.count, insertionCount: insertions)
}

func longestCommonSubsequenceLength(_ a: [String], _ b: [String]) -> Int {
    var table = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
    for i in 0..<a.count {
        for j in 0..<b.count {
            table[i + 1][j + 1] = a[i] == b[j] ? table[i][j] + 1 : max(table[i][j + 1], table[i + 1][j])
        }
    }
    return table[a.count][b.count]
}

func longestIncreasingLength(_ values: [Int]) -> Int {
    var best = Array(repeating: 1, count: values.count)
    for i in values.indices {
        for j in 0..<i where values[j] < values[i] { best[i] = max(best[i], best[j] + 1) }
    }
    return best.max() ?? 0
}

func randomUniqueItems(alphabet: [String], using rng: inout SeededGenerator) -> [TestItem] {
    let count = Int.random(in: 0...alphabet.count, using: &rng)
    return alphabet.shuffled(using: &rng).prefix(count).map { TestItem(id: $0, value: Int.random(in: 0...1, using: &rng)) }
}

func randomItemsWithDuplicates(maxCount: Int, alphabetSize: Int, using rng: inout SeededGenerator) -> [TestItem] {
    (0..<Int.random(in: 0...maxCount, using: &rng)).map { _ in
        TestItem(id: String(Int.random(in: 0..<alphabetSize, using: &rng)), value: Int.random(in: 0...1, using: &rng))
    }
}

func mutate(_ old: [TestItem], using rng: inout SeededGenerator) -> [TestItem] {
    var result = old.filter { _ in Int.random(in: 0..<4, using: &rng) != 0 }
    result = result.map { Int.random(in: 0..<4, using: &rng) == 0 ? TestItem(id: $0.id, value: $0.value + 1) : $0 }
    if Bool.random(using: &rng) { result.shuffle(using: &rng) }
    for _ in 0..<Int.random(in: 0...3, using: &rng) {
        let fresh = TestItem(id: "new\(Int.random(in: 0..<1000, using: &rng))")
        guard !result.contains(where: { $0.id == fresh.id }) else { continue }
        result.insert(fresh, at: Int.random(in: 0...result.count, using: &rng))
    }
    return result
}

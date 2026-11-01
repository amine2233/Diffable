import Diffable

struct Row: Diffable {
    let id: String
    var value = 0
    var primaryKeyValue: String {
        id
    }
}

func rows(_ ids: String, value: Int = 0) -> [Row] {
    ids.map { Row(id: String($0), value: value) }
}

struct Seeded: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

func randomRows(maxCount: Int, using rng: inout Seeded) -> [Row] {
    let alphabet = (0 ..< maxCount).map(String.init)
    let count = Int.random(in: 0 ... maxCount, using: &rng)
    return alphabet.shuffled(using: &rng).prefix(count).map { Row(
        id: $0,
        value: Int.random(in: 0 ... 1, using: &rng)
    ) }
}

func mutated(_ old: [Row], using rng: inout Seeded) -> [Row] {
    var result = old.filter { _ in Int.random(in: 0 ..< 4, using: &rng) != 0 }
    result = result
        .map { Int.random(in: 0 ..< 4, using: &rng) == 0 ? Row(id: $0.id, value: $0.value + 1) : $0 }
    if Bool.random(using: &rng) { result.shuffle(using: &rng) }
    for _ in 0 ..< Int.random(in: 0 ... 3, using: &rng) {
        let fresh = Row(id: "new\(Int.random(in: 0 ..< 1_000, using: &rng))")
        guard !result.contains(where: { $0.id == fresh.id }) else { continue }

        result.insert(fresh, at: Int.random(in: 0 ... result.count, using: &rng))
    }
    return result
}

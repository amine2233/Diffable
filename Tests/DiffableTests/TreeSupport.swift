@testable import Diffable

struct Node: DiffableTree {
    let name: String
    var size = 0
    var children: [Node] = []

    var id: String {
        name
    }

    static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.name == rhs.name && lhs.size == rhs.size
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name); hasher.combine(size)
    }
}

func file(_ name: String, size: Int = 1) -> Node {
    Node(name: name, size: size)
}

func folder(_ name: String, _ children: Node...) -> Node {
    Node(name: name, children: children)
}

func flatten(_ nodes: [Node], prefix: [String] = []) -> [[String]: Int] {
    var result: [[String]: Int] = [:]
    for node in nodes {
        let path = prefix + [node.name]
        result[path] = node.size
        result.merge(flatten(node.children, prefix: path)) { first, _ in first }
    }
    return result
}

func flatten(_ changes: [TreeChange]) -> [(path: [String], kind: TreeChange.Kind)] {
    changes.flatMap { change in [(change.path.map(\.description), change.kind)] + flatten(change.children) }
}

func randomTree(depth: Int, using rng: inout SeededGenerator) -> [Node] {
    let names = ["a", "b", "c", "d", "e"].shuffled(using: &rng).prefix(Int.random(in: 0 ... 4, using: &rng))
    return names.map { name in
        Node(
            name: name,
            size: Int.random(in: 0 ... 1, using: &rng),
            children: depth > 0 ? randomTree(depth: depth - 1, using: &rng) : []
        )
    }
}

func mutateTree(_ nodes: [Node], depth: Int, shuffle: Bool, using rng: inout SeededGenerator) -> [Node] {
    var result: [Node] = []
    for node in nodes where Int.random(in: 0 ..< 5, using: &rng) != 0 {
        var copy = node
        if Int.random(in: 0 ..< 4, using: &rng) == 0 { copy.size += 1 }
        copy.children = mutateTree(node.children, depth: depth - 1, shuffle: shuffle, using: &rng)
        result.append(copy)
    }
    if Int.random(in: 0 ..< 3, using: &rng) == 0 {
        let fresh = Node(
            name: "n\(Int.random(in: 0 ..< 50, using: &rng))",
            size: 1,
            children: depth > 0 ? randomTree(depth: depth - 1, using: &rng) : []
        )
        if !result.contains(where: { $0.name == fresh.name }) { result.insert(
            fresh,
            at: Int.random(in: 0 ... result.count, using: &rng)
        ) }
    }
    if shuffle, Bool.random(using: &rng) { result.shuffle(using: &rng) }
    return result
}

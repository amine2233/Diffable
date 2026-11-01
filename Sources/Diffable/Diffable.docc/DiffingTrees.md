# Diffing trees

Compare a root and all of its children, for example a folder with sub folders and files.

## Overview

``DiffableTree`` adds `children` to ``Diffable/Diffable``. ``Swift/Array/treeDiff(_:algorithm:)`` compares the nodes of one level, then goes into every node that exists on both sides. The result is a tree of ``TreeChange`` values that points at exactly what changed, with its full path.

## Model your tree

```swift
struct Item: DiffableTree {
    let name: String
    var size = 0
    var children: [Item] = []

    var primaryKeyValue: String { name }

    static func == (lhs: Item, rhs: Item) -> Bool { lhs.name == rhs.name && lhs.size == rhs.size }
    func hash(into hasher: inout Hasher) { hasher.combine(name); hasher.combine(size) }
}
```

> Important: `==` and `hash(into:)` must compare the node's **own** properties only, not `children`. Children are compared by recursion. If they were part of `==`, every parent of a change would be reported as updated.

The children may be of another type than the node. A section can hold rows, for example: the `Child` type is inferred from your `children` property, and a leaf type returns an empty array of itself.

## Compare two roots

```swift
let before = Item(name: "MyApp", children: [
    Item(name: "Sources", children: [
        Item(name: "main.swift", size: 10),
        Item(name: "util.swift", size: 5)
    ]),
    Item(name: "Docs", children: [Item(name: "README.md")])
])

let after = Item(name: "MyApp", children: [
    Item(name: "Sources", children: [
        Item(name: "main.swift", size: 12),
        Item(name: "util.swift", size: 5),
        Item(name: "new.swift")
    ])
])

let changes = before.treeDiff(to: after)
print(changes.map(\.description).joined(separator: "\n"))
```

```
= MyApp
  - Docs
  = Sources
    ~ main.swift
    + new.swift
```

`=` is an unchanged node that has changes below it, `~` an update, `+` an insert and `-` a delete. A moved node adds `(moved from n)`.

To compare lists of siblings, call ``Swift/Array/treeDiff(_:algorithm:)`` on the array:

```swift
let changes = oldItems.treeDiff(newItems, algorithm: .myers)
```

## Read a TreeChange

```swift
for change in changes {
    change.key        // "MyApp"
    change.path       // ["MyApp"]
    change.kind       // .unchanged, .update, .insert or .delete
    change.index      // position among its siblings (OLD for .delete, NEW otherwise)
    change.oldIndex   // position among the OLD siblings, nil for an insert
    change.movedFrom  // OLD position if the node changed position
    change.children   // the changes below this node
}
```

Find a changed file by walking the tree:

```swift
func updatedPaths(_ changes: [TreeChange]) -> [[String]] {
    changes.flatMap { change in
        (change.kind == .update ? [change.path] : []) + updatedPaths(change.children)
    }
}
// [["MyApp", "Sources", "main.swift"]]
```

## Rules to know

- Identity is the whole path, so `README.md` in two folders never collide.
- An inserted or deleted folder is **one** entry. Its files are not listed.
- A node moved to another parent is a delete plus an insert. Moves are only reported among siblings.
- Siblings must have unique `primaryKeyValue`s.
- The comparison recurses once per level. Keep trees under about 150 levels deep.
- The ``DiffAlgorithm`` is used at every level. With `.myers` there is never a `movedFrom`.

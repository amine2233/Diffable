# Diffable

Diff two arrays, or two trees such as a folder with sub folders and files, and get back exactly what was
**inserted, deleted, updated or moved**.

- **Heckel** (default): linear time, detects moves.
- **Myers**: always the shortest edit script, no moves.
- **Tree diff**: compares a root and its children recursively and reports the change as a tree with full paths.
- **DiffableUI**: `IndexPath` results and a `UICollectionView` helper, in a separate product.

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/amine2233/Diffable.git", from: "1.0.0")
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Diffable", package: "Diffable"),
    .product(name: "DiffableUI", package: "Diffable")   // optional, UIKit helpers
])
```

### CocoaPods

```ruby
pod 'Diffable'            # Core + UI
pod 'Diffable/Core'       # algorithms and tree diff only
```

## Concepts

Two things drive every diff:

```
              IDENTITY                            CONTENT
        "is it the same item?"             "did the item change?"
        ----------------------             ----------------------
        primaryKeyValue                    Hashable (== / hash)

  old: [ A(id 1, "x") ]                same identity, other content  ==>  UPDATE
  new: [ A(id 1, "y") ]

  old: [ A(id 1) ]                     identity only in old  ==>  DELETE
  new: [ A(id 2) ]                     identity only in new  ==>  INSERT
```

```swift
struct Product: Diffable {
    let sku: String
    var quantity: Int
    var primaryKeyValue: String { sku }
}
```

## Diff an array

```swift
let before = [Product(sku: "shoes", quantity: 1), Product(sku: "hat", quantity: 2), Product(sku: "bag", quantity: 1)]
let after  = [Product(sku: "shoes", quantity: 3), Product(sku: "bag", quantity: 1), Product(sku: "belt", quantity: 1)]

let changes = before.diff(after)                      // Heckel
let shortest = before.diff(after, algorithm: .myers)  // Myers

changes.updates     // [0]   shoes quantity changed        (index in NEW)
changes.deletions   // [1]   hat removed                   (index in OLD)
changes.insertions  // [2]   belt added                    (index in NEW)
changes.moves       // []    (from OLD, to NEW)
```

### Heckel or Myers?

| | `.heckel` (default) | `.myers` |
|---|---|---|
| Time | O(n) | O((N+M)·D), D = number of edits |
| Moves | yes, minimal | no (a move is delete + insert) |
| Shortest script | not guaranteed | always |
| Best for | UI lists, reordering | small edits on big lists, readable minimal diffs |

```
 old: [ A B C D ]  ->  new: [ B C D A ]

 Heckel: moves = [(0 -> 3)]                    1 operation
 Myers:  deletions = [0], insertions = [3]     2 operations
```

## Diff a tree (root, folders and files)

Conform to `DiffableTree` and expose `children`.
`==` and `hash` must compare the node's **own** properties only, not `children`.

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

```swift
let changes = oldRoot.treeDiff(to: newRoot)     // or [Item].treeDiff([Item])
print(changes.map(\.description).joined(separator: "\n"))
```

```
old                              new                           result
MyApp                            MyApp                         = MyApp
├── Sources                      └── Sources                     - Docs
│   ├── main.swift (10)              ├── main.swift (12)         = Sources
│   └── util.swift (5)               ├── util.swift (5)             ~ main.swift
└── Docs                             └── new.swift                  + new.swift
    └── README.md
```

`=` unchanged container, `~` update, `+` insert, `-` delete. A moved node adds `(moved from n)`.

- A `TreeChange` has `key`, `path` (`["MyApp", "Sources", "main.swift"]`), `kind`, `index`, `movedFrom` and `children`.
- Identity is the whole path, so `README.md` in two folders never collide.
- An inserted or deleted folder is **one** entry, its files are not repeated.
- A node moved to another parent is a delete plus an insert.
- Siblings must have unique `primaryKeyValue`s.
- Recursion is one stack frame set per level: keep trees well under ~150 levels deep.

## UIKit

```swift
import DiffableUI

let changes: (updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(IndexPath, IndexPath)])
    = old.diff(new, forSection: 0)

collectionView.apply({ dataSource = new },
                     updates: changes.updates,
                     insertions: changes.insertions,
                     deletions: changes.deletions,
                     moves: changes.moves)
```

Index spaces (same everywhere): **deletions** and the `from` of a move refer to the OLD array, everything else
to the NEW array.

## Heterogeneous lists

`AnyDiffable` wraps any `Diffable`. The wrapped type is part of the identity, so `Article(42)` and `Video(42)`
are never confused.

```swift
let feed: [AnyDiffable] = [AnyDiffable(article), AnyDiffable(video)]
```

## Requirements

Swift 5.4+, iOS 12, macOS 10.14, tvOS 12, watchOS 5 (podspec). The Swift Testing suites need a recent Xcode toolchain.

## Tests

```bash
swift test
```

Besides hand-written cases, the suite replays every produced diff on the old array and checks it rebuilds the new
one, over thousands of seeded random inputs.

## License

MIT, see [LICENSE](LICENSE).

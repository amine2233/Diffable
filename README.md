# Diffable

Diff two arrays, or two trees such as a folder with sub folders and files, and get back exactly what was
**inserted, deleted, updated or moved**.

- **Heckel** (default): linear time, detects moves.
- **Myers**: always the shortest edit script, no moves.
- **Tree diff**: compares a root and its children recursively and reports the change as a tree with full paths.
- **DiffableUI**: animated updates for `UICollectionView`, `UITableView`, `NSCollectionView`, `NSTableView`, `NSOutlineView`, stack views, menus, `MKMapView` and diffable data sources, in a separate product.

## Installation

```swift
.package(url: "https://github.com/amine2233/Diffable.git", from: "1.0.0")
```

```swift
.target(name: "App", dependencies: [
    .product(name: "Diffable", package: "Diffable"),
    .product(name: "DiffableUI", package: "Diffable")   // optional, UIKit / AppKit / MapKit helpers
])
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

## Views (DiffableUI)

`import DiffableUI` adds one-line diff animations to the views below. All of them take `old` and `new` models,
compute the diff (Heckel by default, `algorithm: .myers` to switch) and apply it with the calls the view expects.

| View | Platform | API |
|---|---|---|
| `UICollectionView` | iOS, tvOS | `applyDiff(from:to:)`, `applyDiff(fromSections:toSections:)` |
| `UITableView` | iOS, tvOS | same, plus `animations:` per change kind |
| `UIStackView` | iOS, tvOS | `applyDiff(from:to:makeView:update:)` |
| `UIMenu` | iOS | `replacingChildren(from:to:make:)` keeps the untouched `UIMenuElement`s |
| `NSCollectionView` | macOS | `applyDiff(from:to:)`, `applyDiff(fromSections:toSections:)` |
| `NSTableView` | macOS | `applyDiff(from:to:)` |
| `NSOutlineView` | macOS | `applyDiff(from:to:item:updateData:)` for trees (folders and files) |
| `NSStackView` | macOS | `applyDiff(from:to:makeView:update:)` |
| `NSMenu` | macOS | `applyDiff(from:to:makeItem:update:)` |
| `MKMapView` | iOS, macOS, tvOS | `syncAnnotations(from:to:update:)`, pins that did not change do not flicker |
| `NSDiffableDataSourceSnapshot` | iOS 13, macOS 10.15 | `init(sections:)` and `init(from:to:)` which marks edited items for refresh |
| `NSDiffableDataSourceSectionSnapshot` | iOS 14 | `init(roots:expanded:)`: an expandable outline of a tree |

```swift
import DiffableUI

// One section
collectionView.applyDiff(from: items, to: newItems) { items = newItems }
tableView.applyDiff(from: rows, to: newRows, animations: .init(insert: .fade, delete: .left)) { rows = newRows }

// Several sections: a section is a DiffableTree whose children are its items
collectionView.applyDiff(fromSections: sections, toSections: newSections) { sections = newSections }

// A tree in an outline view; `item` returns the object your data source uses for a path
outlineView.applyDiff(from: oldRoots, to: newRoots, item: { Box($0) }) { roots = newRoots }
```

Your data source must hold the **new** data once `updateData` has run.

### Why two batches

UIKit and `NSCollectionView` read deletions as OLD indexes and insertions as NEW ones, but a reload needs OLD
indexes while our updates are NEW ones. So structure changes run in a first batch and reloads in a second one.
`NSTableView`, `NSOutlineView`, `NSMenu` and the stack views are *sequential* (each call is relative to the
previous one), so the changes first go through `SequentialPlan`.

```
SIMULTANEOUS (UIKit, NSCollectionView)        SEQUENTIAL (NSTableView, NSOutlineView, NSMenu, stacks)
 batch 1: delete(old) insert(new) move(old->new)   remove(high -> low), then for each NEW index:
 batch 2: reload(new)                               insert(i) or move(current -> i)
```

### Sections

A moved or reloaded section cannot also have item edits in the same batch (UIKit and AppKit reject it), so
`SectionedChanges` reports such a section as a delete plus an insert. An item moved to another section is a
delete plus an insert as well.

### Lower level

```swift
let changes = old.listChanges(to: new)                      // ListChanges: plain Int indexes
let paths   = changes.indexPaths(section: 0)                // IndexPaths
let plan    = SequentialPlan(changes: changes, oldCount: old.count, newCount: new.count)
let tuple: (updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(IndexPath, IndexPath)])
    = old.diff(new, forSection: 0)                          // original API, still available
```

## Heterogeneous lists

`AnyDiffable` wraps any `Diffable`. The wrapped type is part of the identity, so `Article(42)` and `Video(42)`
are never confused.

```swift
let feed: [AnyDiffable] = [AnyDiffable(article), AnyDiffable(video)]
```

## Requirements

Swift 5.4+ (SwiftPM only). The Swift Testing suites need a recent Xcode toolchain. `UIMenu` is iOS only; the diffable data source bridges need iOS 13 / macOS 10.15.

## Tests

```bash
swift test
```

Besides hand-written cases, the suite replays every produced diff on the old array and checks it rebuilds the new
one, over thousands of seeded random inputs.

## License

MIT, see [LICENSE](LICENSE).

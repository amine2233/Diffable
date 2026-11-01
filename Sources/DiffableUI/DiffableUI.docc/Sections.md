# Lists with several sections

Diff a list of sections that each hold items.

## Model sections as a tree

A section is a `DiffableTree` whose children are its items. Its `==` compares the section itself (a title or header), not its items:

```swift
struct Row: DiffableTree {
    let id: Int
    var text: String
    var primaryKeyValue: String { String(id) }
    var children: [Row] { [] }
}

struct Section: DiffableTree {
    let title: String
    var header = 0
    var children: [Row] = []

    var primaryKeyValue: String { title }

    static func == (lhs: Section, rhs: Section) -> Bool { lhs.title == rhs.title && lhs.header == rhs.header }
    func hash(into hasher: inout Hasher) { hasher.combine(title); hasher.combine(header) }
}
```

## Apply the difference

```swift
collectionView.applyDiff(fromSections: sections, toSections: newSections) {
    self.sections = newSections
}
```

`UITableView` and `NSCollectionView` have the same call.

## What is reported

``SectionedChanges`` lists section changes and item changes separately:

```swift
let changes = sections.sectionedChanges(to: newSections)

changes.sectionDeletions   // OLD section indexes
changes.sectionInsertions  // NEW section indexes
changes.sectionMoves       // from OLD to NEW
changes.sectionUpdates     // NEW section indexes (reload the header)

changes.itemDeletions      // [ItemPosition] in OLD section, OLD item
changes.itemInsertions     // [ItemPosition] in NEW section, NEW item
changes.itemUpdates        // [ItemPosition] in NEW section, NEW item
changes.itemMoves          // from an OLD position to a NEW position
```

```
 old                  new
 S0 [a b]             S0 [a]            item    delete    (0,1)       OLD section, OLD item
 S1 [c]               S2 [e f]          section insert    1           NEW index
 S2 [d]               S1 [c]            section move      1 -> 2      OLD -> NEW
```

## The moved-section rule

UIKit and AppKit refuse to insert, delete or move items inside a section that is itself being moved or reloaded in the same batch. So a section that moved or was updated **and** has item changes is reported as a section delete plus a section insert, and its items come from the data source as a whole:

| Section | Items | Reported as |
|---|---|---|
| moved | unchanged | `sectionMoves` |
| updated | unchanged | `sectionUpdates` |
| moved or updated | changed | `sectionDeletions` + `sectionInsertions` |
| unchanged | changed | item changes |

An item that moves to another section is a delete plus an insert.

Only two levels are read: changes below the items are ignored.

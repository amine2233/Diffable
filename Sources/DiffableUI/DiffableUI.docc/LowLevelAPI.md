# Building your own adapter

Use the building blocks directly when your view is not covered.

## ListChanges: a diff as plain integers

``ListChanges`` is the result of diffing two flat lists, with no view involved. Every adapter is built on it.

```swift
let changes = old.listChanges(to: new)                  // heckel by default
let shortest = old.listChanges(to: new, algorithm: .myers)

changes.deletions    // OLD indexes
changes.insertions   // NEW indexes
changes.updates      // NEW indexes
changes.moves        // [(from: OLD, to: NEW)]
changes.isEmpty
```

```
 old: [ A  B  C ]                         new: [ B  C' D ]
        0  1  2                                  0  1  2

 deletions  [0]       OLD         insertions [2]       NEW
 updates    [1]       NEW         moves      []        OLD -> NEW
```

Convenience conversions:

```swift
changes.deletionIndexes     // IndexSet
changes.insertionIndexes    // IndexSet
changes.updateIndexes       // IndexSet
changes.indexPaths(section: 0)   // IndexPaths on UIKit and AppKit
```

A level of a tree diff converts too:

```swift
let level = ListChanges(siblings: oldNodes.treeDiff(newNodes))
```

## SequentialPlan: ordered operations

For APIs where each call is relative to the previous one. See <doc:SequentialViews>.

```swift
let plan = SequentialPlan(changes: changes, oldCount: old.count, newCount: new.count)
plan.operations   // [.remove(2), .remove(0), .move(from: 1, to: 0), .insert(2)]
```

## SectionedChanges: sections and items

For several sections. See <doc:Sections>.

```swift
let sectioned = sections.sectionedChanges(to: newSections)
sectioned.itemInsertions.map(\.indexPath)   // IndexPaths on UIKit and AppKit
```

``ItemPosition`` is a `(section, item)` pair.

## The original tuple API

The first version of the library returned `IndexPath`s directly. It still works:

```swift
let changes: (updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(IndexPath, IndexPath)])
    = old.diff(new, forSection: 1)
```

## Write an adapter for another view

Follow the contract of the view:

1. Run `updateData` so your data source holds the new data.
2. For a simultaneous API, call deletes with OLD indexes and inserts with NEW ones, then reload updates in a second step.
3. For a sequential API, run `SequentialPlan.perform(remove:insert:move:)` and reload updates at the end.

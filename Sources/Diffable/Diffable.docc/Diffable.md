# ``Diffable``

Find out what was inserted, deleted, updated or moved between two arrays, or between two trees such as a folder with sub folders and files.

## Overview

Describe your model once, and get the differences back as plain indexes (for arrays) or as a tree of changes (for trees).

```swift
import Diffable

struct Product: Diffable {
    let sku: String
    var quantity: Int
    var primaryKeyValue: String { sku }
}

let changes = before.diff(after)
changes.deletions   // OLD indexes
changes.insertions  // NEW indexes
changes.updates     // NEW indexes
changes.moves       // from OLD to NEW
```

Two algorithms are available: Paul Heckel's linear algorithm (the default, it detects moves) and Eugene Myers' shortest-edit-script algorithm.

To animate the result in a `UICollectionView`, `NSTableView`, `NSOutlineView` and more, add the `DiffableUI` product.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:ReadingTheResult>
- <doc:ChoosingAnAlgorithm>

### Describing your data

- ``Diffable/Diffable``
- ``AnyDiffable``
- <doc:HeterogeneousLists>

### Choosing how to compare

- ``DiffAlgorithm``

### Comparing trees

- <doc:DiffingTrees>
- ``DiffableTree``
- ``TreeChange``

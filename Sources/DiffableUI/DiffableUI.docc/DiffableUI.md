# ``DiffableUI``

Animate the difference between two arrays, or two trees, in `UICollectionView`, `UITableView`, `NSTableView`, `NSCollectionView`, `NSOutlineView`, stack views, menus, map views and diffable data sources.

## Overview

`DiffableUI` builds on the `Diffable` module. Give a view the old and the new models and it computes the diff and applies it with the exact calls that view expects.

```swift
import DiffableUI

collectionView.applyDiff(from: items, to: newItems) {
    items = newItems
}
```

Your data source must hold the **new** data once the `updateData` closure has run. View adapters run on the main actor, while the diff values (``ListChanges`` and friends) are `Sendable` and can be computed anywhere: see <doc:Concurrency>.

| View | Platform | Entry point |
|---|---|---|
| `UICollectionView` | iOS, tvOS | `applyDiff(from:to:)`, `applyDiff(fromSections:toSections:)` |
| `UITableView` | iOS, tvOS | the same, plus an animation per kind of change |
| `UIStackView` | iOS, tvOS | `applyDiff(from:to:makeView:update:)` |
| `UIMenu` | iOS | `replacingChildren(from:to:make:)` |
| `NSCollectionView` | macOS | `applyDiff(from:to:)`, `applyDiff(fromSections:toSections:)` |
| `NSTableView` | macOS | `applyDiff(from:to:)` |
| `NSOutlineView` | macOS | `applyDiff(from:to:item:updateData:)` |
| `NSStackView` | macOS | `applyDiff(from:to:makeView:update:)` |
| `NSMenu` | macOS | `applyDiff(from:to:makeItem:update:)` |
| `MKMapView` | iOS, macOS, tvOS | `syncAnnotations(from:to:update:)` |
| `NSDiffableDataSourceSnapshot` | iOS 13, macOS 10.15.1 | `init(sections:)`, `init(from:to:)` |
| `NSDiffableDataSourceSectionSnapshot` | iOS 14 | `init(roots:expanded:)` |

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Sections>
- <doc:SequentialViews>
- <doc:Concurrency>

### Trees and outlines

- <doc:TreesAndOutlines>
- ``TreePath``

### Diffable data sources

- <doc:DiffableDataSources>
- ``SnapshotItemID``

### Map annotations

- <doc:MapAnnotations>
- ``DiffableAnnotation``

### Building your own adapter

- <doc:LowLevelAPI>
- ``ListChanges``
- ``SequentialPlan``
- ``SectionedChanges``
- ``ItemPosition``

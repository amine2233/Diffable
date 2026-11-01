# Folders, files and outlines

Show a tree in an outline view and animate how it changes.

## NSOutlineView

`NSOutlineView.applyDiff(from:to:item:updateData:)` diffs the tree level by level and applies each level with the sequential calls the outline view expects: `removeItems`, `insertItems`, `moveItem` and `reloadItem`. Only the levels that changed are touched.

```swift
outlineView.applyDiff(
    from: oldRoots,
    to: newRoots,
    item: { path in PathBox(path) },
    updateData: { self.roots = newRoots }
)
```

```
 old                     new                      calls
 root                    root
 ├── src                 ├── src                  src : reloadItem
 │   └── a.swift (1)     │   ├── a.swift (2)      a.swift : reloadItem
 │                       │   └── b.swift          insertItems(at: 1, inParent: src)
 └── docs                └── (removed)            removeItems(at: 1, inParent: root)
```

The `item` closure returns the object your data source uses as the outline item for a ``TreePath``. It is only called for parents that exist in both trees, and must return the same object your `outlineView(_:child:ofItem:)` hands out for that path. Using the path itself as identity is the simplest way:

```swift
final class PathBox: NSObject {
    let path: TreePath
    init(_ path: TreePath) { self.path = path }

    override func isEqual(_ object: Any?) -> Bool { (object as? PathBox)?.path == path }
    override var hash: Int { path.hashValue }
}
```

## Identify a node: TreePath

A ``TreePath`` is the list of keys from the root to a node, so two files with the same name in different folders have different paths:

```swift
let path = TreePath(["MyApp", "Sources", "main.swift"])
path.description  // "MyApp/Sources/main.swift"
path.parent       // TreePath(["MyApp", "Sources"])
```

## An expandable outline in a UICollectionView (iOS 14)

`NSDiffableDataSourceSectionSnapshot<TreePath>` builds the outline for you:

```swift
let snapshot = NSDiffableDataSourceSectionSnapshot<TreePath>(
    roots: roots,
    expanded: [TreePath(["MyApp"])]
)
dataSource.apply(snapshot, to: 0, animatingDifferences: true)
```

Everything not listed in `expanded` starts collapsed. A diffable data source only compares identifiers, so nodes that kept their path but changed content are not redrawn by themselves. Ask for them with `updatedPaths(to:)` and refresh them:

```swift
let changed = oldRoots.updatedPaths(to: newRoots)
var current = dataSource.snapshot()
current.reconfigureItems(changed)
dataSource.apply(current)
```

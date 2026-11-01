# Diffable data sources

Build `NSDiffableDataSourceSnapshot` values from your sections and refresh the items whose content changed.

## A snapshot of sections

A section is a `DiffableTree` whose children are its items (see <doc:Sections>). The snapshot uses the section's `id` as the section identifier, wrapped in a `DiffID`, and a ``SnapshotItemID`` as the item identifier:

```swift
let snapshot = NSDiffableDataSourceSnapshot<DiffID, SnapshotItemID>(sections: sections)
dataSource.apply(snapshot)
```

Diffable data sources need item identifiers that are unique across all sections, so the section is part of the identity:

```
 section "Inbox" / item "42"   SnapshotItemID(section: "Inbox", item: "42")
 section "Sent"  / item "42"   SnapshotItemID(section: "Sent",  item: "42")     different
```

## Refresh edited items

A diffable data source only compares identifiers, so an item whose identity is unchanged but whose content changed would never be redrawn. Build the new snapshot from the old and the new sections and it marks those items for you:

```swift
let snapshot = NSDiffableDataSourceSnapshot<DiffID, SnapshotItemID>(from: sections, to: newSections)
dataSource.apply(snapshot)
self.sections = newSections
```

```
 old: Inbox [1 2]        new: Inbox' [1 2']
                              Inbox' header changed  -> reloadSections(["Inbox"])
                              item 2 content changed -> reconfigureItems([(Inbox,2)])
```

`reconfigureItems` is used on UIKit from iOS 15, and `reloadItems` elsewhere.

## Deployment targets

`NSDiffableDataSourceSnapshot` exists from iOS 13 and macOS 10.15.1. The rest of `DiffableUI` builds for older systems, so an app that targets macOS 10.15 guards the call:

```swift
if #available(macOS 10.15.1, iOS 13.0, *) {
    let snapshot = NSDiffableDataSourceSnapshot<DiffID, SnapshotItemID>(from: old, to: new)
    dataSource.apply(snapshot)
} else {
    tableView.applyDiff(from: oldRows, to: newRows) { rows = newRows }
}
```

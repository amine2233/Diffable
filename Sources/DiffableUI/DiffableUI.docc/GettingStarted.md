# Getting started

Animate a change in a list view with one call.

## Make your model diffable

Models conform to `Diffable`: a stable `primaryKeyValue` is the identity, and `==` says whether the content changed.

```swift
import Diffable
import DiffableUI

struct Message: Diffable {
    let id: Int
    var text: String
    var primaryKeyValue: String { String(id) }
}
```

## A collection view

```swift
var messages: [Message] = []

func show(_ newMessages: [Message]) {
    collectionView.applyDiff(from: messages, to: newMessages) {
        self.messages = newMessages
    }
}
```

- The closure runs inside the batch update, before any row is touched. Replace your data source's content there.
- Deleted items are animated out, inserted ones in, moved ones travel, and items whose content changed are reloaded.
- `completion:` is called when the animations are done.

## A table view

`UITableView` takes the same call and lets you choose the animation of each kind of change:

```swift
tableView.applyDiff(
    from: messages,
    to: newMessages,
    animations: .init(insert: .fade, delete: .left, reload: .none)
) {
    self.messages = newMessages
}
```

On macOS, `NSTableView` is the same call with `NSTableView.DiffAnimations`:

```swift
tableView.applyDiff(from: messages, to: newMessages, animations: .init(insert: .slideDown, remove: .effectFade)) {
    self.messages = newMessages
}
```

## Choose the algorithm

Every call accepts `algorithm: .heckel` (default, detects moves) or `algorithm: .myers` (shortest list of edits, no moves):

```swift
collectionView.applyDiff(from: messages, to: newMessages, algorithm: .myers) { messages = newMessages }
```

## Why updates run in a second batch

UIKit and `NSCollectionView` read deletions as OLD indexes and insertions as NEW ones, but a reload needs OLD indexes while the diff reports updates with NEW ones. So structure changes run in a first batch and reloads in a second one, once the new layout exists.

```
 batch 1 (old -> new layout)               batch 2 (new layout)
 ---------------------------               --------------------
 updateData()                              reloadItems(updates)
 deleteItems(deletions)       [old idx]
 insertItems(insertions)      [new idx]
 moveItem(from old, to new)
```

## Next

- <doc:Sections> for lists with several sections.
- <doc:SequentialViews> for table views, stack views and menus.
- <doc:TreesAndOutlines> for folders and files.

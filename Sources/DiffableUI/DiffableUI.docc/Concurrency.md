# Concurrency

Compute a diff on any thread, apply it on the main actor.

## Overview

`DiffableUI` is built in the Swift 6 language mode and splits its API in two:

| Part | Isolation | Why |
|---|---|---|
| ``ListChanges``, ``SectionedChanges``, ``SequentialPlan``, ``TreePath``, ``ItemPosition``, ``SnapshotItemID`` | none, all `Sendable` | Pure values. Compute them and pass them between tasks freely. |
| Snapshot builders (`NSDiffableDataSourceSnapshot(sections:)`, `updatedPaths(to:)`) | none | Pure computation, safe on a background task. |
| Every view adapter (`applyDiff`, `apply`, `syncAnnotations`, `replacingChildren`...) | `@MainActor` | They touch views. |

The closures you pass to a view adapter (`updateData`, `completion`, `makeView`, `update`, `makeItem`, `item`, `make`) are `@MainActor` too, so they can read and write your view model and the views directly, without `DispatchQueue.main` or `MainActor.assumeIsolated`.

## Diff off the main thread

The core algorithms are synchronous and keep no shared state, so a large diff can run in a detached task. The models must be `Sendable` for that, because they cross into the task; `Diffable` does not require it.

```swift
struct Message: Diffable, Sendable {
    let id: Int
    var text: String
    var primaryKeyValue: String { String(id) }
}

@MainActor
final class Inbox {
    var messages: [Message] = []

    func refresh(with newMessages: [Message]) async {
        let old = messages

        let changes = await Task.detached {
            old.listChanges(to: newMessages)          // ListChanges is Sendable
        }.value

        collectionView.apply(changes) {               // back on the main actor
            self.messages = newMessages
        }
    }
}
```

The same split works for sections (`sectionedChanges(to:)` then `apply(_:updateData:)`) and for tables (`SequentialPlan` is `Sendable`).

## When the diff is small

For lists of a few hundred items the diff takes microseconds. Calling `applyDiff(from:to:)` directly on the main actor is simpler, and it does not need `Sendable` models:

```swift
collectionView.applyDiff(from: messages, to: newMessages) {
    self.messages = newMessages
}
```

## Models that are not Sendable

`Diffable` only requires `Hashable`. Classes such as `NSObject`-based map annotations are fine: diff them on the main actor with `syncAnnotations(from:to:update:)`.

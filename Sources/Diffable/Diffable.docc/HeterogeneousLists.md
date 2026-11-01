# Mixing several types in one list

Put articles, videos and ads in the same array with ``AnyDiffable``.

## Overview

``AnyDiffable`` wraps any ``Diffable/Diffable`` type, so one array can hold values of different types:

```swift
struct Article: Diffable { let id: Int; var title: String }
struct Video: Diffable { let id: Int }

let feed: [AnyDiffable] = [
    AnyDiffable(Article(id: 1, title: "Hello")),
    AnyDiffable(Video(id: 1))
]
```

## The type is part of the identity

`Article` 1 and `Video` 1 have the same `id`, but they are not the same item. The ``AnyDiffable`` id combines the wrapped type and the wrapped id (as a ``DiffID``), so they are never confused:

```swift
let old: [AnyDiffable] = [AnyDiffable(Article(id: 1, title: "a"))]
let new: [AnyDiffable] = [AnyDiffable(Video(id: 1))]

let changes = old.diff(new)
changes.deletions   // [0]
changes.insertions  // [0]
changes.updates     // []     a different type is never an update
```

Two wrapped values are equal only when they have the same type and equal content:

```swift
AnyDiffable(Article(id: 1, title: "a")) == AnyDiffable(Article(id: 1, title: "a"))  // true
AnyDiffable(Article(id: 1, title: "a")) == AnyDiffable(Video(id: 1))                // false
```

## Transform a wrapped value

``AnyDiffable/map(_:)`` changes a value only when it has the requested type, and returns the same wrapper otherwise:

```swift
let edited = feed.map { item in
    item.map { (article: Article) in Article(id: article.id, title: "Edited") }
}
// articles are replaced, videos are left as they are
```

``AnyDiffable/flatMap(_:)`` does the same with a closure that returns an `AnyDiffable`.

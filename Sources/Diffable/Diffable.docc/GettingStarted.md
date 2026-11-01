# Getting started

Make a type diffable, then compare two arrays of it.

## Identity and content

Two things drive every diff, and they come from two different places:

```
              IDENTITY                            CONTENT
        "is it the same item?"             "did the item change?"
        ----------------------             ----------------------
        Identifiable.id                    Hashable (== / hash)

  old: [ A(id 1, "x") ]                same identity, other content  ==>  UPDATE
  new: [ A(id 1, "y") ]

  old: [ A(id 1) ]                     identity only in old  ==>  DELETE
  new: [ A(id 2) ]                     identity only in new  ==>  INSERT
```

- `id` (from `Identifiable`) must be stable and unique among siblings: a database id, a UUID, a SKU, a file name. Any `Hashable` and `Sendable` type works.
- `==` decides whether an item with the same identity changed. Compare the properties you want to detect changes on.

## Conform to Diffable

```swift
import Diffable

struct Product: Diffable {
    let sku: String
    var quantity: Int

    var id: String { sku }
}
```

`Diffable` refines `Hashable` and `Identifiable`, so a struct of `Hashable` properties with an `id` needs nothing else. A model that already is `Identifiable` (for SwiftUI, for example) only has to add `Diffable`.

## Compare two arrays

```swift
let before = [
    Product(sku: "shoes", quantity: 1),
    Product(sku: "hat", quantity: 2),
    Product(sku: "bag", quantity: 1)
]
let after = [
    Product(sku: "shoes", quantity: 3),
    Product(sku: "bag", quantity: 1),
    Product(sku: "belt", quantity: 1)
]

let changes = before.diff(after)

changes.updates     // [0]  shoes: quantity changed
changes.deletions   // [1]  hat: removed
changes.insertions  // [2]  belt: added
changes.moves       // []
```

`diff(_:)` uses Heckel's algorithm. Pass an ``DiffAlgorithm`` to choose another one:

```swift
let shortest = before.diff(after, algorithm: .myers)
```

## What next

- <doc:ReadingTheResult> explains the two index spaces.
- <doc:ChoosingAnAlgorithm> compares Heckel and Myers.
- <doc:DiffingTrees> compares nested data such as folders.
- <doc:HeterogeneousLists> mixes several types in one list.

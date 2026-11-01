# Sets, dictionaries and other collections

Diff a `Set`, a `Dictionary`, or any random-access collection, not only an `Array`.

## Any random-access collection

`diff(_:)`, `diff(_:algorithm:)` and `treeDiff(_:algorithm:)` are available on every `RandomAccessCollection` of `Diffable` elements: `Array`, `ArraySlice`, `ContiguousArray`, a `Range`, or your own collection type. The two sides can even be different types:

```swift
let old = ContiguousArray(products)
let new = products[2...]                        // an ArraySlice

let changes = old.diff(new)                     // same tuple as Array.diff
let shortest = old.diff(new, algorithm: .myers)
```

All indexes in the result are **offsets from the start** of their collection, never raw collection indexes. This matters for a slice whose `startIndex` is not 0:

```
 old: ArraySlice [ B  C  D ]  (startIndex 1)         new: ContiguousArray [ C  D  E ]
                   0  1  2    offsets                                      0  1  2

 deletions  -> [0]     B is gone          insertions -> [2]     E is new
```

The elements are copied into arrays first. That is O(n), the same order as the diff itself.

`DiffableUI` follows the same rule: `listChanges(to:)` and `sectionedChanges(to:)` accept any random-access collection.

## Sets

A `Set` has no order, so a set diff has no indexes and no moves. ``SetChanges`` lists the elements inserted and deleted:

```swift
let changes = Set([1, 2, 3]).diff(Set([2, 3, 4]))

changes.deletions   // [1]
changes.insertions  // [4]
changes.updates     // []
```

For `Diffable` elements, an edited element is not equal to its old version, so a set holds both and the plain set difference sees a deletion plus an insertion. Because the elements are `Identifiable`, `diff` pairs them by `id` into an update:

```swift
let old: Set<Product> = [Product(id: "shoes", quantity: 1), Product(id: "hat", quantity: 2)]
let new: Set<Product> = [Product(id: "shoes", quantity: 3), Product(id: "bag", quantity: 1)]

let changes = old.diff(new)
changes.updates     // [shoes: quantity 1 -> 3]    (SetChanges.Update has old and new)
changes.deletions   // [hat]
changes.insertions  // [bag]
```

```
 old: { A, B, C }                 new: { B, C', D }          C' = C with other content, same id

 deletions   { A }                in old, not in new
 insertions  { D }                in new, not in old
 updates     [ C -> C' ]          same id in both, other content   (Diffable elements only)
 B is unchanged and appears nowhere
```

Keep ids unique in each set. If two elements share an id, they are paired in no particular order.

Applying a result always gives the new set: remove `deletions` and every `updates.old`, then add `insertions` and every `updates.new`.

## Dictionaries

Keys are the identity and values are the content. ``DictionaryChanges`` needs `Value: Equatable`:

```swift
let old = ["a": 1, "b": 2, "c": 3]
let new = ["b": 2, "c": 30, "d": 4]

let changes = old.diff(new)
changes.deletions   // ["a": 1]                           key only in old, with its old value
changes.insertions  // ["d": 4]                           key only in new
changes.updates     // ["c": Update(old: 3, new: 30)]     same key, other value
```

To apply it to `old`:

```swift
var result = old
for key in changes.deletions.keys { result[key] = nil }
for (key, update) in changes.updates { result[key] = update.new }
for (key, value) in changes.insertions { result[key] = value }
// result == new
```

A key whose value is `nil` in a `[String: Int?]` is a real entry, not a missing key.

## Concurrency

``SetChanges`` and ``DictionaryChanges`` are `Sendable` when their elements are, so a large diff can run in a detached task and be returned to the caller:

```swift
let changes = await Task.detached { old.diff(new) }.value
```

## Keeping the order: use an array

Sets and dictionaries cannot tell you that something moved. If the order matters, for a list on screen, keep an array and use ``Swift/Array/diff(_:)``, which also finds moves.

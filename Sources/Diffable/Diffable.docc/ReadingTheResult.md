# Reading the result

Know which array each index refers to.

## Overview

`diff(_:)` returns four lists. They do not all use the same array:

```
   old: [ A  B  C ]                         new: [ B  C' D ]
          0  1  2                                  0  1  2

   deletions  [0]       index in the OLD array     (A is gone)
   moves      []        from OLD  ->  to NEW
   insertions [2]       index in the NEW array     (D is new)
   updates    [1]       index in the NEW array     (C changed content)
```

| List | Refers to |
|---|---|
| `deletions` | the OLD array |
| `insertions` | the NEW array |
| `updates` | the NEW array |
| `moves` | `from` is OLD, `to` is NEW |

This is the order UIKit and AppKit batch updates expect: delete from the old layout, then insert and move into the new one, then reload the updated items.

## Walk the result

Each list can be read on its own. For example, to log what happened to a list of products:

```swift
let changes = old.diff(new)

for index in changes.deletions { print("removed", old[index].sku) }
for index in changes.insertions { print("added", new[index].sku) }
for index in changes.updates { print("changed", new[index].sku) }
for (from, to) in changes.moves { print("moved", old[from].sku, "to", to) }
```

Note which array each index goes into: `old[index]` for deletions and the start of a move, `new[index]` for everything else.

You rarely need to apply the result by hand: `DiffableUI` applies it to a view for you.

## Updates and moves can overlap

An item can be both moved and updated. It then appears in `moves` and in `updates`.

## Duplicate keys

Keys should be unique among siblings. If they are not, the algorithms still return a consistent result (applying it always gives the new array), but items with the same key are matched in order or reported as a delete plus an insert.

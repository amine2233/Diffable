# Choosing an algorithm

Heckel finds moves in linear time; Myers always finds the shortest list of edits.

## Overview

Both algorithms answer the same question with the same result type. Pick one with ``DiffAlgorithm``:

```swift
let withMoves = old.diff(new)                       // .heckel (default)
let shortest  = old.diff(new, algorithm: .myers)
```

| | ``DiffAlgorithm/heckel`` | ``DiffAlgorithm/myers`` |
|---|---|---|
| Idea | hash table and anchors | shortest path in an edit graph |
| Time | O(n) | O((N+M)·D), D = number of edits |
| Moves | yes, minimal | no: a move is a delete plus an insert |
| Shortest script | not guaranteed | always |
| Duplicate keys | best effort | matched in order |
| Best for | UI lists, reordering | small edits on large lists, readable diffs |

## The same change, two answers

```
 old: [ A B C D ]  ->  new: [ B C D A ]

 Heckel: moves = [(0, 3)]                       1 operation
 Myers:  deletions = [0], insertions = [3]      2 operations
```

Heckel recognises that `A` only changed position. Myers has no notion of a move, so it deletes `A` and inserts it again.

## How Heckel works

Heckel identifies items by key with a hash table, in five passes:

```
 Pass 1  count every key of `new`
 Pass 2  count every key of `old`
 Pass 3  a key seen exactly ONCE on each side is the same item (an anchor)
 Pass 4  walk forward from each anchor: equal neighbours are the same item
 Pass 5  walk backward the same way

 Result  linked in both    -> unchanged, updated or moved
         only in old       -> delete
         only in new       -> insert
```

Items that are identical at the very start and end of both arrays are linked first, so identical arrays are an empty diff even with duplicate keys. Moves are minimal: the longest run of items already in order stays put and only the others move.

## How Myers works

Myers puts the old array on one axis and the new array on the other. Going right deletes, going down inserts, and a diagonal (same key) is free. The algorithm finds the cheapest path from the top-left to the bottom-right corner.

```
         old:   A     B     C
              0     1     2     3
         new  +-----+-----+-----+
          B   |  \  |     |     |      right = delete   down = insert
              +-----+-----+-----+      diagonal = same key, free
          C   |     |  \  |     |
              +-----+-----+-----+      [A B C] -> [B C D]:
          D   |     |     |     |      delete A, follow two diagonals, insert D
              +-----+-----+-----+
```

It needs memory proportional to the number of edits times the array sizes, so it is best when the two arrays are similar.

## Which one should I use?

- Showing a list to the user and the order can change: Heckel.
- You want the smallest possible script, or a readable text-like diff: Myers.
- You are not sure: Heckel.

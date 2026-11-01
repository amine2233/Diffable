# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Diffable is a small Swift package with two library products, `Diffable` (algorithms + tree diff, no UI) and `DiffableUI` (IndexPath/UICollectionView helpers, depends on `Diffable`; swift-tools 5.4) implementing Paul Heckel's diff algorithm to compute updates/insertions/deletions/moves between two arrays. Distributed via SPM and CocoaPods (`Diffable.podspec`, subspecs `Core` and `UI`; the pod compiles both into one `Diffable` module, hence `#if SWIFT_PACKAGE import Diffable` in DiffableUI).

## Commands

```bash
swift build -v
swift test -v
swift test --filter DiffableTests/<testName>   # single test
swiftlint                                      # config in .swiftlint.yml
```

CI (`.github/workflows/`) runs `swift build` / `swift test` on macOS and SwiftLint on push.

## Architecture

- `Diffable.swift` — `Diffable: Hashable`. Identity = `primaryKeyValue` / `diffIdentity` (the key the algorithms match on); content = `==` (decides *update*).
- `Diff.swift` — Heckel (default): O(n), detects moves (minimal, via longest increasing subsequence). `Myers.swift` — shortest edit script, no moves. `DiffAlgorithm.swift` picks one. Both emit the internal `DiffStep` (delete = old index; insert/update = new index; move = old -> new).
- `Foundation/Array+Diff.swift` — public `Array.diff(_:algorithm:)` returning index tuples. `Sources/DiffableUI/` (separate target, only uses the public tuple API) — `IndexPath` variant and `UICollectionView.apply` (two sequential batches because reloads use new indexes).
- `Foundation/TreeDiff.swift` — `DiffableTree` (`children`) and `treeDiff` -> `[TreeChange]`: diffs siblings per level, recurses into matched nodes, path-qualified. A `DiffableTree`'s `==` must exclude `children`.
- `AnyDiffable.swift` — type-erased wrapper; its `diffIdentity` includes the wrapped type.

## Notes

- Each source file carries ASCII-diagram docs of its algorithm; keep them in sync when changing behavior.
- Old tests are XCTest (`DiffableTests.swift`, `XCTestManifests.swift`; `LinuxMain.swift` was removed); new tests use Swift Testing. `TestSupport.swift` has `replay(...)`, an oracle that applies diff steps to the old array and checks it rebuilds the new one; `RandomizedTests` / `TreeRandomizedTests` run it over seeded random inputs (reproducible, change the seed to explore).
- `swiftlint lint Sources` reports many pre-existing style warnings (line length etc.).

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Diffable is a small Swift package with two library products, `Diffable` (algorithms + tree diff, no UI) and `DiffableUI` (animated updates for UIKit/AppKit/MapKit views and diffable data sources; depends on `Diffable`; swift-tools 5.4). Computes updates/insertions/deletions/moves between two arrays (Heckel or Myers) or two trees. Distributed via SwiftPM only (the podspec was removed); `#if SWIFT_PACKAGE import Diffable` in DiffableUI is a leftover from compiling both into one module and is harmless.

## Commands

```bash
mise run test                         # swift test (macOS + Linux in CI)
mise run test-coverage                # macOS only
mise run format                       # executor format .
mise run check_code                   # lint Sources
mise run check_documentation          # lint doc comments
mise run check_commit_title           # latest commit title vs conventional commits
mise run build_documentations         # DocC into ./public (use --serve to preview)
mise run release --dry-run            # semantic-release preview

swift build
swift test --filter <TypeOrFunctionName>   # single test
```

CI (`.github/workflows/ci.yml`) is a thin caller of `amine2233/ci-shared`: it runs the mise tasks above on macOS and Linux for PRs and pushes to `main`. `page.yml` publishes DocC after a green CI, `semantic-release.yml` is a manual release (dry run by default). PR titles must be conventional commits.

## Architecture

- `Diffable.swift` — `Diffable: Hashable`. Identity = `primaryKeyValue` / `diffIdentity` (the key the algorithms match on); content = `==` (decides *update*).
- `Diff.swift` — Heckel (default): O(n), detects moves (minimal, via longest increasing subsequence). `Myers.swift` — shortest edit script, no moves. `DiffAlgorithm.swift` picks one. Both emit the internal `DiffStep` (delete = old index; insert/update = new index; move = old -> new).
- `Foundation/Array+Diff.swift` — public `Array.diff(_:algorithm:)` returning index tuples. `Sources/DiffableUI/` (separate target, only uses the public API of `Diffable`): `Core/` is Foundation-only and tested on the host (`ListChanges`, `SequentialPlan` for sequential views, `SectionedChanges` built on `treeDiff`, `TreePath`); `UIKit/`, `AppKit/`, `MapKit/`, `Snapshot/` are thin per-view adapters. Simultaneous APIs (UIKit, NSCollectionView) use two batches because reloads need old indexes; sequential ones (NSTableView, NSOutlineView, NSMenu, stack views) go through `SequentialPlan`.
- `Foundation/TreeDiff.swift` — `DiffableTree` (`children`, `Child` may differ from the node type, e.g. section -> row) and `treeDiff` -> `[TreeChange]`: diffs siblings per level, recurses into matched nodes, path-qualified. A `DiffableTree`'s `==` must exclude `children`.
- `AnyDiffable.swift` — type-erased wrapper; its `diffIdentity` includes the wrapped type.

## Notes

- Each source file carries ASCII-diagram docs of its algorithm; keep them in sync when changing behavior.
- Old tests are XCTest (`DiffableTests.swift`, `XCTestManifests.swift`; `LinuxMain.swift` was removed); new tests use Swift Testing. `TestSupport.swift` has `replay(...)`, an oracle that applies diff steps to the old array and checks it rebuilds the new one; `RandomizedTests` / `TreeRandomizedTests` run it over seeded random inputs (reproducible, change the seed to explore).
- UIKit-only code cannot run on the macOS host: after touching `Sources/DiffableUI/UIKit` or `Snapshot`, typecheck against the iOS/tvOS SDK (`xcrun --sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios12.0-simulator -D SWIFT_PACKAGE -I <dir with Diffable.swiftmodule> $(find Sources/DiffableUI -name '*.swift')`). AppKit and MapKit adapters are tested on the host with real views (`AppKitViewTests`, `MapKitTests`).
- `swift test --filter` matches type/function names (e.g. `NSTableViewDiffTests`), not the display names.

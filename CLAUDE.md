# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Diffable is a small Swift package with two library products, `Diffable` (algorithms + tree diff, no UI) and `DiffableUI` (animated updates for UIKit/AppKit/MapKit views and diffable data sources; depends on `Diffable`; swift-tools 6.0, Swift 6 language mode). Computes updates/insertions/deletions/moves between two arrays (Heckel or Myers) or two trees. Distributed via SwiftPM only (the podspec was removed); `#if SWIFT_PACKAGE import Diffable` in DiffableUI is a leftover from compiling both into one module and is harmless.

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

- `Diffable.swift` — `Diffable: Hashable, Identifiable` (`ID: Sendable`). Identity = `id` (the engines match on `AnyHashable(item.id)`); content = `==` (decides *update*). `DiffID.swift` is the `Sendable`, literal-convertible wrapper used in results (`TreeChange.key/path`, `TreePath`, `SnapshotItemID`) because `AnyHashable` is not `Sendable`.
- `Heckel.swift` — the Heckel engine (default): O(n), detects moves (minimal, via longest increasing subsequence). `Myers.swift` — shortest edit script, no moves. `DiffAlgorithm.swift` picks one. Both emit the internal `DiffStep` (delete = old index; insert/update = new index; move = old -> new).
- `Foundation/Array+Diff.swift` — public `Array.diff(_:algorithm:)` returning index tuples; `Collection+Diff.swift` is the same for any `RandomAccessCollection` (copies into arrays, indexes are offsets; `treeDiff`, `listChanges`, `sectionedChanges` have generic overloads too); `Set+Diff.swift` (`SetChanges`, updates paired by `id` for Diffable elements) and `Dictionary+Diff.swift` (`DictionaryChanges`, `Value: Equatable`) are unordered, so no indexes or moves. `Sources/DiffableUI/` (separate target, only uses the public API of `Diffable`): `Core/` is Foundation-only and tested on the host (`ListChanges`, `SequentialPlan` for sequential views, `SectionedChanges` built on `treeDiff`, `TreePath`); `UIKit/`, `AppKit/`, `MapKit/`, `Snapshot/` are thin per-view adapters. Simultaneous APIs (UIKit, NSCollectionView) use two batches because reloads need old indexes; sequential ones (NSTableView, NSOutlineView, NSMenu, stack views) go through `SequentialPlan`.
- `Foundation/TreeDiff.swift` — `DiffableTree` (`children`, `Child` may differ from the node type, e.g. section -> row) and `treeDiff` -> `[TreeChange]`: diffs siblings per level, recurses into matched nodes, path-qualified. A `DiffableTree`'s `==` must exclude `children`.
- `AnyDiffable.swift` — type-erased wrapper; its `id` is a `DiffID` that includes the wrapped type.

## Notes

- Each source file carries ASCII-diagram docs of its algorithm; keep them in sync when changing behavior.
- All tests use Swift Testing; there is no XCTest left on purpose: on Linux the XCTest runner (`XCTestCase.invokeTest` -> `awaitUsingExpectation`) deadlocks intermittently (it hung in 10 of 14 runs even on a tree without any of our code changes). Do not add `XCTestCase` classes, `LinuxMain.swift` or `XCTestManifests.swift`. `TestSupport.swift` has `replay(...)`, an oracle that applies diff steps to the old array and checks it rebuilds the new one; `RandomizedTests` / `TreeRandomizedTests` run it over seeded random inputs (reproducible, change the seed to explore).
- UIKit-only code cannot run on the macOS host: after touching `Sources/DiffableUI/UIKit` or `Snapshot`, typecheck against the iOS/tvOS SDK (`xcrun --sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios12.0-simulator -D SWIFT_PACKAGE -I <dir with Diffable.swiftmodule> $(find Sources/DiffableUI -name '*.swift')`). AppKit and MapKit adapters are tested on the host with real views (`AppKitViewTests`, `MapKitTests`).
- `swift test --filter` matches type/function names (e.g. `NSTableViewDiffTests`), not the display names.
- DocC catalogs live in `Sources/Diffable/Diffable.docc` and `Sources/DiffableUI/DiffableUI.docc` (tools-version 5.5 is what lets SwiftPM handle them). Build them with `xcodebuild docbuild -scheme Diffable -destination 'generic/platform=macOS'` (same for `DiffableUI`) and keep articles and `///` parameter lists complete: DocC warns about any undocumented parameter once one is documented.
- With `mise.toml` in this folder, plain `swift` is mise's open-source Swift 6.3.1, which can fail against the installed Xcode SDK (`unknown argument '-target-arch-variant'`). Use `xcrun swift build` / `xcrun swift test` locally if that happens.
- Swift 6 language mode (`swiftLanguageModes: [.v6]`). Concurrency rules: `Diffable` does NOT require `Sendable`; the pure value types (`DiffAlgorithm`, `TreeChange`, `ListChanges`, `SequentialPlan`, `SectionedChanges`, `ItemPosition`, `TreePath`, `SnapshotItemID`, both `DiffAnimations`) are `Sendable`; every view adapter extension in `UIKit/`, `AppKit/`, `MapKit/` is `@MainActor` with `@MainActor` closure parameters; `Core/` and the snapshot builders stay nonisolated. Never use `@unchecked Sendable` or `nonisolated(unsafe)` to silence an error.
- Type-check UIKit code in Swift 6 mode too: the scratchpad recipe needs `-swift-version 6` on both `swiftc` calls (plain `swiftc` defaults to Swift 5 mode and hides errors).
- Collection tests are split by type: `RandomAccessCollectionDiffTests.swift`, `SetDiffTests.swift`, `DictionaryDiffTests.swift` (core) and `GenericCollectionTests.swift` (DiffableUI).

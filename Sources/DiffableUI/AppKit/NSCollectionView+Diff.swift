#if canImport(AppKit) && !targetEnvironment(macCatalyst)

#if SWIFT_PACKAGE
import Diffable
#endif
import AppKit

extension NSCollectionView {
    /// Applies the changes of ONE section. Same two-batch order as `UICollectionView.apply`:
    ///
    /// ```
    ///  batch 1 (old -> new layout)                batch 2 (new layout)
    ///  ---------------------------                --------------------
    ///  updateData()                               reloadItems(updates)
    ///  deleteItems(deletions)       [old idx]
    ///  insertItems(insertions)      [new idx]
    ///  moveItem(from old, to new)
    /// ```
    public func apply(
        _ changes: ListChanges,
        section: Int = 0,
        updateData: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        let paths = changes.indexPaths(section: section)

        performBatchUpdates({
            updateData()
            self.deleteItems(at: Set(paths.deletions))
            self.insertItems(at: Set(paths.insertions))
            for move in paths.moves {
                self.moveItem(at: move.from, to: move.to)
            }
        }, completionHandler: { _ in
            guard !paths.updates.isEmpty else {
                completion?()
                return
            }

            self.performBatchUpdates({
                self.reloadItems(at: Set(paths.updates))
            }, completionHandler: { _ in
                completion?()
            })
        })
    }

    /// Diffs `old` against `new` and animates the difference in one section.
    public func applyDiff<Element: Diffable>(
        from old: [Element],
        to new: [Element],
        section: Int = 0,
        algorithm: DiffAlgorithm = .heckel,
        updateData: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        apply(
            old.listChanges(to: new, algorithm: algorithm),
            section: section,
            updateData: updateData,
            completion: completion
        )
    }

    /// Applies the changes of several sections (see `SectionedChanges` for the moved-section rule).
    public func apply(
        _ changes: SectionedChanges,
        updateData: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        performBatchUpdates({
            updateData()

            self.deleteSections(changes.sectionDeletionIndexes)
            self.insertSections(changes.sectionInsertionIndexes)
            for move in changes.sectionMoves {
                self.moveSection(move.from, toSection: move.to)
            }

            self.deleteItems(at: Set(changes.itemDeletionPaths))
            self.insertItems(at: Set(changes.itemInsertionPaths))
            for move in changes.itemMovePaths {
                self.moveItem(at: move.from, to: move.to)
            }
        }, completionHandler: { _ in
            guard !changes.sectionUpdates.isEmpty || !changes.itemUpdates.isEmpty else {
                completion?()
                return
            }

            self.performBatchUpdates({
                self.reloadSections(changes.sectionUpdateIndexes)
                self.reloadItems(at: Set(changes.itemUpdatePaths))
            }, completionHandler: { _ in
                completion?()
            })
        })
    }

    /// Diffs two lists of sections (a section is a `DiffableTree` whose children are its items).
    public func applyDiff<Section: DiffableTree>(
        fromSections old: [Section],
        toSections new: [Section],
        algorithm: DiffAlgorithm = .heckel,
        updateData: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        apply(
            old.sectionedChanges(to: new, algorithm: algorithm),
            updateData: updateData,
            completion: completion
        )
    }
}

#endif

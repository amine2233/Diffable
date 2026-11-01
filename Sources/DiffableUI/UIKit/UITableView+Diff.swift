#if canImport(UIKit) && !os(watchOS)

#if SWIFT_PACKAGE
import Diffable
#endif
import UIKit

extension UITableView {
    /// The row animation used for each kind of change.
    public struct DiffAnimations {
        public var insert: RowAnimation
        public var delete: RowAnimation
        public var reload: RowAnimation

        public init(
            insert: RowAnimation = .automatic,
            delete: RowAnimation = .automatic,
            reload: RowAnimation = .automatic
        ) {
            self.insert = insert
            self.delete = delete
            self.reload = reload
        }

        public static let automatic = DiffAnimations()
    }

    /// Applies the changes of ONE section.
    ///
    /// ```
    ///  batch 1                                  batch 2 (only if there are updates)
    ///  -------                                  -------
    ///  updateData()                             reloadRows(updates)       [new idx]
    ///  deleteRows(deletions)  [old idx]
    ///  insertRows(insertions) [new idx]
    ///  moveRow(from old, to new)
    /// ```
    @available(iOS 11.0, tvOS 11.0, *)
    public func apply(
        _ changes: ListChanges,
        section: Int = 0,
        animations: DiffAnimations = .automatic,
        updateData: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        let paths = changes.indexPaths(section: section)

        performBatchUpdates({
            updateData()
            self.deleteRows(at: paths.deletions, with: animations.delete)
            self.insertRows(at: paths.insertions, with: animations.insert)
            for move in paths.moves {
                self.moveRow(at: move.from, to: move.to)
            }
        }, completion: { _ in
            guard !paths.updates.isEmpty else {
                completion?()
                return
            }

            self.performBatchUpdates({
                self.reloadRows(at: paths.updates, with: animations.reload)
            }, completion: { _ in
                completion?()
            })
        })
    }

    /// Diffs `old` against `new` and animates the difference in one section.
    @available(iOS 11.0, tvOS 11.0, *)
    public func applyDiff<Element: Diffable>(
        from old: [Element],
        to new: [Element],
        section: Int = 0,
        algorithm: DiffAlgorithm = .heckel,
        animations: DiffAnimations = .automatic,
        updateData: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        apply(
            old.listChanges(to: new, algorithm: algorithm),
            section: section,
            animations: animations,
            updateData: updateData,
            completion: completion
        )
    }

    /// Applies the changes of several sections, with the same two-batch order as `UICollectionView`.
    @available(iOS 11.0, tvOS 11.0, *)
    public func apply(
        _ changes: SectionedChanges,
        animations: DiffAnimations = .automatic,
        updateData: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        performBatchUpdates({
            updateData()

            self.deleteSections(changes.sectionDeletionIndexes, with: animations.delete)
            self.insertSections(changes.sectionInsertionIndexes, with: animations.insert)
            for move in changes.sectionMoves {
                self.moveSection(move.from, toSection: move.to)
            }

            self.deleteRows(at: changes.itemDeletionPaths, with: animations.delete)
            self.insertRows(at: changes.itemInsertionPaths, with: animations.insert)
            for move in changes.itemMovePaths {
                self.moveRow(at: move.from, to: move.to)
            }
        }, completion: { _ in
            guard !changes.sectionUpdates.isEmpty || !changes.itemUpdates.isEmpty else {
                completion?()
                return
            }

            self.performBatchUpdates({
                self.reloadSections(changes.sectionUpdateIndexes, with: animations.reload)
                self.reloadRows(at: changes.itemUpdatePaths, with: animations.reload)
            }, completion: { _ in
                completion?()
            })
        })
    }

    /// Diffs two lists of sections (a section is a `DiffableTree` whose children are its rows).
    @available(iOS 11.0, tvOS 11.0, *)
    public func applyDiff<Section: DiffableTree>(
        fromSections old: [Section],
        toSections new: [Section],
        algorithm: DiffAlgorithm = .heckel,
        animations: DiffAnimations = .automatic,
        updateData: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        apply(
            old.sectionedChanges(to: new, algorithm: algorithm),
            animations: animations,
            updateData: updateData,
            completion: completion
        )
    }
}

#endif

//
//  UICollectionView+Diff.swift
//  DiffableUI
//
//  Created by Amine Bensalah on 05/12/2019.
//

#if canImport(UIKit)

#if SWIFT_PACKAGE
import Diffable
#endif
import UIKit

#if !os(watchOS)
extension UICollectionView {

    /// Applies index paths computed by `Array.diff(_:forSection:algorithm:)`.
    ///
    /// UIKit reads indexes in two different coordinate systems inside one batch, and `reloadItems`
    /// would need OLD indexes while `updates` holds NEW ones. So the work is split in two
    /// sequential batches:
    ///
    /// ```
    ///  batch 1 (old -> new layout)                batch 2 (new layout)
    ///  ---------------------------                --------------------
    ///  block()   update your data source          reloadItems(updates)
    ///  deleteItems(deletions)       [old idx]
    ///  insertItems(insertions)      [new idx]
    ///  moveItem(from old, to new)
    ///                      \                       /
    ///                       +--- on completion ---+--- then `completion`
    /// ```
    ///
    /// - Parameters:
    ///   - block: Mutates the data source. Runs at the start of the first batch.
    ///   - updates: New-array index paths whose content changed.
    ///   - insertions: New-array index paths.
    ///   - deletions: Old-array index paths.
    ///   - moves: From old-array, to new-array index paths.
    ///   - completion: Called once both batches finished.
    public func apply(_ block: @escaping () -> Void, updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(from: IndexPath, to: IndexPath)], completion: (() -> Void)? = nil) {

        performBatchUpdates({
            block()

            self.deleteItems(at: deletions)
            self.insertItems(at: insertions)

            for move in moves {
                self.moveItem(at: move.from, to: move.to)
            }
        }, completion: { _ in
            guard !updates.isEmpty else {
                completion?()
                return
            }
            self.performBatchUpdates({
                self.reloadItems(at: updates)
            }, completion: { _ in
                completion?()
            })
        })
    }

    /// Applies the changes of ONE section.
    public func apply(_ changes: ListChanges, section: Int = 0, updateData: @escaping () -> Void, completion: (() -> Void)? = nil) {
        let paths = changes.indexPaths(section: section)
        apply(updateData, updates: paths.updates, insertions: paths.insertions, deletions: paths.deletions, moves: paths.moves, completion: completion)
    }

    /// Diffs `old` against `new` and animates the difference in one section.
    ///
    /// ```
    ///  collectionView.applyDiff(from: items, to: newItems) { items = newItems }
    /// ```
    public func applyDiff<Element: Diffable>(from old: [Element], to new: [Element], section: Int = 0, algorithm: DiffAlgorithm = .heckel, updateData: @escaping () -> Void, completion: (() -> Void)? = nil) {
        apply(old.listChanges(to: new, algorithm: algorithm), section: section, updateData: updateData, completion: completion)
    }

    /// Applies the changes of several sections.
    ///
    /// ```
    ///  batch 1                                        batch 2
    ///  -------                                        -------
    ///  updateData()                                   reloadSections(sectionUpdates)
    ///  deleteSections(sectionDeletions)  [old]        reloadItems(itemUpdates)         [new]
    ///  insertSections(sectionInsertions) [new]
    ///  moveSection(from old, to new)
    ///  deleteItems / insertItems / moveItem
    /// ```
    public func apply(_ changes: SectionedChanges, updateData: @escaping () -> Void, completion: (() -> Void)? = nil) {

        performBatchUpdates({
            updateData()

            self.deleteSections(changes.sectionDeletionIndexes)
            self.insertSections(changes.sectionInsertionIndexes)
            for move in changes.sectionMoves {
                self.moveSection(move.from, toSection: move.to)
            }

            self.deleteItems(at: changes.itemDeletionPaths)
            self.insertItems(at: changes.itemInsertionPaths)
            for move in changes.itemMovePaths {
                self.moveItem(at: move.from, to: move.to)
            }
        }, completion: { _ in
            guard !changes.sectionUpdates.isEmpty || !changes.itemUpdates.isEmpty else {
                completion?()
                return
            }
            self.performBatchUpdates({
                self.reloadSections(changes.sectionUpdateIndexes)
                self.reloadItems(at: changes.itemUpdatePaths)
            }, completion: { _ in
                completion?()
            })
        })
    }

    /// Diffs two lists of sections (a section is a `DiffableTree` whose children are its items).
    public func applyDiff<Section: DiffableTree>(fromSections old: [Section], toSections new: [Section], algorithm: DiffAlgorithm = .heckel, updateData: @escaping () -> Void, completion: (() -> Void)? = nil) {
        apply(old.sectionedChanges(to: new, algorithm: algorithm), updateData: updateData, completion: completion)
    }
}
#endif
#endif

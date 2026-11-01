//
//  UICollectionViewExtension.swift
//  DiffableUI
//
//  Created by Amine Bensalah on 05/12/2019.
//

#if canImport(UIKit)

import UIKit

#if !os(watchOS)
extension UICollectionView {

    /// Applies the result of `Array.diff(_:forSection:algorithm:)` to the collection view.
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
}
#endif
#endif

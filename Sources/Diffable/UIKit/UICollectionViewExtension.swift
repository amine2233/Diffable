//
//  UICollectionViewExtension.swift
//  Diffable
//
//  Created by Amine Bensalah on 05/12/2019.
//

#if canImport(UIKit)

import UIKit

extension UICollectionView {

    func applay(_ block: () -> Void, updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(from: IndexPath, to: IndexPath)], completion: (() -> Void)?) {

        let group = DispatchGroup()

        group.enter()

        performBatchUpdates({
            block()

            self.deleteItems(at: deletions)
            self.insertItems(at: insertions)

            for move in moves {
                self.moveItem(at: move.from, to: move.to)
            }

        }) { _ in
            group.leave()
        }

        group.enter()

        performBatchUpdates({
            self.reloadItems(at: updates)
        }) { _ in
            group.leave()
        }

        group.notify(queue: .main, execute: {
            completion?()
        })
    }
}
#endif

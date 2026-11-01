#if canImport(UIKit) || canImport(AppKit)

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

extension ItemPosition {
    public var indexPath: IndexPath {
        IndexPath(item: item, section: section)
    }
}

extension ListChanges {
    /// The changes as index paths of one section. Same index spaces as the integers
    /// (deletions and move sources are OLD, the rest NEW).
    public func indexPaths(section: Int = 0)
        -> (updates: [IndexPath], insertions: [IndexPath], deletions: [IndexPath], moves: [(
            from: IndexPath,
            to: IndexPath
        )]) {
        func path(_ item: Int) -> IndexPath {
            IndexPath(item: item, section: section)
        }

        return (
            updates.map(path),
            insertions.map(path),
            deletions.map(path),
            moves.map { (from: path($0.from), to: path($0.to)) }
        )
    }
}

extension SectionedChanges {
    public var sectionDeletionIndexes: IndexSet {
        IndexSet(sectionDeletions)
    }

    public var sectionInsertionIndexes: IndexSet {
        IndexSet(sectionInsertions)
    }

    public var sectionUpdateIndexes: IndexSet {
        IndexSet(sectionUpdates)
    }

    public var itemDeletionPaths: [IndexPath] {
        itemDeletions.map(\.indexPath)
    }

    public var itemInsertionPaths: [IndexPath] {
        itemInsertions.map(\.indexPath)
    }

    public var itemUpdatePaths: [IndexPath] {
        itemUpdates.map(\.indexPath)
    }

    public var itemMovePaths: [(from: IndexPath, to: IndexPath)] {
        itemMoves.map { (from: $0.from.indexPath, to: $0.to.indexPath) }
    }
}

#endif

#if SWIFT_PACKAGE
import Diffable
#endif
import Foundation

/// A position in a sectioned list.
public struct ItemPosition: Hashable {
    public let section: Int
    public let item: Int

    public init(section: Int, item: Int) {
        self.section = section
        self.item = item
    }
}

/// The changes of a list of sections, each holding items. A list of sections is a two-level tree:
/// section = node, items = its children, so the work is done by `treeDiff`.
///
/// ```
///   old                  new
///   S0 [a b]             S0 [a]            item    delete    (0,1)       OLD section, OLD item
///   S1 [c]               S2 [e f]          section insert    1           NEW index
///   S2 [d]               S1 [c]            section move      1 -> 2      OLD -> NEW
/// ```
///
/// Index spaces: `*Deletions` use the OLD indexes, `*Insertions` and `*Updates` the NEW ones,
/// `*Moves` go from OLD to NEW. This is what UIKit and `NSCollectionView` batch updates expect.
///
/// ## The moved/updated section rule
///
/// UIKit and AppKit refuse to insert, delete or move items **inside** a section that is itself being
/// moved or reloaded in the same batch. So when a section moved (or its own content changed) and it also has
/// item changes, it is reported as a section delete + a section insert instead. Its items then come
/// from the data source as a whole.
///
/// ```
///   section moved,   items unchanged        -> sectionMoves
///   section updated, items unchanged        -> sectionUpdates       (reload the section)
///   section moved or updated, items changed -> sectionDeletions (OLD) + sectionInsertions (NEW)
///   section unchanged, items changed        -> item level changes
/// ```
///
/// Only two levels are read: changes below the items are ignored.
public struct SectionedChanges {
    public var sectionDeletions: [Int] = []
    public var sectionInsertions: [Int] = []
    public var sectionUpdates: [Int] = []
    public var sectionMoves: [(from: Int, to: Int)] = []

    public var itemDeletions: [ItemPosition] = []
    public var itemInsertions: [ItemPosition] = []
    public var itemUpdates: [ItemPosition] = []
    public var itemMoves: [(from: ItemPosition, to: ItemPosition)] = []

    /// - Parameter sections: The result of `oldSections.treeDiff(newSections)`.
    public init(_ sections: [TreeChange]) {
        for section in sections {
            switch section.kind {
            case .delete:
                sectionDeletions.append(section.index)
            case .insert:
                sectionInsertions.append(section.index)
            case .update, .unchanged:
                addMatched(section)
            }
        }
    }

    public var isEmpty: Bool {
        sectionDeletions.isEmpty && sectionInsertions.isEmpty && sectionUpdates.isEmpty && sectionMoves
            .isEmpty
            && itemDeletions.isEmpty && itemInsertions.isEmpty && itemUpdates.isEmpty && itemMoves.isEmpty
    }

    private mutating func addMatched(_ section: TreeChange) {
        guard let oldSection = section.oldIndex else {
            return
        }

        let newSection = section.index
        let itemsChanged = section.children.contains { $0.kind != .unchanged || $0.movedFrom != nil }
        let updated = section.kind == .update
        let moved = section.movedFrom != nil

        if updated || moved, itemsChanged || (updated && moved) {
            sectionDeletions.append(oldSection)
            sectionInsertions.append(newSection)
            return
        }
        if updated {
            sectionUpdates.append(newSection)
            return
        }
        if let from = section.movedFrom {
            sectionMoves.append((from: from, to: newSection))
            return
        }

        for item in section.children {
            switch item.kind {
            case .delete:
                itemDeletions.append(ItemPosition(section: oldSection, item: item.index))
            case .insert:
                itemInsertions.append(ItemPosition(section: newSection, item: item.index))
            case .update:
                itemUpdates.append(ItemPosition(section: newSection, item: item.index))
            case .unchanged:
                break
            }
            if let from = item.movedFrom {
                itemMoves.append((
                    from: ItemPosition(section: oldSection, item: from),
                    to: ItemPosition(section: newSection, item: item.index)
                ))
            }
        }
    }
}

extension Array where Element: DiffableTree {
    /// Diffs two lists of sections (nodes whose `children` are the items).
    public func sectionedChanges(to new: [Element], algorithm: DiffAlgorithm = .heckel) -> SectionedChanges {
        SectionedChanges(treeDiff(new, algorithm: algorithm))
    }
}

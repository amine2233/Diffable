//
//  DiffableSnapshot.swift
//  DiffableUI
//

#if (canImport(UIKit) || canImport(AppKit)) && !os(watchOS)

#if SWIFT_PACKAGE
import Diffable
#endif
import Foundation
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The identifier of an item in a sectioned snapshot.
///
/// Diffable data sources need item identifiers that are unique across ALL sections, so the section
/// key is part of the identity:
///
/// ```
///  section "Inbox"  / item "42"   SnapshotItemID(section: "Inbox",  item: "42")
///  section "Sent"   / item "42"   SnapshotItemID(section: "Sent",   item: "42")     different
/// ```
public struct SnapshotItemID: Hashable {
    public let section: String
    public let item: String

    public init(section: String, item: String) {
        self.section = section
        self.item = item
    }
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15.1, *)
extension NSDiffableDataSourceSnapshot where SectionIdentifierType == String, ItemIdentifierType == SnapshotItemID {

    /// A snapshot of `sections` (a section is a `DiffableTree`, its children are the items).
    ///
    /// ```
    ///  [ Section("Inbox", [Row 1, Row 2]), Section("Sent", [Row 3]) ]
    ///      -> sections: "Inbox", "Sent"
    ///      -> items:    (Inbox,1) (Inbox,2) | (Sent,3)
    /// ```
    public init<Section: DiffableTree>(sections: [Section]) {
        self.init()
        for section in sections {
            let key = section.primaryKeyValue
            appendSections([key])
            appendItems(section.children.map { SnapshotItemID(section: key, item: $0.primaryKeyValue) }, toSection: key)
        }
    }

    /// The snapshot of `new`, with the sections and items whose CONTENT changed marked for refresh.
    ///
    /// A diffable data source only compares identifiers, so an item whose identity is unchanged but
    /// whose content changed would never be redrawn. Diffing `old` against `new` finds those items and
    /// marks them: `reconfigureItems` on UIKit (iOS 15), `reloadItems` otherwise.
    ///
    /// ```
    ///  old: Inbox [1 2]        new: Inbox' [1 2']
    ///                               Inbox' header changed  -> reloadSections(["Inbox"])
    ///                               item 2 content changed -> reconfigureItems([(Inbox,2)])
    /// ```
    public init<Section: DiffableTree>(from old: [Section], to new: [Section], algorithm: DiffAlgorithm = .heckel) {
        self.init(sections: new)

        var sectionsToReload: [String] = []
        var itemsToRefresh: [SnapshotItemID] = []
        for section in old.treeDiff(new, algorithm: algorithm) where section.kind != .delete && section.kind != .insert {
            if section.kind == .update {
                sectionsToReload.append(section.key)
            }
            for item in section.children where item.kind == .update {
                itemsToRefresh.append(SnapshotItemID(section: section.key, item: item.key))
            }
        }

        if !sectionsToReload.isEmpty {
            reloadSections(sectionsToReload)
        }
        if !itemsToRefresh.isEmpty {
            #if canImport(UIKit)
            if #available(iOS 15.0, tvOS 15.0, *) {
                reconfigureItems(itemsToRefresh)
            } else {
                reloadItems(itemsToRefresh)
            }
            #else
            reloadItems(itemsToRefresh)
            #endif
        }
    }
}

#endif

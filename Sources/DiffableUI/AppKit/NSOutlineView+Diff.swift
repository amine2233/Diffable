//
//  NSOutlineView+Diff.swift
//  DiffableUI
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

#if SWIFT_PACKAGE
import Diffable
#endif
import AppKit

extension NSOutlineView {

    /// Animates the difference between two trees (folders, files...) in an outline view.
    ///
    /// The tree is diffed level by level (`treeDiff`), and each level is applied with the sequential
    /// calls `NSOutlineView` expects. Only levels that changed are touched:
    ///
    /// ```
    ///  old                     new                      calls
    ///  root                    root
    ///  ├── src                 ├── src                  src : reloadItem
    ///  │   └── a.swift (1)     │   ├── a.swift (2)      a.swift : reloadItem
    ///  │                       │   └── b.swift          insertItems(at: 1, inParent: src)
    ///  └── docs                └── (removed)            removeItems(at: 1, inParent: root)
    /// ```
    ///
    /// - Parameters:
    ///   - old: The top-level nodes before.
    ///   - new: The top-level nodes after.
    ///   - item: Returns the object the data source uses as the outline item for a node path, or `nil` for the
    ///     outline root. It is only called for parents that exist in BOTH trees, and must return the same
    ///     object your `outlineView(_:child:ofItem:)` hands out for that path after `updateData`.
    ///   - updateData: Mutates the data source.
    public func applyDiff<Node: DiffableTree>(from old: [Node], to new: [Node], algorithm: DiffAlgorithm = .heckel, animations: NSTableView.DiffAnimations = .default, item: (TreePath) -> Any?, updateData: () -> Void) {

        let changes = old.treeDiff(new, algorithm: algorithm)

        updateData()

        beginUpdates()
        applyLevel(old: old, new: new, changes: changes, parent: nil, animations: animations, item: item)
        endUpdates()
    }

    private func applyLevel<Node: DiffableTree>(old: [Node], new: [Node], changes: [TreeChange], parent: Any?, animations: NSTableView.DiffAnimations, item: (TreePath) -> Any?) {

        let list = ListChanges(siblings: changes)

        SequentialPlan(changes: list, oldCount: old.count, newCount: new.count).perform(remove: { index in
            removeItems(at: IndexSet(integer: index), inParent: parent, withAnimation: animations.remove)
        }, insert: { index in
            insertItems(at: IndexSet(integer: index), inParent: parent, withAnimation: animations.insert)
        }, move: { from, to in
            moveItem(at: from, inParent: parent, to: to, inParent: parent)
        })

        for change in changes {
            let path = TreePath(change.path)

            switch change.kind {
            case .update:
                if let node = item(path) {
                    reloadItem(node, reloadChildren: false)
                }
            case .delete, .insert, .unchanged:
                break
            }

            guard change.kind == .update || change.kind == .unchanged,
                  !change.children.isEmpty,
                  let oldIndex = change.oldIndex else {
                continue
            }

            applyLevel(old: old[oldIndex].children,
                       new: new[change.index].children,
                       changes: change.children,
                       parent: item(path),
                       animations: animations,
                       item: item)
        }
    }
}

#endif

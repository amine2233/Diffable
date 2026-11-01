//
//  TreeSnapshot.swift
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

#if canImport(UIKit)
@available(iOS 14.0, tvOS 14.0, *)
extension NSDiffableDataSourceSectionSnapshot where ItemIdentifierType == TreePath {

    /// An expandable outline snapshot of a tree, for a collection view with an outline layout.
    ///
    /// ```
    ///  roots: [ root ]                      snapshot (TreePath identifiers)
    ///  root/                                ▾ root
    ///  ├── src/                               ▾ root/src
    ///  │   └── a.swift                          · root/src/a.swift
    ///  └── docs/                              ▸ root/docs         (collapsed: not in `expanded`)
    /// ```
    ///
    /// - Parameters:
    ///   - roots: The top-level nodes.
    ///   - expanded: The paths to show expanded. Everything else is collapsed.
    public init<Node: DiffableTree>(roots: [Node], expanded: Set<TreePath> = []) {
        self.init()
        Self.append(roots, parent: nil, to: &self)
        expand(items.filter { expanded.contains($0) })
    }

    private static func append<Node: DiffableTree>(_ nodes: [Node], parent: TreePath?, to snapshot: inout NSDiffableDataSourceSectionSnapshot<TreePath>) {
        let paths = nodes.map { TreePath((parent?.components ?? []) + [$0.primaryKeyValue]) }
        snapshot.append(paths, to: parent)
        for (node, path) in zip(nodes, paths) {
            append(node.children, parent: path, to: &snapshot)
        }
    }
}
#endif

extension Array where Element: DiffableTree {

    /// The paths of the nodes whose own content changed between `self` and `new`.
    ///
    /// Feed them to `reconfigureItems` / `reloadItems`: a diffable data source compares identifiers
    /// only, so edited nodes would otherwise not be redrawn.
    public func updatedPaths(to new: [Element], algorithm: DiffAlgorithm = .heckel) -> [TreePath] {
        func collect(_ changes: [TreeChange]) -> [TreePath] {
            return changes.flatMap { change -> [TreePath] in
                (change.kind == .update ? [TreePath(change.path)] : []) + collect(change.children)
            }
        }
        return collect(treeDiff(new, algorithm: algorithm))
    }
}

#endif

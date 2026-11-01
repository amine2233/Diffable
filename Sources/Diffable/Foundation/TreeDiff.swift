//
//  TreeDiff.swift
//  Diffable
//

import Foundation

/// A node of a tree (a folder with files and sub folders, for example).
///
/// ```
///  root/                       children = [src, docs]
///  ├── src/                    children = [a.swift, util]
///  │   ├── a.swift             children = []
///  │   └── util/               children = [b.swift]
///  │       └── b.swift
///  └── docs/
/// ```
///
/// - Important: `==` and `hash(into:)` must compare the node's **own** properties only (name, size,
///   modification date...) and NOT `children`. Children are compared by recursion, which is what lets
///   the result say *which* descendant changed instead of flagging the whole folder as updated.
/// - `primaryKeyValue` must be unique among the children of one parent (a file name for example).
///   Two files with the same name in different folders are fine: identity is the whole path.
public protocol DiffableTree: Diffable {
    var children: [Self] { get }
}

/// One changed node in a tree diff. The changes form a tree themselves: a node whose own content did not
/// change but whose descendants did is kept as `.unchanged` so the path down to the change is preserved.
///
/// ```
///  old                       new                         treeDiff result
///  src/                      src/                        = src                 (unchanged, has changes below)
///  ├── a.swift               ├── a.swift                   = util              (unchanged, has changes below)
///  └── util/                 └── util/                       ~ b.swift         (update)
///      └── b.swift (v1)          ├── b.swift (v2)            + c.swift         (insert)
///  docs/                         └── c.swift               - docs              (delete, ONE entry:
///  └── index.md                                                                 its files are not repeated)
/// ```
public struct TreeChange: Equatable {

    public enum Kind: Equatable {

        /// The node exists only in the new tree. Its descendants are not listed.
        case insert

        /// The node exists only in the old tree. Its descendants are not listed.
        case delete

        /// The node exists in both trees and its own content (`==`) changed.
        case update

        /// The node exists in both trees with the same content; only descendants (or its position) changed.
        case unchanged
    }

    /// The `primaryKeyValue` of the node.
    public let key: String

    /// The keys from the root to this node (included): `["src", "util", "b.swift"]`.
    public let path: [String]

    public let kind: Kind

    /// Index among its siblings: in the OLD siblings for `.delete`, in the NEW siblings otherwise.
    public let index: Int

    /// When the node changed position among its siblings, the index it had in the OLD siblings.
    public let movedFrom: Int?

    /// The changes found below this node.
    public let children: [TreeChange]
}

extension TreeChange: CustomStringConvertible {

    /// A readable outline of the change tree.
    ///
    /// ```
    ///  = src
    ///    = util
    ///      ~ b.swift
    ///      + c.swift
    ///  - docs
    /// ```
    /// `+` insert, `-` delete, `~` update, `=` unchanged container. A moved node adds `(moved from n)`.
    public var description: String {
        return outline(depth: 0).joined(separator: "\n")
    }

    private func outline(depth: Int) -> [String] {
        let marker: String
        switch kind {
        case .insert: marker = "+"
        case .delete: marker = "-"
        case .update: marker = "~"
        case .unchanged: marker = "="
        }
        let moved = movedFrom.map { " (moved from \($0))" } ?? ""
        let line = String(repeating: "  ", count: depth) + "\(marker) \(key)\(moved)"
        return [line] + children.flatMap { $0.outline(depth: depth + 1) }
    }
}

extension Array where Element: DiffableTree {

    /// Diffs two lists of sibling trees (for example the content of a root folder) recursively.
    ///
    /// ```
    ///  level 0:  diff(old roots, new roots)                 <- Heckel or Myers
    ///               |
    ///               +-- node in both?  yes -> level 1: diff(old.children, new.children)
    ///               |                                      |
    ///               |                                      +-- ... and so on, path grows: [src] -> [src, util] ...
    ///               +-- only in old -> .delete  (whole subtree, one entry)
    ///               +-- only in new -> .insert  (whole subtree, one entry)
    /// ```
    ///
    /// Only nodes that changed, or that have a changed descendant, appear in the result.
    ///
    /// - Parameters:
    ///   - new: The new siblings.
    ///   - algorithm: The algorithm used at **every** level. `.myers` never reports `movedFrom`.
    /// - Returns: The change tree, deletions first, then the new siblings in order. Empty when nothing changed.
    public func treeDiff(_ new: [Element], algorithm: DiffAlgorithm = .heckel) -> [TreeChange] {
        return treeDiff(new, algorithm: algorithm, parentPath: [])
    }

    private func treeDiff(_ new: [Element], algorithm: DiffAlgorithm, parentPath: [String]) -> [TreeChange] {

        var deleted: [Int] = []
        var inserted = Set<Int>()
        var updated = Set<Int>()
        var movedFrom: [Int: Int] = [:]

        for step in algorithm.process(old: self, new: new) {
            switch step {
            case .delete(let index, _):
                deleted.append(index)
            case .insert(let index, _):
                inserted.insert(index)
            case .update(let index, _):
                updated.insert(index)
            case .move(let from, let to, _):
                movedFrom[to] = from
            }
        }

        var changes: [TreeChange] = deleted.sorted().map { index in
            let key = self[index].primaryKeyValue
            return TreeChange(key: key, path: parentPath + [key], kind: .delete, index: index, movedFrom: nil, children: [])
        }

        var survivors: [AnyHashable: [Int]] = [:]
        let deletedSet = Set(deleted)
        for (index, node) in enumerated() where !deletedSet.contains(index) {
            survivors[node.diffIdentity, default: []].append(index)
        }

        for (index, node) in new.enumerated() {
            let path = parentPath + [node.primaryKeyValue]

            guard !inserted.contains(index), let oldIndex = survivors[node.diffIdentity]?.removeFirst() else {
                changes.append(TreeChange(key: node.primaryKeyValue, path: path, kind: .insert, index: index, movedFrom: nil, children: []))
                continue
            }

            let childChanges = self[oldIndex].children.treeDiff(node.children, algorithm: algorithm, parentPath: path)
            let kind: TreeChange.Kind = updated.contains(index) ? .update : .unchanged
            let moved = movedFrom[index]

            guard kind != .unchanged || moved != nil || !childChanges.isEmpty else {
                continue
            }

            changes.append(TreeChange(key: node.primaryKeyValue, path: path, kind: kind, index: index, movedFrom: moved, children: childChanges))
        }

        return changes
    }
}

extension DiffableTree {

    /// Diffs this root against another root.
    ///
    /// ```
    ///  root(old)  vs  root(new)      same key  -> [ root: .unchanged / .update, children: [...] ]
    ///                                 key changed -> [ root: .delete, root': .insert ]
    /// ```
    ///
    /// - Returns: Usually one `TreeChange` for the root with its descendants' changes as `children`;
    ///   empty when the trees are identical.
    public func treeDiff(to new: Self, algorithm: DiffAlgorithm = .heckel) -> [TreeChange] {
        return [self].treeDiff([new], algorithm: algorithm)
    }
}

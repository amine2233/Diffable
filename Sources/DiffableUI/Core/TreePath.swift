#if SWIFT_PACKAGE
import Diffable
#endif
import Foundation

/// The identity of a node in a tree: the ids from the root to the node.
///
/// ```
///  root/
///  └── src/
///      └── a.swift        TreePath(["root", "src", "a.swift"])
/// ```
///
/// Two files with the same name in different folders have different paths, which makes it a safe
/// item identifier for diffable data sources.
public struct TreePath: Hashable, CustomStringConvertible, Sendable {
    public let components: [DiffID]

    public init(_ components: [DiffID]) {
        self.components = components
    }

    public var parent: TreePath? {
        components.count > 1 ? TreePath(Array(components.dropLast())) : nil
    }

    public var description: String {
        components.map { "\($0)" }.joined(separator: "/")
    }
}

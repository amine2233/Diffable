import Foundation

/// The algorithm used to compare two arrays of siblings.
///
/// ```
///                      heckel                         myers
///   --------------------------------------------------------------------------
///   idea               hash table + anchors           shortest path in edit graph
///   time               O(n)                           O((N+M)·D)
///   moves              yes (minimal, via LIS)         no (delete + insert)
///   shortest script    not guaranteed                 always
///   duplicate keys     best effort                    matched in order
///   best for           UI lists, reordering           small edits on large lists,
///                                                     readable minimal diffs
/// ```
public enum DiffAlgorithm: Sendable {
    /// Paul Heckel's linear algorithm. See `Diff`.
    case heckel

    /// Eugene Myers' shortest-edit-script algorithm. See `Myers`.
    case myers

    func process<T: Diffable>(old: [T], new: [T]) -> [DiffStep<T>] {
        switch self {
        case .heckel:
            var diff = Diff()
            return diff.process(old: old, new: new)
        case .myers:
            return Myers().process(old: old, new: new)
        }
    }
}

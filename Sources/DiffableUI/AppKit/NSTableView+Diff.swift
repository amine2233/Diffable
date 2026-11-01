#if canImport(AppKit) && !targetEnvironment(macCatalyst)

#if SWIFT_PACKAGE
import Diffable
#endif
import AppKit

extension NSTableView {
    /// The animation used for each kind of row change.
    public struct DiffAnimations {
        /// The animation used when a row is inserted.
        public var insert: AnimationOptions
        /// The animation used when a row is removed.
        public var remove: AnimationOptions

        /// Creates the animations.
        ///
        /// - Parameters:
        ///   - insert: The animation of inserted rows.
        ///   - remove: The animation of removed rows.
        public init(insert: AnimationOptions = .effectFade, remove: AnimationOptions = .effectFade) {
            self.insert = insert
            self.remove = remove
        }

        /// Fade in and fade out.
        public static let `default` = DiffAnimations()
    }

    /// Applies list changes to the table.
    ///
    /// `NSTableView` applies its calls **sequentially**: every index is relative to the state left by
    /// the previous call. So the changes go through `SequentialPlan` first:
    ///
    /// ```
    ///  updateData()                         your data source now holds the NEW rows
    ///  beginUpdates()
    ///    removeRows(...)                    highest index first
    ///    insertRows(...) / moveRow(...)     walking the NEW indexes in order
    ///  endUpdates()                         AppKit checks numberOfRows == old - removed + inserted
    ///  reloadData(forRowIndexes: updates)   rows whose content changed, all columns
    /// ```
    ///
    /// - Parameters:
    ///   - changes: The diff between the old and the new rows.
    ///   - oldCount: Number of rows before.
    ///   - newCount: Number of rows after.
    ///   - animations: The animation of inserted and removed rows.
    ///   - updateData: Mutates the data source.
    public func apply(
        _ changes: ListChanges,
        oldCount: Int,
        newCount: Int,
        animations: DiffAnimations = .default,
        updateData: () -> Void
    ) {
        updateData()

        beginUpdates()
        SequentialPlan(changes: changes, oldCount: oldCount, newCount: newCount).perform(remove: { index in
            removeRows(at: IndexSet(integer: index), withAnimation: animations.remove)
        }, insert: { index in
            insertRows(at: IndexSet(integer: index), withAnimation: animations.insert)
        }, move: { from, to in
            moveRow(at: from, to: to)
        })
        endUpdates()

        if !changes.updates.isEmpty {
            reloadData(
                forRowIndexes: changes.updateIndexes,
                columnIndexes: IndexSet(0 ..< tableColumns.count)
            )
        }
    }

    /// Diffs `old` against `new` and animates the difference.
    public func applyDiff<Element: Diffable>(
        from old: [Element],
        to new: [Element],
        algorithm: DiffAlgorithm = .heckel,
        animations: DiffAnimations = .default,
        updateData: () -> Void
    ) {
        apply(
            old.listChanges(to: new, algorithm: algorithm),
            oldCount: old.count,
            newCount: new.count,
            animations: animations,
            updateData: updateData
        )
    }
}

#endif

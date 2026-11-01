#if canImport(AppKit) && !targetEnvironment(macCatalyst)

#if SWIFT_PACKAGE
import Diffable
#endif
import AppKit

@MainActor
extension NSMenu {
    /// Keeps the menu items in sync with a list of models without rebuilding the menu, so open
    /// submenus, key equivalents and item state of untouched items survive.
    ///
    /// ```
    ///  models old: [ open  save  close ]        items: [ Io Is Ic ]
    ///  models new: [ open  close  quit ]
    ///
    ///  remove(1)        [ Io Ic ]               Is removed
    ///  insert(2)        [ Io Ic Iq ]            makeItem(quit)
    ///  updates          update(item, model)     for models whose content changed
    /// ```
    ///
    /// - Parameters:
    ///   - old: The models the current `items` were built from, in order.
    ///   - new: The models of the new menu.
    ///   - algorithm: The algorithm used to compare `old` and `new`.
    ///   - makeItem: Creates the item of a new model.
    ///   - update: Refreshes an existing item whose model changed.
    public func applyDiff<Element: Diffable>(
        from old: [Element],
        to new: [Element],
        algorithm: DiffAlgorithm = .heckel,
        makeItem: @MainActor (Element) -> NSMenuItem,
        update: @MainActor (NSMenuItem, Element) -> Void
    ) {
        let changes = old.listChanges(to: new, algorithm: algorithm)

        SequentialPlan(changes: changes, oldCount: old.count, newCount: new.count).perform(remove: { index in
            removeItem(at: index)
        }, insert: { index in
            insertItem(makeItem(new[index]), at: index)
        }, move: { from, to in
            let item = items[from]
            removeItem(at: from)
            insertItem(item, at: to)
        })

        for index in changes.updates {
            update(items[index], new[index])
        }
    }
}

#endif

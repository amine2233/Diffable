#if canImport(AppKit) && !targetEnvironment(macCatalyst)

#if SWIFT_PACKAGE
import Diffable
#endif
import AppKit

extension NSStackView {
    /// Keeps the arranged subviews in sync with a list of models: unchanged views are kept,
    /// new ones are created, removed ones are dropped, reordered ones are moved.
    ///
    /// ```
    ///  models old: [ a  b  c ]        arrangedSubviews: [ Va Vb Vc ]
    ///  models new: [ c  a  d ]
    ///
    ///  remove(1)         [ Va Vc ]          Vb leaves the stack and the hierarchy
    ///  move(1 -> 0)      [ Vc Va ]          Vc is reused, not recreated
    ///  insert(2)         [ Vc Va Vd ]       makeView(d)
    ///  updates           update(Vx, model)  for views whose model changed content
    /// ```
    ///
    /// - Parameters:
    ///   - old: The models currently shown, in order. Must match `arrangedSubviews`.
    ///   - new: The models to show.
    ///   - algorithm: The algorithm used to compare `old` and `new`.
    ///   - makeView: Creates the view of a new model.
    ///   - update: Refreshes an existing view whose model changed.
    public func applyDiff<Element: Diffable, View: NSView>(
        from old: [Element],
        to new: [Element],
        algorithm: DiffAlgorithm = .heckel,
        makeView: (Element) -> View,
        update: (View, Element) -> Void
    ) {
        let changes = old.listChanges(to: new, algorithm: algorithm)

        SequentialPlan(changes: changes, oldCount: old.count, newCount: new.count).perform(remove: { index in
            let view = arrangedSubviews[index]
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }, insert: { index in
            insertArrangedSubview(makeView(new[index]), at: index)
        }, move: { from, to in
            let view = arrangedSubviews[from]
            removeArrangedSubview(view)
            insertArrangedSubview(view, at: to)
        })

        for index in changes.updates {
            if let view = arrangedSubviews[index] as? View {
                update(view, new[index])
            }
        }
    }
}

#endif

//
//  UIStackView+Diff.swift
//  DiffableUI
//

#if canImport(UIKit) && !os(watchOS)

#if SWIFT_PACKAGE
import Diffable
#endif
import UIKit

extension UIStackView {

    /// Keeps the arranged subviews in sync with a list of models: unchanged views are kept,
    /// new ones are created, removed ones are dropped, reordered ones are moved.
    ///
    /// ```
    ///  models old: [ a  b  c ]        arrangedSubviews: [ Va Vb Vc ]
    ///  models new: [ c  a  d ]
    ///
    ///  remove(1)         [ Va Vc ]          Vb is removed from the stack and the hierarchy
    ///  move(1 -> 0)      [ Vc Va ]          Vc is reused, not recreated
    ///  insert(2)         [ Vc Va Vd ]       makeView(d)
    ///  updates           update(Vx, model)  for views whose model changed content
    /// ```
    ///
    /// - Parameters:
    ///   - old: The models currently shown, in order. Must match `arrangedSubviews`.
    ///   - new: The models to show.
    ///   - animated: Wraps the work in `UIView.animate` and lays out.
    ///   - makeView: Creates the view of a new model.
    ///   - update: Refreshes an existing view whose model changed.
    public func applyDiff<Element: Diffable, View: UIView>(from old: [Element], to new: [Element], algorithm: DiffAlgorithm = .heckel, animated: Bool = true, duration: TimeInterval = 0.25, makeView: @escaping (Element) -> View, update: @escaping (View, Element) -> Void) {

        let changes = old.listChanges(to: new, algorithm: algorithm)
        let plan = SequentialPlan(changes: changes, oldCount: old.count, newCount: new.count)

        let work = {
            plan.perform(remove: { index in
                let view = self.arrangedSubviews[index]
                self.removeArrangedSubview(view)
                view.removeFromSuperview()
            }, insert: { index in
                self.insertArrangedSubview(makeView(new[index]), at: index)
            }, move: { from, to in
                let view = self.arrangedSubviews[from]
                self.removeArrangedSubview(view)
                self.insertArrangedSubview(view, at: to)
            })

            for index in changes.updates {
                if let view = self.arrangedSubviews[index] as? View {
                    update(view, new[index])
                }
            }
        }

        if animated {
            UIView.animate(withDuration: duration) {
                work()
                self.layoutIfNeeded()
            }
        } else {
            work()
        }
    }
}

#endif

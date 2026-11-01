#if canImport(UIKit) && os(iOS)

#if SWIFT_PACKAGE
import Diffable
#endif
import UIKit

@available(iOS 13.0, *)
extension UIMenu {
    /// `UIMenu` is immutable, so a "diff" can only rebuild it. What this does is keep the
    /// `UIMenuElement` instances of the models that did not change, so the system keeps their state
    /// (highlight, identity, in-flight actions) and only the new or edited models are rebuilt.
    ///
    /// ```
    ///  old models: [ a  b  c ]    children: [ Ea Eb Ec ]
    ///  new models: [ a  c' d ]    c' = c with other content
    ///
    ///  a  : same identity, same content  -> reuse Ea
    ///  c' : same identity, new content   -> make(c')
    ///  d  : new                          -> make(d)
    ///  b  : gone
    ///
    ///  result: UIMenu(children: [ Ea  make(c')  make(d) ])
    /// ```
    ///
    /// - Parameters:
    ///   - old: The models the current `children` were built from, in order.
    ///   - new: The models of the new menu.
    ///   - make: Builds the element of a new or edited model.
    public func replacingChildren<Element: Diffable>(
        from old: [Element],
        to new: [Element],
        make: (Element) -> UIMenuElement
    ) -> UIMenu {
        var reusable: [AnyHashable: (model: Element, element: UIMenuElement)] = [:]
        for (model, element) in zip(old, children) {
            reusable[model.diffIdentity] = (model: model, element: element)
        }

        let newChildren = new.map { model -> UIMenuElement in
            if let match = reusable[model.diffIdentity], match.model == model {
                return match.element
            }
            return make(model)
        }

        return UIMenu(
            title: title,
            image: image,
            identifier: identifier,
            options: options,
            children: newChildren
        )
    }
}

#endif

#if canImport(MapKit) && !os(watchOS)

#if SWIFT_PACKAGE
import Diffable
#endif
import MapKit

/// An annotation that can be diffed: `primaryKeyValue` is its identity (a place id), `==` its content
/// (title, coordinate...).
public protocol DiffableAnnotation: Diffable, MKAnnotation {}

@MainActor
extension MKMapView {
    /// Updates the annotations on the map with a diff instead of removing and re-adding everything,
    /// so pins that did not change do not flicker, lose their selection or restart their animation.
    ///
    /// ```
    ///  old: [ A  B  C ]            map shows A B C
    ///  new: [ A  C' D ]            C' = C with a new coordinate/title
    ///
    ///  B   gone            -> removeAnnotation(B)
    ///  C'  same identity   -> update(C, C')            keeps the pin on the map, no flicker
    ///                         (no `update` closure: removeAnnotation(C) + addAnnotation(C'))
    ///  D   new             -> addAnnotation(D)
    ///  A   unchanged       -> untouched
    /// ```
    ///
    /// Annotations are unordered on a map, so moves are ignored. Identities must be unique.
    ///
    /// - Parameters:
    ///   - old: The annotations currently on the map, as returned by the previous call.
    ///   - new: The annotations that should be on the map.
    ///   - algorithm: The algorithm used to compare `old` and `new`.
    ///   - update: Copies the new content (coordinate, title...) onto the annotation already on the map.
    /// - Returns: The annotations now on the map, in the order of `new`. Pass it as `old` next time:
    ///   for updated annotations it contains the instance already on the map, not the one from `new`.
    @discardableResult
    public func syncAnnotations<Annotation: DiffableAnnotation>(
        from old: [Annotation],
        to new: [Annotation],
        algorithm: DiffAlgorithm = .heckel,
        update: (@MainActor (_ onMap: Annotation, _ new: Annotation) -> Void)? = nil
    ) -> [Annotation] {
        let changes = old.listChanges(to: new, algorithm: algorithm)
        let inserted = Set(changes.insertions)
        let updated = Set(changes.updates)

        removeAnnotations(changes.deletions.map { old[$0] })

        var onMap: [AnyHashable: Annotation] = [:]
        for annotation in old {
            onMap[annotation.diffIdentity] = annotation
        }

        var result: [Annotation] = []
        var toAdd: [Annotation] = []

        for (index, annotation) in new.enumerated() {
            guard !inserted.contains(index), let existing = onMap[annotation.diffIdentity] else {
                toAdd.append(annotation)
                result.append(annotation)
                continue
            }
            guard updated.contains(index) else {
                result.append(existing)
                continue
            }

            if let update {
                update(existing, annotation)
                result.append(existing)
            } else {
                removeAnnotation(existing)
                toAdd.append(annotation)
                result.append(annotation)
            }
        }

        addAnnotations(toAdd)
        return result
    }
}

#endif

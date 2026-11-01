# Map annotations

Update the pins of a map without removing and re-adding all of them.

## Make an annotation diffable

``DiffableAnnotation`` combines `Diffable` and `MKAnnotation`. The `id` is the identity of the place, and `==` compares what you want to detect changes on:

```swift
final class Pin: NSObject, DiffableAnnotation {
    let id: String
    var title: String?
    dynamic var coordinate: CLLocationCoordinate2D

    init(id: String, title: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.title = title
        self.coordinate = coordinate
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Pin else { return false }
        return other.id == id && other.title == title
            && other.coordinate.latitude == coordinate.latitude && other.coordinate.longitude == coordinate.longitude
    }

    override var hash: Int { id.hashValue }
}
```

## Sync the map

`syncAnnotations(from:to:update:)` removes the pins that disappeared, adds the new ones and leaves the others alone, so they do not flicker or lose their selection:

```swift
var shown: [Pin] = []

func show(_ pins: [Pin]) {
    shown = mapView.syncAnnotations(from: shown, to: pins) { onMap, new in
        onMap.title = new.title
        onMap.coordinate = new.coordinate
    }
}
```

```
 old: [ A  B  C ]            map shows A B C
 new: [ A  C' D ]            C' = C with a new coordinate or title

 B   gone            -> removeAnnotation(B)
 C'  same identity   -> update(C, C')       keeps the pin on the map
 D   new             -> addAnnotation(D)
 A   unchanged       -> untouched
```

- Without the `update` closure, an edited pin is replaced (removed and added again).
- The call returns the annotations now on the map, in the order of `to`. Pass it as `from` next time: for an updated pin it holds the instance already on the map, not the one you passed in.
- Annotations are unordered on a map, so moves are ignored. Identities must be unique.

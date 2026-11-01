#if canImport(MapKit) && !os(watchOS)
import MapKit
import Testing
import Diffable
@testable import DiffableUI

private final class Pin: NSObject, DiffableAnnotation {
    let id: String
    var title: String?
    dynamic var coordinate: CLLocationCoordinate2D

    init(_ id: String, title: String = "", latitude: Double = 0) {
        self.id = id
        self.title = title
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: 0)
    }

    var primaryKeyValue: String { id }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Pin else { return false }
        return other.id == id && other.title == title && other.coordinate.latitude == coordinate.latitude
    }

    override var hash: Int { id.hashValue ^ (title ?? "").hashValue }
}

@MainActor
@Suite("MKMapView") struct MapKitDiffTests {

    private func ids(_ map: MKMapView) -> [String] {
        map.annotations.compactMap { ($0 as? Pin)?.id }.sorted()
    }

    @Test("pins are added and removed")
    func addsAndRemoves() {
        let map = MKMapView(frame: .zero)
        var shown: [Pin] = []

        shown = map.syncAnnotations(from: shown, to: [Pin("a"), Pin("b"), Pin("c")])
        #expect(ids(map) == ["a", "b", "c"])

        shown = map.syncAnnotations(from: shown, to: [Pin("a"), Pin("c"), Pin("d")])
        #expect(ids(map) == ["a", "c", "d"])
    }

    @Test("an unchanged pin keeps the same instance")
    func keepsInstance() {
        let map = MKMapView(frame: .zero)
        let first = Pin("a")
        var shown = map.syncAnnotations(from: [], to: [first, Pin("b")])

        shown = map.syncAnnotations(from: shown, to: [Pin("a"), Pin("b")])

        #expect(shown.first === first)
        #expect(map.annotations.contains { $0 === first })
    }

    @Test("an edited pin is updated in place when an update closure is given")
    func updatesInPlace() {
        let map = MKMapView(frame: .zero)
        let first = Pin("a", title: "old")
        var shown = map.syncAnnotations(from: [], to: [first])

        shown = map.syncAnnotations(from: shown, to: [Pin("a", title: "new")]) { onMap, new in onMap.title = new.title }

        #expect(shown.first === first)
        #expect(first.title == "new")
        #expect(map.annotations.count == 1)
    }

    @Test("an edited pin is replaced when there is no update closure")
    func replacesWithoutClosure() {
        let map = MKMapView(frame: .zero)
        var shown = map.syncAnnotations(from: [], to: [Pin("a", title: "old")])
        let replacement = Pin("a", title: "new")

        shown = map.syncAnnotations(from: shown, to: [replacement])

        #expect(shown.first === replacement)
        #expect(map.annotations.count == 1 && map.annotations.first === replacement)
    }

    @Test("random syncs keep the map equal to the target", arguments: [DiffAlgorithm.heckel, .myers])
    func randomSyncs(algorithm: DiffAlgorithm) {
        var generator = Seeded(seed: 61)
        let map = MKMapView(frame: .zero)
        var shown: [Pin] = []
        for _ in 0..<150 {
            let target = randomRows(maxCount: 8, using: &generator).map { Pin($0.id, title: "\($0.value)") }

            shown = map.syncAnnotations(from: shown, to: target, algorithm: algorithm) { onMap, new in onMap.title = new.title }

            #expect(ids(map) == target.map(\.id).sorted())
            #expect(shown.map(\.id) == target.map(\.id))
        }
    }
}
#endif

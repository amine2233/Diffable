import Testing
@testable import Diffable

extension Int: @retroactive Identifiable {
    public var id: Int {
        self
    }
}

extension Int: Diffable {}

@Suite("Diffs of type-erased lists")
struct DiffableTests {

    @Test("new entry difference")
    func testNewEntryDifference() {
        let actualArray: [AnyDiffable] = []
        let newArray = [AnyDiffable(1)]

        let value = actualArray.diff(newArray)

        #expect(value.insertions.count == 1)
        #expect(value.updates.count == 0)
        #expect(value.moves.count == 0)
        #expect(value.deletions.count == 0)
    }

    @Test("no difference")
    func testNoDifference() {
        let actualArray = [AnyDiffable(1), AnyDiffable(2)]
        let newArray = [AnyDiffable(1), AnyDiffable(2)]

        let value = actualArray.diff(newArray)

        #expect(value.insertions.count == 0)
        #expect(value.updates.count == 0)
        #expect(value.moves.count == 0)
        #expect(value.deletions.count == 0)
    }

    @Test("add new element difference")
    func testAddNewElementDifference() {
        let actualArray = [AnyDiffable(1), AnyDiffable(2)]
        let newArray = [AnyDiffable(1), AnyDiffable(2), AnyDiffable(2)]

        let value = actualArray.diff(newArray)

        #expect(value.insertions.count == 1)
        #expect(value.updates.count == 0)
        #expect(value.moves.count == 0)
        #expect(value.deletions.count == 0)
    }

    @Test("remove new element difference")
    func testRemoveNewElementDifference() {
        let actualArray = [AnyDiffable(1), AnyDiffable(2)]
        let newArray = [AnyDiffable(1)]

        let value = actualArray.diff(newArray)

        #expect(value.insertions.count == 0)
        #expect(value.updates.count == 0)
        #expect(value.moves.count == 0)
        #expect(value.deletions.count == 1)
    }

    @Test("move element difference")
    func testMoveElementDifference() {
        let actualArray = [AnyDiffable(1), AnyDiffable(2)]
        let newArray = [AnyDiffable(2), AnyDiffable(1)]

        let value = actualArray.diff(newArray)

        #expect(value.insertions.count == 0)
        #expect(value.updates.count == 0)
        #expect(value.moves.count == 1)
        #expect(value.deletions.count == 0)
    }

    @Test("update element difference")
    func testUpdateElementDifference() {
        struct Car: Diffable {
            var id: String
            var name: String

        }

        let actualArray = [AnyDiffable(Car(id: "1", name: "Audi")), AnyDiffable(Car(id: "2", name: "BMW"))]
        let newArray = [AnyDiffable(Car(id: "1", name: "Audi")), AnyDiffable(Car(id: "2", name: "Mercedes"))]

        let value = actualArray.diff(newArray)

        #expect(value.insertions.count == 0)
        #expect(value.updates.count == 1)
        #expect(value.moves.count == 0)
        #expect(value.deletions.count == 0)
    }

    @Test("many entry difference")
    func testManyEntryDifference() {
        let actualArray: [AnyDiffable] = []
        let newArray = [AnyDiffable(1), AnyDiffable(2), AnyDiffable(3)]

        let value = actualArray.diff(newArray)

        #expect(value.insertions.count == 3)
        #expect(value.updates.count == 0)
        #expect(value.moves.count == 0)
        #expect(value.deletions.count == 0)
    }

    @Test("many entries difference")
    func testManyEntriesDifference() {
        let actualArray: [AnyDiffable] = [AnyDiffable(1), AnyDiffable(2), AnyDiffable(3), AnyDiffable(6)]
        let newArray = [
            AnyDiffable(1),
            AnyDiffable(2),
            AnyDiffable(3),
            AnyDiffable(4),
            AnyDiffable(5),
            AnyDiffable(6)
        ]

        let value = actualArray.diff(newArray)

        #expect(value.insertions.count == 2)
        #expect(value.updates.count == 0)
        #expect(value.moves.count == 0)
        #expect(value.deletions.count == 0)
    }

    @Test("many move elements difference")
    func testManyMoveElementsDifference() {
        struct Car: Diffable {
            var id: String
            var name: String

        }

        let actualArray = [
            Car(id: "1", name: "Audi"),
            Car(id: "2", name: "BMW"),
            Car(id: "3", name: "Mercedes")
        ]
        let newArray = [Car(id: "2", name: "BMW"), Car(id: "3", name: "Mercedes"), Car(id: "1", name: "Audi")]

        let value = actualArray.diff(newArray)

        #expect(value.insertions.count == 0)
        #expect(value.updates.count == 0)
        #expect(value.moves.count == 1)
        #expect(value.deletions.count == 0)
    }
}

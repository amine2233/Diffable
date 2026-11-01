import Testing
@testable import Diffable

@Suite("Examples (readable scenarios)")
struct ExamplesTests {
    @Test("[a b c] → [b c d]: a is deleted, d is inserted")
    func listExample() {
        let result = items("abc").diff(items("bcd"))
        #expect(result.deletions == [0])
        #expect(result.insertions == [2])
    }

    @Test("[a b c d] → [b c d a]: Heckel sees ONE move, Myers sees delete + insert")
    func rotationExample() {
        let heckel = items("abcd").diff(items("bcda"))
        let myers = items("abcd").diff(items("bcda"), algorithm: .myers)

        #expect(heckel.moves.count == 1 && heckel.deletions.isEmpty)
        #expect(myers.moves.isEmpty && myers.deletions == [0] && myers.insertions == [3])
    }

    @Test("a cart: price change is an update, removal is a delete, new product is an insert")
    func cartExample() {
        struct Line: Diffable {
            let sku: String
            var quantity: Int
            var primaryKeyValue: String {
                sku
            }
        }
        let before = [
            Line(sku: "shoes", quantity: 1),
            Line(sku: "hat", quantity: 2),
            Line(sku: "bag", quantity: 1)
        ]
        let after = [
            Line(sku: "shoes", quantity: 3),
            Line(sku: "bag", quantity: 1),
            Line(sku: "belt", quantity: 1)
        ]

        let result = before.diff(after)

        #expect(result.updates == [0])
        #expect(result.deletions == [1])
        #expect(result.insertions == [2])
    }

    @Test("a project folder: the change tree points at the edited file")
    func folderExample() {
        let before = folder(
            "MyApp",
            folder("Sources", file("main.swift", size: 10), file("util.swift", size: 5)),
            folder("Docs", file("README.md"))
        )
        let after = folder(
            "MyApp",
            folder(
                "Sources",
                file("main.swift", size: 12),
                file("util.swift", size: 5),
                file("new.swift")
            )
        )

        let outline = before.treeDiff(to: after).map(\.description).joined(separator: "\n")

        #expect(outline == """
        = MyApp
          - Docs
          = Sources
            ~ main.swift
            + new.swift
        """)
    }

    @Test("type erasure: Article 1 and Video 1 live in the same list")
    func typeErasureExample() {
        struct Article: Diffable { let id: Int; var primaryKeyValue: String {
            String(id)
        } }
        struct Video: Diffable { let id: Int; var primaryKeyValue: String {
            String(id)
        } }

        let feed: [AnyDiffable] = [AnyDiffable(Article(id: 1)), AnyDiffable(Video(id: 1))]
        let refreshed: [AnyDiffable] = [AnyDiffable(Video(id: 1)), AnyDiffable(Article(id: 1))]

        let result = feed.diff(refreshed)

        #expect(result.moves.count == 1)
        #expect(result.insertions.isEmpty && result.deletions.isEmpty)
    }
}

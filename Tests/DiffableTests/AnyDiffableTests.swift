import Testing
@testable import Diffable

private struct Article: Diffable { let id: Int; var title = ""; var primaryKeyValue: String { String(id) } }
private struct Video: Diffable { let id: Int; var primaryKeyValue: String { String(id) } }

@Suite("AnyDiffable") struct AnyDiffableTests {

    @Test("wrapping different types with the same key is not equal")
    func differentTypesAreDifferent() {
        #expect(AnyDiffable(Article(id: 42)) != AnyDiffable(Video(id: 42)))
    }

    @Test("same type and same value is equal and hashes the same")
    func sameValueIsEqual() {
        let first = AnyDiffable(Article(id: 42, title: "a"))
        let second = AnyDiffable(Article(id: 42, title: "a"))
        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
    }

    @Test("same key with other content is not equal but has the same identity")
    func sameIdentityOtherContent() {
        let first = AnyDiffable(Article(id: 1, title: "a"))
        let second = AnyDiffable(Article(id: 1, title: "b"))
        #expect(first != second)
        #expect(first.diffIdentity == second.diffIdentity)
    }

    @Test("the identity contains the wrapped type")
    func identityContainsType() {
        #expect(AnyDiffable(Article(id: 1)).diffIdentity != AnyDiffable(Video(id: 1)).diffIdentity)
        #expect(AnyDiffable(Article(id: 1)).primaryKeyValue == AnyDiffable(Video(id: 1)).primaryKeyValue)
    }

    @Test("a heterogeneous list: same key, other type is delete + insert, never an update")
    func heterogeneousList() {
        let old: [AnyDiffable] = [AnyDiffable(Article(id: 1)), AnyDiffable(Video(id: 2))]
        let new: [AnyDiffable] = [AnyDiffable(Video(id: 1)), AnyDiffable(Video(id: 2))]

        for algorithm in algorithms {
            let result = old.diff(new, algorithm: algorithm)
            #expect(result.deletions == [0])
            #expect(result.insertions == [0])
            #expect(result.updates.isEmpty)
        }
    }

    @Test("map transforms only the matching type")
    func mapOnlyMatchingType() {
        let article = AnyDiffable(Article(id: 1, title: "a"))
        let video = AnyDiffable(Video(id: 1))

        let mapped = article.map { (value: Article) in Article(id: value.id, title: "changed") }
        let untouched = video.map { (value: Article) in Article(id: value.id, title: "changed") }

        #expect(mapped == AnyDiffable(Article(id: 1, title: "changed")))
        #expect(untouched == video)
    }

    @Test("flatMap returns self for another type")
    func flatMapOtherType() {
        let video = AnyDiffable(Video(id: 1))
        let result = video.flatMap { (_: Article) in AnyDiffable(Article(id: 9)) }
        #expect(result == video)
    }

    @Test("apply with a nil transform gives nil")
    func applyNil() throws {
        let nothing: ((Article) throws -> Article)? = nil
        #expect(try AnyDiffable(Article(id: 1)).apply(transform: nothing) == nil)
    }
}

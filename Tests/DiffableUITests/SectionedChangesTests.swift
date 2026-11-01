import Diffable
import Testing
@testable import DiffableUI

extension Row: DiffableTree {
    var children: [Row] {
        []
    }
}

private struct Section: DiffableTree {
    let title: String
    var header = 0
    var children: [Row] = []

    var id: String {
        title
    }

    static func == (lhs: Section, rhs: Section) -> Bool {
        lhs.title == rhs.title && lhs.header == rhs.header
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title); hasher.combine(header)
    }
}

private func section(_ title: String, _ ids: String, header: Int = 0) -> Section {
    Section(title: title, header: header, children: rows(ids))
}

@Suite("SectionedChanges")
struct SectionedChangesTests {
    @Test("item insert and delete in a stable section")
    func stableSection() {
        let old = [section("A", "abc"), section("B", "xy")]
        let new = [section("A", "bcd"), section("B", "xy")]

        let changes = old.sectionedChanges(to: new)

        #expect(changes.itemDeletions == [ItemPosition(section: 0, item: 0)])
        #expect(changes.itemInsertions == [ItemPosition(section: 0, item: 2)])
        #expect(changes.sectionMoves.isEmpty && changes.sectionUpdates.isEmpty)
    }

    @Test("a deletion uses the OLD section index even when an earlier section was inserted")
    func oldSectionIndexForDeletions() {
        let changes = [section("B", "ab")].sectionedChanges(to: [section("A", "x"), section("B", "b")])

        #expect(changes.sectionInsertions == [0])
        #expect(changes.itemDeletions == [ItemPosition(section: 0, item: 0)])
    }

    @Test("an inserted section is one entry")
    func insertedSection() {
        let changes = [section("A", "a")].sectionedChanges(to: [section("A", "a"), section("B", "bcd")])
        #expect(changes.sectionInsertions == [1])
        #expect(changes.itemInsertions.isEmpty)
    }

    @Test("a deleted section is one entry")
    func deletedSection() {
        let changes = [section("A", "a"), section("B", "bcd")].sectionedChanges(to: [section("A", "a")])
        #expect(changes.sectionDeletions == [1])
        #expect(changes.itemDeletions.isEmpty)
    }

    @Test("a moved section without item changes is a section move")
    func movedSection() {
        let old = [section("A", "a"), section("B", "b"), section("C", "c")]
        let new = [section("B", "b"), section("C", "c"), section("A", "a")]

        let changes = old.sectionedChanges(to: new)

        #expect(changes.sectionMoves.count == 1)
        #expect(changes.sectionMoves[0].from == 0 && changes.sectionMoves[0].to == 2)
        #expect(changes.sectionDeletions.isEmpty)
    }

    @Test("a moved section WITH item changes becomes delete + insert")
    func movedSectionWithItemChanges() {
        let old = [section("A", "a"), section("B", "b"), section("C", "c")]
        let new = [section("B", "b"), section("C", "c"), section("A", "ax")]

        let changes = old.sectionedChanges(to: new)

        #expect(changes.sectionDeletions == [0])
        #expect(changes.sectionInsertions == [2])
        #expect(changes.sectionMoves.isEmpty && changes.itemInsertions.isEmpty)
    }

    @Test("an updated section without item changes is a section reload")
    func updatedSection() {
        let changes = [section("A", "a")].sectionedChanges(to: [section("A", "a", header: 1)])
        #expect(changes.sectionUpdates == [0])
        #expect(changes.sectionDeletions.isEmpty)
    }

    @Test("an updated section with item changes becomes delete + insert")
    func updatedSectionWithItemChanges() {
        let changes = [section("A", "a")].sectionedChanges(to: [section("A", "ab", header: 1)])
        #expect(changes.sectionDeletions == [0])
        #expect(changes.sectionInsertions == [0])
    }

    @Test("an item moved inside a section")
    func itemMoved() {
        let changes = [section("A", "abc")].sectionedChanges(to: [section("A", "bca")])

        #expect(changes.itemMoves.count == 1)
        #expect(changes.itemMoves[0].from == ItemPosition(section: 0, item: 0))
        #expect(changes.itemMoves[0].to == ItemPosition(section: 0, item: 2))
    }

    @Test("an item moved to another section is delete + insert")
    func itemMovedAcrossSections() {
        let old = [section("A", "ax"), section("B", "b")]
        let new = [section("A", "a"), section("B", "bx")]

        let changes = old.sectionedChanges(to: new)

        #expect(changes.itemDeletions == [ItemPosition(section: 0, item: 1)])
        #expect(changes.itemInsertions == [ItemPosition(section: 1, item: 1)])
    }

    @Test("item updates use the NEW section and item index")
    func itemUpdates() {
        let old = [section("Z", "z"), section("A", "xy")]
        var edited = old
        edited.remove(at: 0)
        edited[0].children[1].value = 5

        let changes = old.sectionedChanges(to: edited)

        #expect(changes.sectionDeletions == [0])
        #expect(changes.itemUpdates == [ItemPosition(section: 0, item: 1)])
    }

    @Test("identical sections are empty")
    func empty() {
        let value = [section("A", "ab"), section("B", "c")]
        #expect(value.sectionedChanges(to: value).isEmpty)
    }

    @Test("random sections: the changes are consistent with the data")
    func randomConsistency() {
        var generator = Seeded(seed: 41)
        for _ in 0 ..< 1_500 {
            let old = randomSections(using: &generator)
            let new = mutatedSections(old, using: &generator)

            check(old.sectionedChanges(to: new), old: old, new: new)
        }
    }

    private func check(_ changes: SectionedChanges, old: [Section], new: [Section]) {
        let deleted = Set(changes.sectionDeletions)
        let inserted = Set(changes.sectionInsertions)
        let context = "\(describe(old)) → \(describe(new))"

        #expect(deleted.allSatisfy { old.indices.contains($0) }, "\(context)")
        #expect(inserted.allSatisfy { new.indices.contains($0) }, "\(context)")
        #expect(old.count - deleted.count == new.count - inserted.count, "\(context)")

        for (newIndex, section) in new.enumerated() where !inserted.contains(newIndex) {
            guard let oldIndex = old.firstIndex(where: { $0.title == section.title }),
                  !deleted.contains(oldIndex) else {
                Issue.record("kept section \(section.title) has no old counterpart: \(context)")
                continue
            }

            let removed = removedItems(changes, oldSection: oldIndex)
            let added = addedItems(changes, newSection: newIndex)
            let survivors = old[oldIndex].children.map(\.id).enumerated()
                .filter { !removed.contains($0.offset) }.map(\.element)
            let fixed = section.children.map(\.id).enumerated().filter { !added.contains($0.offset) }
                .map(\.element)

            #expect(survivors == fixed, "section \(section.title): \(context)")
        }

        let movedTargets = Set(changes.sectionMoves.map(\.to))
        let unmovedOldIndexes = new.enumerated().compactMap { entry -> Int? in
            guard !inserted.contains(entry.offset), !movedTargets.contains(entry.offset) else { return nil }

            return old.firstIndex(where: { $0.title == entry.element.title })
        }
        #expect(
            unmovedOldIndexes == unmovedOldIndexes.sorted(),
            "unmoved sections keep their order: \(context)"
        )
    }

    private func removedItems(_ changes: SectionedChanges, oldSection: Int) -> Set<Int> {
        let deleted = changes.itemDeletions.filter { $0.section == oldSection }.map(\.item)
        let moved = changes.itemMoves.filter { $0.from.section == oldSection }.map(\.from.item)
        return Set(deleted + moved)
    }

    private func addedItems(_ changes: SectionedChanges, newSection: Int) -> Set<Int> {
        let inserted = changes.itemInsertions.filter { $0.section == newSection }.map(\.item)
        let moved = changes.itemMoves.filter { $0.to.section == newSection }.map(\.to.item)
        return Set(inserted + moved)
    }

    private func describe(_ sections: [Section]) -> String {
        sections.map { $0.title + ":" + $0.children.map(\.id).joined() }.joined(separator: " | ")
    }

    private func randomSections(using rng: inout Seeded) -> [Section] {
        let titles = ["A", "B", "C", "D"].shuffled(using: &rng).prefix(Int.random(in: 0 ... 4, using: &rng))
        return titles.map { Section(title: $0, header: 0, children: randomRows(maxCount: 5, using: &rng)) }
    }

    private func mutatedSections(_ old: [Section], using rng: inout Seeded) -> [Section] {
        var result = old.filter { _ in Int.random(in: 0 ..< 5, using: &rng) != 0 }
        result = result.map { section in
            var copy = section
            if Int.random(in: 0 ..< 4, using: &rng) == 0 { copy.header += 1 }
            if Int.random(in: 0 ..< 2, using: &rng) == 0 { copy.children = mutated(
                section.children,
                using: &rng
            ) }
            return copy
        }
        if Bool.random(using: &rng) { result.shuffle(using: &rng) }
        if Int.random(in: 0 ..< 3, using: &rng) == 0, !result.contains(where: { $0.title == "Z" }) {
            result.insert(
                Section(title: "Z", header: 0, children: randomRows(maxCount: 3, using: &rng)),
                at: Int.random(in: 0 ... result.count, using: &rng)
            )
        }
        return result
    }
}

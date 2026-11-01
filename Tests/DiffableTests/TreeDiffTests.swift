import Testing
@testable import Diffable

@Suite("Tree diff")
struct TreeDiffTests {
    @Test("identical trees have no change", arguments: algorithms)
    func identicalTrees(algorithm: DiffAlgorithm) {
        let root = folder("root", file("a"), folder("src", file("b"), folder("deep", file("c"))))
        #expect(root.treeDiff(to: root, algorithm: algorithm).isEmpty)
    }

    @Test("empty forests", arguments: algorithms)
    func emptyForests(algorithm: DiffAlgorithm) {
        #expect([Node]().treeDiff([], algorithm: algorithm).isEmpty)
        #expect([Node]().treeDiff([file("a")], algorithm: algorithm).map(\.kind) == [.insert])
        #expect([file("a")].treeDiff([], algorithm: algorithm).map(\.kind) == [.delete])
    }

    @Test("a nested edit and insert keep the full path", arguments: algorithms)
    func nestedEditAndInsert(algorithm: DiffAlgorithm) {
        let old = folder("root", folder("src", file("a"), folder("util", file("b", size: 1))))
        let new = folder("root", folder("src", file("a"), folder("util", file("b", size: 2), file("c"))))

        let changes = old.treeDiff(to: new, algorithm: algorithm)

        #expect(changes.count == 1)
        #expect(changes[0].kind == .unchanged)
        let util = changes[0].children[0].children[0]
        #expect(util.path == ["root", "src", "util"])
        #expect(util.children.map(\.path) == [["root", "src", "util", "b"], ["root", "src", "util", "c"]])
        #expect(util.children.map(\.kind) == [.update, .insert])
    }

    @Test("a removed folder is ONE entry without its files", arguments: algorithms)
    func removedFolder(algorithm: DiffAlgorithm) {
        let old = folder("root", file("a"), folder("docs", file("x"), file("y")))
        let new = folder("root", file("a"))

        let changes = old.treeDiff(to: new, algorithm: algorithm)

        #expect(changes[0].children.count == 1)
        #expect(changes[0].children[0].kind == .delete)
        #expect(changes[0].children[0].children.isEmpty)
    }

    @Test("an added folder is ONE entry without its files", arguments: algorithms)
    func addedFolder(algorithm: DiffAlgorithm) {
        let old = folder("root", file("a"))
        let new = folder("root", file("a"), folder("docs", file("x"), file("y")))

        let children = old.treeDiff(to: new, algorithm: algorithm)[0].children

        #expect(children.count == 1)
        #expect(children[0].kind == .insert)
        #expect(children[0].children.isEmpty)
    }

    @Test("the same file name in two folders does not collide", arguments: algorithms)
    func sameNameInSiblingFolders(algorithm: DiffAlgorithm) {
        let old = folder("root", folder("a", file("README", size: 1)), folder("b", file("README", size: 1)))
        let new = folder("root", folder("a", file("README", size: 1)), folder("b", file("README", size: 2)))

        let changes = old.treeDiff(to: new, algorithm: algorithm)

        #expect(changes[0].children.count == 1)
        #expect(changes[0].children[0].path == ["root", "b"])
        #expect(changes[0].children[0].children[0].path == ["root", "b", "README"])
    }

    @Test("a file moved to another folder is delete + insert")
    func movedAcrossFolders() {
        let old = folder("root", folder("a", file("x")), folder("b"))
        let new = folder("root", folder("a"), folder("b", file("x")))

        let flat = flatten(old.treeDiff(to: new)).filter { $0.kind != .unchanged }

        #expect(flat.map(\.path) == [["root", "a", "x"], ["root", "b", "x"]])
        #expect(flat.map(\.kind) == [.delete, .insert])
    }

    @Test("a renamed folder is delete + insert, its files are not listed")
    func renamedFolder() {
        let old = folder("root", folder("old", file("a")))
        let new = folder("root", folder("new", file("a")))

        #expect(old.treeDiff(to: new)[0].children.map(\.kind) == [.delete, .insert])
    }

    @Test("reordered siblings are reported as a minimal move with Heckel")
    func reorderedSibling() {
        let old = folder("root", file("a"), file("b"), file("c"))
        let new = folder("root", file("b"), file("c"), file("a"))

        let moved = old.treeDiff(to: new)[0].children

        #expect(moved.count == 1)
        #expect(moved[0].key == "a" && moved[0].movedFrom == 0 && moved[0].index == 2)
    }

    @Test("Myers never reports a move in a tree")
    func myersTreeHasNoMove() {
        let old = folder("root", file("a"), file("b"), file("c"))
        let new = folder("root", file("b"), file("c"), file("a"))

        let flat = flatten(old.treeDiff(to: new, algorithm: .myers))

        #expect(flat.filter { $0.kind != .unchanged }.map(\.kind).sorted { "\($0)" < "\($1)" } == [
            .delete,
            .insert
        ])
    }

    @Test("a folder whose own content AND children changed is an update with children", arguments: algorithms)
    func updatedFolderWithChangedChildren(algorithm: DiffAlgorithm) {
        let old = Node(name: "root", size: 1, children: [file("a", size: 1)])
        let new = Node(name: "root", size: 2, children: [file("a", size: 2)])

        let change = old.treeDiff(to: new, algorithm: algorithm)[0]

        #expect(change.kind == .update)
        #expect(change.children.map(\.kind) == [.update])
    }

    @Test("a moved folder that also has a changed child keeps both facts")
    func movedFolderWithChangedChild() {
        let old = folder("root", folder("a", file("x", size: 1)), file("b"), file("c"))
        let new = folder("root", file("b"), file("c"), folder("a", file("x", size: 2)))

        let moved = old.treeDiff(to: new)[0].children[0]

        #expect(moved.key == "a" && moved.movedFrom == 0)
        #expect(moved.children.map(\.kind) == [.update])
    }

    @Test("a folder that loses all its children")
    func folderBecomesEmpty() {
        let old = folder("root", folder("src", file("a"), file("b")))
        let new = folder("root", folder("src"))

        let src = old.treeDiff(to: new)[0].children[0]

        #expect(src.kind == .unchanged)
        #expect(src.children.map(\.kind) == [.delete, .delete])
        #expect(src.children.map(\.index) == [0, 1])
    }

    @Test("a different root key is delete + insert of the root", arguments: algorithms)
    func rootReplaced(algorithm: DiffAlgorithm) {
        let changes = folder("one", file("a")).treeDiff(to: folder("two", file("a")), algorithm: algorithm)
        #expect(changes.map(\.kind) == [.delete, .insert])
        #expect(changes.map(\.path) == [["one"], ["two"]])
    }

    @Test("a deep tree (100 levels) is handled", arguments: algorithms)
    func deepTree(algorithm: DiffAlgorithm) {
        func chain(depth: Int, leaf: Int) -> Node {
            var node = file("leaf", size: leaf)
            for level in 0 ..< depth {
                node = Node(name: "d\(level)", children: [node])
            }
            return node
        }

        let changes = chain(depth: 100, leaf: 1).treeDiff(
            to: chain(depth: 100, leaf: 2),
            algorithm: algorithm
        )

        let flat = flatten(changes)
        #expect(flat.count == 101)
        #expect(flat.last?.kind == .update)
        #expect(flat.last?.path.count == 101)
    }

    @Test("a wide folder (5000 files, 3 edits)", arguments: algorithms)
    func wideFolder(algorithm: DiffAlgorithm) {
        let files = (0 ..< 5_000).map { file("f\($0)") }
        var edited = files
        edited[10].size = 9
        edited.remove(at: 2_000)
        edited.append(file("extra"))

        let kinds = Node(name: "root", children: files).treeDiff(
            to: Node(name: "root", children: edited),
            algorithm: algorithm
        )[0].children.map(\.kind)

        #expect(kinds.sorted { "\($0)" < "\($1)" } == [.delete, .insert, .update])
    }

    @Test("indexes: delete = OLD sibling index, others = NEW sibling index")
    func indexSemantics() {
        let old = folder("root", file("a"), file("b"), file("c"))
        let new = folder("root", file("b"), file("c"), file("d"))

        let children = old.treeDiff(to: new)[0].children

        #expect(children.map(\.kind) == [.delete, .insert])
        #expect(children.map(\.index) == [0, 2])
    }

    @Test("a leaf that becomes a folder")
    func leafBecomesFolder() {
        let old = folder("root", file("x"))
        let new = folder("root", Node(name: "x", size: 1, children: [file("y")]))

        let x = old.treeDiff(to: new)[0].children[0]

        #expect(x.kind == .unchanged)
        #expect(x.children.map(\.path) == [["root", "x", "y"]])
    }

    @Test("the outline reads like a diff")
    func outline() {
        let old = folder("root", folder("src", file("b", size: 1)), folder("docs", file("x")))
        let new = folder("root", folder("src", file("b", size: 2), file("c")))

        let text = old.treeDiff(to: new).map(\.description).joined(separator: "\n")

        #expect(text == """
        = root
          - docs
          = src
            ~ b
            + c
        """)
    }

    @Test("the outline shows moves")
    func outlineShowsMoves() {
        let text = folder("r", file("a"), file("b")).treeDiff(to: folder("r", file("b"), file("a")))
            .map(\.description).joined(separator: "\n")
        #expect(text.contains("(moved from"))
    }
}

@Suite("Tree diff randomized")
struct TreeRandomizedTests {
    @Test("the reported changes match a path-based oracle", arguments: algorithms)
    func matchesOracle(algorithm: DiffAlgorithm) {
        var generator = SeededGenerator(seed: 21)
        for _ in 0 ..< 1_500 {
            let old = randomTree(depth: 3, using: &generator)
            let new = mutateTree(old, depth: 3, shuffle: algorithm == .heckel, using: &generator)

            let oldPaths = flatten(old)
            let newPaths = flatten(new)
            var expected = Set<String>()
            for (path, size) in oldPaths
                where newPaths[path] == nil && (path.count == 1 || newPaths[Array(path.dropLast())] != nil) {
                expected.insert("delete \(path)")
                _ = size
            }
            for path in newPaths.keys
                where oldPaths[path] == nil && (path.count == 1 || oldPaths[Array(path.dropLast())] != nil) {
                expected.insert("insert \(path)")
            }
            for (path, size) in newPaths where oldPaths[path] != nil && oldPaths[path] != size {
                expected.insert("update \(path)")
            }

            let actual = Set(flatten(old.treeDiff(new, algorithm: algorithm))
                .compactMap { change -> String? in
                    switch change.kind {
                    case .insert: return "insert \(change.path)"
                    case .delete: return "delete \(change.path)"
                    case .update: return "update \(change.path)"
                    case .unchanged: return nil
                    }
                })

            #expect(actual == expected, "\(algorithm)")
        }
    }

    @Test("a tree diffed with itself is empty", arguments: algorithms)
    func selfDiff(algorithm: DiffAlgorithm) {
        var generator = SeededGenerator(seed: 22)
        for _ in 0 ..< 300 {
            let tree = randomTree(depth: 3, using: &generator)
            #expect(tree.treeDiff(tree, algorithm: algorithm).isEmpty)
        }
    }
}

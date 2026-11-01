import Foundation

/// Paul Heckel's linear-time diff ("A technique for isolating differences between files", 1978).
///
/// Heckel identifies items by key (`Diffable.id`) with a hash table, so it runs in O(n)
/// and, unlike Myers, it natively detects **moves**.
///
/// ## The five passes
///
/// ```
///  old: [ A  B  C  D ]          new: [ B  C  D  A ]
///          0  1  2  3                   0  1  2  3
///
///  Pass 1  count every key of `new`          table: A(new 1) B(new 1) C(new 1) D(new 1)
///  Pass 2  count every key of `old`          table: A(old 1) B(old 1) C(old 1) D(old 1)
///
///  Pass 2b items identical at the very start / end of both arrays are linked right away
///          (this is what makes [a a a] vs [a a a] an empty diff despite the duplicates)
///
///  Pass 3  a key seen exactly ONCE on each side is the same item (an "anchor"):
///
///            old   A   B   C   D
///                  |\   \   \   \
///                  | \   \   \   \          every anchor links old[j] <-> new[i]
///                  |  \---\---\---\--+
///                  |       \   \   \ |
///            new   B   C   D   A  <--+
///
///  Pass 4  walk new ascending: if new[i] <-> old[j] and the NEXT entries are the same
///          key, link them too   (grows blocks of unchanged items towards the right)
///  Pass 5  same, walking descending (grows blocks towards the left)
///
///  Result  new[i] linked to old[j]  -> unchanged / updated / moved
///          old[j] never linked      -> DELETE
///          new[i] never linked      -> INSERT
/// ```
///
/// Keys that appear several times are *not* anchors (pass 3 requires exactly one occurrence per side);
/// they only get linked when they sit next to an anchor (passes 4 and 5), otherwise they are
/// reported as delete + insert.
///
/// ## Detecting moves (longest increasing subsequence)
///
/// Linked items form a list of old indexes read in `new` order. Items that already are in
/// increasing order did not move; the others did. Keeping the *longest* increasing run unmoved
/// reports the minimum number of moves:
///
/// ```
///  old indexes in new order:   1  2  3  0          LIS = 1 2 3   ->   only item "0" moved
///
///  old: [ A  B  C  D ]   new: [ B  C  D  A ]       => 1 move  (A: 0 -> 3)
///                                                      not 4 moves (one per shifted item)
/// ```
///
/// ## Index spaces of the produced `DiffStep`s
///
/// ```
///  delete(index)        index in the OLD array
///  insert(index)        index in the NEW array
///  update(index)        index in the NEW array
///  move(from, to)       from in the OLD array, to in the NEW array
/// ```
///
/// - Complexity: O(n) time and memory for the passes, O(n log n) for the move detection.
/// - Not guaranteed to produce the *shortest* script. See `Myers` for that.
struct Heckel {
    private var oldReferences: [Reference] = []
    private var newReferences: [Reference] = []
    private var table: [AnyHashable: Reference.Symbol] = [:]

    /// A reference to an entry in the array, can either be a pointer (a change) or an index (unchanged)
    enum Reference {
        /// - pointer: A pointer to a symbol in the list of entries. This is used to identify changes.
        case pointer(Symbol)

        /// - index: An index reference. This is used to signify things which have not changed.
        case index(Int)

        /// A reference symbol: one per distinct key.
        class Symbol {
            /// The count of the symbol in the old array
            var oldCount: Count = .zero

            /// The count of the symbol in the new array
            var newCount: Count = .zero

            /// The reference indexes in the old array
            var oldLineReferenceIndexes: [Int] = []

            /// true if the symbol occurs exactly once in each array (an anchor).
            var isUnique: Bool {
                oldCount == .one && newCount == .one
            }
        }
    }

    enum Count {
        /// - zero: equivalent to 0
        case zero

        /// - one: equivalent to 1
        case one

        /// - many: equivalent to anything larger than 1
        case many

        /// Advance to to the next value.
        ///
        /// zero -> one
        /// one -> many
        mutating func next() {
            switch self {
            case .zero:
                self = .one
            case .one:
                self = .many
            case .many:
                break
            }
        }
    }

    /// Process the old and new array to produce a list of diff steps.
    ///
    /// - Parameters:
    ///   - old: The array to compare.
    ///   - new: The array to compare against.
    /// - Returns: A list of DiffStep operations to perform on the old array to get the new array.
    mutating func process<T: Diffable>(old: [T], new: [T]) -> [DiffStep<T>] {
        setupContext(old: old, new: new)

        var steps: [DiffStep<T>] = []

        for (index, reference) in oldReferences.enumerated() {
            if case .pointer = reference {
                steps.append(.delete(index: index, value: old[index]))
            }
        }

        var matches: [(oldIndex: Int, newIndex: Int)] = []

        for (index, reference) in newReferences.enumerated() {
            switch reference {
            case .pointer:
                steps.append(.insert(index: index, value: new[index]))
            case let .index(oldIndex):
                matches.append((oldIndex: oldIndex, newIndex: index))
                if old[oldIndex] != new[index] {
                    steps.append(.update(index: index, value: new[index]))
                }
            }
        }

        let unmoved = Heckel.longestIncreasingSubsequence(matches.map { $0.oldIndex })

        for (position, match) in matches.enumerated() where !unmoved.contains(position) {
            steps.append(.move(from: match.oldIndex, to: match.newIndex, value: new[match.newIndex]))
        }

        return steps
    }

    /// Positions (not values) of one longest strictly increasing subsequence of `values`.
    ///
    /// Patience sorting with binary search, O(n log n).
    ///
    /// ```
    ///  values:  1  2  3  0
    ///  tails:   [1] -> [1,2] -> [1,2,3] -> [0,2,3]      length 3, positions {0,1,2}
    /// ```
    static func longestIncreasingSubsequence(_ values: [Int]) -> Set<Int> {
        var tails: [Int] = []
        var previous = [Int?](repeating: nil, count: values.count)

        for (position, value) in values.enumerated() {
            var low = 0
            var high = tails.count
            while low < high {
                let middle = (low + high) / 2
                if values[tails[middle]] < value {
                    low = middle + 1
                } else {
                    high = middle
                }
            }
            previous[position] = low > 0 ? tails[low - 1] : nil
            if low == tails.count {
                tails.append(position)
            } else {
                tails[low] = position
            }
        }

        var result = Set<Int>()
        var current = tails.last
        while let position = current {
            result.insert(position)
            current = previous[position]
        }
        return result
    }

    /// Setup the context for the diffing operation by running Heckel's five passes (see the type
    /// documentation).
    ///
    /// - Parameters:
    ///   - old: The array to compare.
    ///   - new: The array to compare against.
    private mutating func setupContext<T: Diffable>(old: [T], new: [T]) {
        table = [:]

        // First pass
        newReferences = makeTableReferences(with: new, counter: { $0.newCount.next() })

        // Second pass
        oldReferences = makeTableReferences(
            with: old,
            updateLineReference: true,
            counter: { $0.oldCount.next() }
        )

        // Common prefix and suffix
        linkCommonEnds(old: old, new: new)

        // Third pass
        findUniqueEntries()

        // Fourth pass
        expandUniqueEntries(direction: .ascending)

        // Fifth pass
        expandUniqueEntries(direction: .descending)
    }

    /// Generate table entries for the array, if updateLineReference is true the oldLineReferenceIndexes are
    /// also populated.
    ///
    /// First & Second pass
    ///
    /// - Parameters:
    ///   - array: The array calee to generate refernces for.
    ///   - updateLineReference: true if the oldLineReferenceIndexes should be updated
    ///   - counter: A function used to increase the counter for the reference symbol.
    /// - Returns: A list of symbol references for array `array`.
    private mutating func makeTableReferences<T: Diffable>(
        with array: [T],
        updateLineReference: Bool = false,
        counter: (Reference.Symbol) -> Void
    ) -> [Reference] {
        var entries: [Reference] = []

        for (index, item) in array.enumerated() {
            let key = AnyHashable(item.id)
            let entry = table[key] ?? Reference.Symbol()

            table[key] = entry

            counter(entry)

            if updateLineReference {
                entry.oldLineReferenceIndexes.append(index)
            }

            entries.append(.pointer(entry))
        }

        return entries
    }

    /// Links the items that are identical at the start and at the end of both arrays.
    ///
    /// ```
    ///  old: [ a  a  a  x ]        prefix  a a a  -> linked one to one
    ///  new: [ a  a  a  y ]        suffix  (none)
    /// ```
    ///
    /// Duplicated keys are never anchors in pass 3, so without this step `[a a a]` vs `[a a a]`
    /// would be reported as three deletions and three insertions.
    private mutating func linkCommonEnds<T: Diffable>(old: [T], new: [T]) {
        func link(old oldIndex: Int, new newIndex: Int) {
            newReferences[newIndex] = .index(oldIndex)
            oldReferences[oldIndex] = .index(newIndex)
        }

        var prefix = 0
        while prefix < old.count, prefix < new.count, AnyHashable(old[prefix].id) == AnyHashable(new[prefix].id) {
            link(old: prefix, new: prefix)
            prefix += 1
        }

        var oldIndex = old.count - 1
        var newIndex = new.count - 1
        while oldIndex >= prefix, newIndex >= prefix,
              AnyHashable(old[oldIndex].id) == AnyHashable(new[newIndex].id) {
            link(old: oldIndex, new: newIndex)
            oldIndex -= 1
            newIndex -= 1
        }
    }

    /// Third pass: link the keys that occur exactly once in each array.
    private mutating func findUniqueEntries() {
        for (index, reference) in newReferences.enumerated() {
            guard case let .pointer(entry) = reference,
                  entry.isUnique,
                  let oldIndex = entry.oldLineReferenceIndexes.first else {
                continue
            }

            newReferences[index] = .index(oldIndex)
            oldReferences[oldIndex] = .index(index)
        }
    }

    /// An enumeration to specify the direction of the traversal of references.
    enum ReferenceWalker {
        /// - ascending: Walk the references in ascending order.
        case ascending

        /// - descending: Walk the references in decending order.
        case descending

        /// The starting value of the walk.
        ///
        /// - Parameter references: The references which are being walked.
        /// - Returns: The start index.
        func start(references: [Reference]) -> Int {
            switch self {
            case .ascending:
                0
            case .descending:
                references.count - 1
            }
        }

        /// The step increase when walking references.
        var step: Int {
            switch self {
            case .ascending:
                1
            case .descending:
                -1
            }
        }

        /// Compare the index with the list of indexes to ensure it is valid.
        ///
        /// - Parameters:
        ///   - i: the index to validate
        ///   - references: The array of references, the count of these determines if the traversal is still
        /// valid.
        /// - Returns: true if the traversal is still valid.
        func isValid(i: Int, references: [Reference]) -> Bool {
            switch self {
            case .ascending:
                i < references.count - 1
            case .descending:
                i > 0
            }
        }

        /// Determine if the index is in range and can be continued.
        ///
        /// - Parameters:
        ///   - i: the index to validate
        ///   - references: The array of references, the count of these determines if the traversal is still
        /// valid.
        /// - Returns: true if the index is in range.
        func inRange(i: Int, references: [Reference]) -> Bool {
            switch self {
            case .ascending:
                i + step < references.count
            case .descending:
                i + step >= 0
            }
        }
    }

    /// Fourth & Fifth pass
    ///
    /// ```
    ///  ascending                       descending
    ///
    ///  new[i] <-> old[j]               new[i] <-> old[j]
    ///  new[i+1] ?= old[j+1]            new[i-1] ?= old[j-1]
    ///  same symbol => link them        same symbol => link them
    /// ```
    ///
    /// - Parameter direction: The direction to walk, ascending or descending
    private mutating func expandUniqueEntries(direction: ReferenceWalker) {
        var i = direction.start(references: newReferences)

        while direction.isValid(i: i, references: newReferences) {
            if case let .index(j) = newReferences[i], direction.inRange(i: j, references: oldReferences) {
                if case let .pointer(new) = newReferences[i + direction.step],
                   case let .pointer(old) = oldReferences[j + direction.step], new === old {
                    newReferences[i + direction.step] = .index(j + direction.step)
                    oldReferences[j + direction.step] = .index(i + direction.step)
                }
            }
            i += direction.step
        }
    }
}

/// A description of a step to apply to an array to be able to transform one into the other.
///
/// See `Heckel` for the index space of each case.
enum DiffStep<T: Diffable>: CustomDebugStringConvertible {
    /// - insert: A insertation step.
    case insert(index: Int, value: T)

    /// - delete: A deletion step.
    case delete(index: Int, value: T)

    /// - move: A move step.
    case move(from: Int, to: Int, value: T)

    /// update: A update step.
    case update(index: Int, value: T)

    var debugDescription: String {
        switch self {
        case let .insert(idx, value):
            "+\(idx)@\(value)"
        case let .delete(idx, value):
            "-\(idx)@\(value)"
        case let .move(from, to, value):
            "\(from)>\(to)@\(value)"
        case let .update(idx, value):
            "!\(idx)@\(value)"
        }
    }
}

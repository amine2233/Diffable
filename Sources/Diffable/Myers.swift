import Foundation

/// Eugene Myers' O(ND) diff ("An O(ND) difference algorithm and its variations", 1986),
/// the algorithm behind `git diff` and Swift's `CollectionDifference`.
///
/// It finds the **shortest edit script** (fewest inserts + deletes) between two arrays.
/// It does not detect moves: a moved item is one delete plus one insert.
///
/// ## The edit graph
///
/// Put `old` on the x axis and `new` on the y axis. Every path from the top-left corner
/// to the bottom-right corner is an edit script:
///
/// ```
///          old:   A     B     C
///               0     1     2     3
///          new  +-----+-----+-----+
///           B   |  \  |     |     |      right  (x+1) = delete old[x]       cost 1
///               +-----+-----+-----+      down   (y+1) = insert new[y]       cost 1
///           C   |     |  \  |     |      diag   (x+1,y+1) = same key, free  cost 0
///               +-----+-----+-----+
///           D   |     |     |     |
///               +-----+-----+-----+
/// ```
///
/// Example `[A B C] -> [B C D]`: delete A (right), follow the two diagonals B and C,
/// insert D (down). `D = 2` edits is the shortest possible.
///
/// ## How it searches
///
/// Diagonals are numbered `k = x - y`. For each edit budget `d = 0, 1, 2 ...` the algorithm keeps,
/// per diagonal, the furthest `x` reachable with exactly `d` edits (the array `V`), extending each
/// point along free diagonals ("snakes") as far as possible:
///
/// ```
///   d=0   k=0           ----snake--->
///   d=1   k=-1, k=1
///   d=2   k=-2, 0, 2     ... stop at the first d that reaches (N, M)
/// ```
///
/// A copy of `V` is saved at every `d` (the "trace"); walking the trace backwards from `(N, M)`
/// recovers which edits were taken.
///
/// ## Output
///
/// - `delete(index)`: index in the OLD array
/// - `insert(index)`: index in the NEW array
/// - `update(index)`: index in the NEW array, for a kept item whose content changed (`old != new`)
/// - never `move`
///
/// - Complexity: O((N+M)·D) time, O(D·(N+M)) memory, where D is the number of edits.
///   Great when the arrays are similar, heavy when they are completely different and huge.
/// - Items are matched by `Diffable.id`; with duplicate keys it matches them in order.
struct Myers {
    func process<T: Diffable>(old: [T], new: [T]) -> [DiffStep<T>] {
        let oldKeys = old.map { AnyHashable($0.id) }
        let newKeys = new.map { AnyHashable($0.id) }
        let oldCount = oldKeys.count
        let newCount = newKeys.count

        guard oldCount + newCount > 0 else {
            return []
        }

        let offset = oldCount + newCount
        let trace = shortestEditTrace(old: oldKeys, new: newKeys, offset: offset)

        var deleted: [Int] = []
        var inserted: [Int] = []
        var matches: [(oldIndex: Int, newIndex: Int)] = []

        var x = oldCount
        var y = newCount

        for d in stride(from: trace.count - 1, through: 0, by: -1) {
            let v = trace[d]
            let k = x - y
            let cameFromAbove = k == -d || (k != d && v[offset + k - 1] < v[offset + k + 1])
            let previousK = cameFromAbove ? k + 1 : k - 1
            let previousX = v[offset + previousK]
            let previousY = previousX - previousK

            while x > previousX, y > previousY {
                x -= 1
                y -= 1
                matches.append((oldIndex: x, newIndex: y))
            }

            if d > 0 {
                if x == previousX {
                    inserted.append(previousY)
                } else {
                    deleted.append(previousX)
                }
            }

            x = previousX
            y = previousY
        }

        var steps: [DiffStep<T>] = []

        for index in deleted.sorted() {
            steps.append(.delete(index: index, value: old[index]))
        }
        for index in inserted.sorted() {
            steps.append(.insert(index: index, value: new[index]))
        }
        for match in matches.sorted(by: { $0.newIndex < $1.newIndex })
            where old[match.oldIndex] != new[match.newIndex] {
            steps.append(.update(index: match.newIndex, value: new[match.newIndex]))
        }

        return steps
    }

    /// Runs the forward search and returns `V` as it was at the start of every round `d`.
    ///
    /// `V[offset + k]` is the furthest x reached on diagonal `k`; `offset` shifts negative diagonals to valid
    /// indexes.
    private func shortestEditTrace(old: [AnyHashable], new: [AnyHashable], offset: Int) -> [[Int]] {
        let oldCount = old.count
        let newCount = new.count
        var v = Array(repeating: 0, count: 2 * offset + 2)
        var trace: [[Int]] = []

        for d in 0 ... offset {
            trace.append(v)

            for k in stride(from: -d, through: d, by: 2) {
                var x: Int = if k == -d || (k != d && v[offset + k - 1] < v[offset + k + 1]) {
                    v[offset + k + 1]
                } else {
                    v[offset + k - 1] + 1
                }
                var y = x - k

                while x < oldCount, y < newCount, old[x] == new[y] {
                    x += 1
                    y += 1
                }

                v[offset + k] = x

                if x >= oldCount, y >= newCount {
                    return trace
                }
            }
        }

        return trace
    }
}

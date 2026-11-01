import Foundation

/// An element that can be compared by the diff algorithms.
///
/// Two pieces of information drive every diff, and they come from two different places:
///
/// ```
///                 IDENTITY                          CONTENT
///        "is it the same item?"             "did the item change?"
///        ----------------------             ----------------------
///        primaryKeyValue / diffIdentity     Hashable (== / hash)
///
///   old: [ A(id 1, "x") ]              same identity (id 1)
///   new: [ A(id 1, "y") ]     ==>      different content  ==>  UPDATE
///
///   old: [ A(id 1) ]                   identity only in old  ==>  DELETE
///   new: [ A(id 2) ]                   identity only in new  ==>  INSERT
/// ```
///
/// - `primaryKeyValue` must be stable and unique among siblings (a database id, a file name...).
/// - `==` must compare the *content* you want to detect changes on.
public protocol Diffable: Hashable {
    /// The stable identity of the element, unique inside one array of siblings.
    var primaryKeyValue: String { get }

    /// The identity actually used by the algorithms.
    ///
    /// Defaults to `primaryKeyValue`. Type-erasing wrappers such as `AnyDiffable` override it
    /// to add the wrapped type, so `Article(42)` and `Video(42)` are never mistaken for each other.
    var diffIdentity: AnyHashable { get }
}

extension Diffable {
    /// The default identity: the `primaryKeyValue`.
    public var diffIdentity: AnyHashable {
        primaryKeyValue
    }
}

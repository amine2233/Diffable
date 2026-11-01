import Foundation

/// An element that can be compared by the diff algorithms.
///
/// `Diffable` is `Identifiable` and `Hashable`. Two pieces of information drive every diff, and they come
/// from two different places:
///
/// ```
///                 IDENTITY                          CONTENT
///        "is it the same item?"             "did the item change?"
///        ----------------------             ----------------------
///        Identifiable.id                    Hashable (== / hash)
///
///   old: [ A(id 1, "x") ]              same identity (id 1)
///   new: [ A(id 1, "y") ]     ==>      different content  ==>  UPDATE
///
///   old: [ A(id 1) ]                   identity only in old  ==>  DELETE
///   new: [ A(id 2) ]                   identity only in new  ==>  INSERT
/// ```
///
/// - `id` must be stable and unique among siblings (a database id, a UUID, a file name...). Any `Hashable` and
///   `Sendable` type works (`String`, `Int`, `UUID`...), and a model that already is `Identifiable` only has to
///   add `Diffable`.
/// - `==` must compare the *content* you want to detect changes on.
///
/// ```swift
/// struct Product: Diffable {
///     let id: String
///     var quantity: Int
/// }
/// ```
public protocol Diffable: Hashable, Identifiable where ID: Sendable {}

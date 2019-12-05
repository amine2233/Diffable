//
//  AnyDiffable.swift
//  Diffable
//
//  Created by Amine Bensalah on 05/12/2019.
//

import Foundation

/// A type-erased diffable value.
/// The AnyDiffable type forwards diffing, equality comparisons and hashing operations to an underlying diffing value,
/// hiding its specific underlying type.
///
/// let items: [AnyDiffable] = [
///    AnyDiffable(article),
///    AnyDiffable(video),
///    AnyDiffable(advert)
/// ]
///
public struct AnyDiffable: Diffable {

    private let _primaryKeyValue: () -> String

    /// The value wrapped by this instance.
    /// The base property can be cast back to its original type using one of the casting operators (as?, as!, or as).
    var base: AnyHashable

    /// Creates a type-erased diffable value that wraps the given instance.
    ///
    /// The following example creates two type-erased diffable values: x wraps an Article with the value 42, while y wraps a Video with the same identifier value.
    /// Because the underlying types of x and y are different, the two variables do not compare as equal despite having equal underlying values.
    ///
    /// let x = AnyDiffable(Article(identifier: 42))
    /// let y = AnyDiffable(Video(identifier: 42))
    ///
    /// print(x == y)
    /// Prints "false" because `Article` and `Video` are different types
    ///
    /// print(x == AnyDiffable(Article(identifier: 42)))
    /// Prints "true"
    ///
    public init<D: Diffable>(_ base: D) {
        self.base = base
        _primaryKeyValue = { base.primaryKeyValue }
    }

    /// The primaryKeyValue value
    public var primaryKeyValue: String {
        return _primaryKeyValue()
    }
}

extension AnyDiffable: Equatable {
    /// Returns a Boolean value indicating whether two type-erased diffable instances wrap the same type and value.
    ///
    /// Two instances of AnyDiffable compare as equal if and only if the underlying types have the same conformance
    /// to the Equatable protocol and the underlying values compare as equal.
    ///
    /// The following example creates two type-erased diffable values: x wraps an Article with identifier 42,
    /// while y wraps a Video with the same identifier value. Because the underlying types of x and y are different,
    /// the two variables do not compare as equal despite having equal underlying values.
    ///
    /// ```
    /// let x = AnyDiffable(Article(identifier: 42))
    /// let y = AnyDiffable(Video(identfier: 42))
    ///
    /// print(x == y)
    /// // Prints "false" because `Video` and `Article` are different types
    ///
    /// print(x == AnyDiffable(Article(identifier: 42)))
    /// // Prints "true"
    /// ```
    ///
    /// - Parameters:
    ///   - x: A type-erased diffable value.
    ///   - y: A type-erased diffable value.
    /// - Returns: a Boolean value indicating whether two values are equal.
    public static func == (x: AnyDiffable, y: AnyDiffable) -> Bool {
        return x.base == y.base
    }
}

extension AnyDiffable: Hashable {

    /// The hash value.
    /// Axiom: x == y implies x.hashValue == y.hashValue.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}

extension AnyDiffable {

    /// Evaluates the given closure when this `AnyDiffable` instance is type `T`,
    /// passing the unwrapped value as a parameter.
    ///
    /// Use the `map` method with a closure that returns a nonoptional value.
    ///
    /// - Parameter transform: A closure that takes the unwrapped value of the instance.
    /// - Returns: The result of the given closure. If this instance is not type T, returns `self`.
    public func map<T: Diffable, U: Diffable>(_ transform: (T) throws -> U) rethrows -> AnyDiffable {
        guard let object = base as? T else {
            return self
        }
        return try AnyDiffable(transform(object))
    }

    /// Evaluates the given closure when this `AnyDiffable` value instance is of type T,
    /// passing the unwrapped value as a parameter.
    ///
    /// - Parameter transform: A closure that takes the unwrapped value of the instance.
    /// - Returns: The result of the given closure.
    public func flatMap<T: Diffable>(_ transform: (T) throws -> AnyDiffable) rethrows -> AnyDiffable {
        guard let object = base as? T else {
            return self
        }
        return try transform(object)
    }

    /// Evaluates the given closure when this `AnyDiffable` instance is not `nil`,
    /// passing the unwrapped value as a parameter.
    ///
    /// Use the `apply` method with an optional closure that returns a nonoptional value.
    ///
    /// - Parameter transform: A closure that takes the unwrapped value
    ///   of the instance.
    /// - Returns: The result of the given closure. If the closure is `nil`,
    ///   returns `nil`.
    public func apply<T: Diffable, U: Diffable>(transform: ((T) throws -> U)?) throws -> AnyDiffable? {
        return try transform.flatMap(map)
    }
}

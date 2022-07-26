import Foundation

public protocol Diffable: Hashable {
    var primaryKeyValue: String { get }
}

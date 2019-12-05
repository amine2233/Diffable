//
//  Diffable.swift
//  Diffable
//
//  Created by Amine Bensalah on 05/12/2019.
//

import Foundation

public protocol Diffable: Hashable {

    var primaryKeyValue: String { get }

}

//
//  PersistFetchRequest.swift
//  RetsTalk
//
//  Created on 11/25/24.
//

import Foundation

struct PersistFetchRequest<Entity: EntityRepresentable>: PersistFetchRequestable {
    var predicate: CustomPredicate?
    var sortDescriptors: [CustomSortDescriptor]
    var fetchLimit: Int
    var fetchOffset: Int
    
    init(
        predicate: CustomPredicate? = nil,
        sortDescriptors: [CustomSortDescriptor] = [],
        fetchLimit: Int = 1,
        fetchOffset: Int = 0
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fetchLimit = fetchLimit
        self.fetchOffset = fetchOffset
    }
}

struct CustomPredicate: Sendable {
    let format: String
    let argumentArray: [any Sendable]
    
    var nsPredicate: NSPredicate {
        NSPredicate(format: format, argumentArray: argumentArray)
    }
}

struct CustomSortDescriptor {
    let key: String
    let ascending: Bool
    
    var nsSortDescriptor: NSSortDescriptor {
        NSSortDescriptor(key: key, ascending: ascending)
    }
}

//
//  Retrospect+Query.swift
//  RetsTalk
//
//  Created on 3/11/25.
//

import Foundation

extension Retrospect {
    
    // MARK: Predicates
    
    static let pinnedPredicate = CustomPredicate(
        format: "isPinned = %@",
        argumentArray: [true]
    )
    static let inProgressPredicate = CustomPredicate(
        format: "status != %@",
        argumentArray: [State.finished.rawValue]
    )
    static let finishedPredicate = CustomPredicate(
        format: "status = %@ AND isPinned = %@",
        argumentArray: [State.finished.rawValue, false]
    )
    
    static func monthlyPredicate(baseOn date: Date) -> CustomPredicate? {
        guard let year = date.toDateComponents.year,
              let month = date.toDateComponents.month,
              let startOfMonth = Date.startOfMonth(year: year, month: month),
              let startOfNextMonth = Date.startOfMonth(
                year: month == 12 ? year + 1 : year,
                month: month == 12 ? 1 : month + 1
              )
        else { return nil }
        
        let predicate = CustomPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            argumentArray: [startOfMonth, startOfNextMonth]
        )
        return predicate
    }
    
    static func matchingRetorspect(id: UUID) -> CustomPredicate {
        CustomPredicate(format: "retrospectID = %@", argumentArray: [id])
    }
    
    // MARK: SortDescriptor
    
    static let lastest = CustomSortDescriptor(key: "createdAt", ascending: false)
}

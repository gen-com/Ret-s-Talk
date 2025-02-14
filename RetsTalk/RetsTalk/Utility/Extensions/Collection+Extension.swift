//
//  Collection+Extension.swift
//  RetsTalk
//
//  Created on 11/17/24.
//

extension Collection {
    var isNotEmpty: Bool {
        !isEmpty
    }
}

extension Collection where Element: Equatable {
    func notContains(_ element: Element) -> Bool {
        !contains(element)
    }
}

//
//  RetrospectList.swift
//  RetsTalk
//
//  Created on 3/12/25.
//

struct RetrospectList {
    
    // MARK: Properties
    
    private var retrospects: [Retrospect]
    private(set) var count: Count
    
    // MARK: Initialization
    
    init(count: Count = Count(total: 0, monthly: 0), retrospects: [Retrospect] = []) {
        self.count = count
        self.retrospects = retrospects
    }
    
    // MARK: List
    
    var pinned: [Retrospect] {
        retrospects.filter { $0.isPinned }
    }
    var inProgress: [Retrospect] {
        retrospects.filter { $0.state != .finished }
    }
    var finished: [Retrospect] {
        retrospects.filter { !$0.isPinned && $0.state == .finished }
    }
    
    // MARK: Mutating methods
    
    mutating func updateCount(total: Int, monthly: Int) {
        count.total = total
        count.monthly = monthly
    }
    
    func retrospect(matching retrospect: Retrospect) -> Retrospect? {
        retrospects.first(where: { $0.id == retrospect.id })
    }
    
    mutating func append(contentsOf retrospects: [Retrospect]) {
        for retrospect in retrospects where self.retrospects.notContains(retrospect) {
            self.retrospects.append(retrospect)
        }
    }
    
    mutating func updateRetrospect(to updated: Retrospect) {
        guard let sourceIndex = retrospects.firstIndex(where: { $0.id == updated.id }) else { return }
        
        retrospects[sourceIndex] = updated
        retrospects[sourceIndex].removeAllChat()
    }
    
    mutating func deleteRetrospect(_ retrospect: Retrospect) {
        retrospects.removeAll(where: { $0.id == retrospect.id })
    }
}

// MARK: - Nested type

extension RetrospectList {
    struct Count: Hashable {
        var total: Int
        var monthly: Int
    }
}

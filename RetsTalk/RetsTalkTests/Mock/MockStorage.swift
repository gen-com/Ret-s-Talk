//
//  MockStorage.swift
//  RetsTalkTests
//
//  Created by KimMinSeok on 11/20/24.
//

import Foundation

actor MockStorage: Persistable {
    private var dictionaryListByEntityName: [String: [[String: Any]]] = [:]
    private let failingOperations: Set<Operation>
    
    // MARK: Initialization
    
    init(failingOperations: Set<Operation> = []) {
        self.failingOperations = failingOperations
    }
    
    // MARK: Persistable conformance
    
    func add<Entity>(contentsOf entities: [Entity]) throws -> [Entity] where Entity: EntityRepresentable {
        try failIfNeeded(for: .add)
        
        dictionaryListByEntityName[Entity.entityName, default: []] += entities.map({ $0.mappingDictionary })
        return entities
    }
    
    func fetch<Entity>(
        by request: any PersistFetchRequestable<Entity>
    ) throws -> [Entity] where Entity: EntityRepresentable {
        try failIfNeeded(for: .fetch)
        
        let matchingList = matchingDictionaryList(named: Entity.entityName, predicate: request.predicate)
        let sortDescriptors = request.sortDescriptors.map({ $0.nsSortDescriptor })
        let sortedList = (matchingList as NSArray).sortedArray(using: sortDescriptors)
            .compactMap({ $0 as? [String: Any] })
            .dropFirst(request.fetchOffset)
        let limitedList = request.fetchLimit == .zero ? Array(sortedList) : Array(sortedList.prefix(request.fetchLimit))
        return try limitedList.map({ try Entity(dictionary: $0) })
    }
    
    func fetchDataCount<Entity>(
        by request: any PersistFetchRequestable<Entity>
    ) throws -> Int where Entity: EntityRepresentable {
        try failIfNeeded(for: .count)
        
        return matchingDictionaryList(named: Entity.entityName, predicate: request.predicate).count
    }
    
    func update<Entity>(
        from sourceEntity: Entity,
        to updatingEntity: Entity
    ) throws -> Entity where Entity: EntityRepresentable {
        try failIfNeeded(for: .update)
        
        let predicate = identifyingPredicate(of: sourceEntity)
        let updatingDictionary = updatingEntity.mappingDictionary
        let dictionaryList = dictionaryListByEntityName[Entity.entityName, default: []]
        dictionaryListByEntityName[Entity.entityName] = dictionaryList.map({
            predicate.evaluate(with: $0) ? updatingDictionary : $0
        })
        return updatingEntity
    }
    
    func delete<Entity>(contentsOf entities: [Entity]) throws where Entity: EntityRepresentable {
        try failIfNeeded(for: .delete)
        
        for entity in entities {
            let predicate = identifyingPredicate(of: entity)
            dictionaryListByEntityName[Entity.entityName]?.removeAll(where: { predicate.evaluate(with: $0) })
        }
    }
    
    func delete<Entity>(
        by request: any PersistFetchRequestable<Entity>
    ) throws where Entity: EntityRepresentable {
        try failIfNeeded(for: .delete)
        guard let predicate = request.predicate?.nsPredicate else { throw TestError.custom }
        
        dictionaryListByEntityName[Entity.entityName]?.removeAll(where: { predicate.evaluate(with: $0) })
    }
    
    // MARK: Supporting methods
    
    private func failIfNeeded(for operation: Operation) throws {
        if failingOperations.contains(operation) { throw TestError.custom }
    }
    
    private func matchingDictionaryList(named entityName: String, predicate: CustomPredicate?) -> [[String: Any]] {
        let dictionaryList = dictionaryListByEntityName[entityName, default: []]
        guard let predicate = predicate?.nsPredicate else { return dictionaryList }
        
        return dictionaryList.filter({ predicate.evaluate(with: $0) })
    }
    
    private func identifyingPredicate<Entity>(of entity: Entity) -> NSPredicate where Entity: EntityRepresentable {
        let predicates = entity.identifyingDictionary.map({ key, value in
            NSPredicate(format: "\(key) == %@", argumentArray: [value])
        })
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

// MARK: - Nested operation

extension MockStorage {
    enum Operation {
        case add
        case fetch
        case count
        case update
        case delete
    }
}

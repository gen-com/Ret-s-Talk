//
//  UserDefaultsManager.swift
//  RetsTalk
//
//  Created on 11/25/24.
//

import Foundation

actor UserDefaultsManager: Persistable {
    private let userDefaultsContainer: UserDefaults

    init(container: UserDefaults = .standard) {
        self.userDefaultsContainer = container
    }
    
    // MARK: Persistable conformance

    func add<Entity>(contentsOf entities: [Entity]) -> [Entity] where Entity: EntityRepresentable {
        guard let firstEntity = entities.first else { return [] }
        
        let entityDictionary = firstEntity.mappingDictionary
        userDefaultsContainer.set(entityDictionary, forKey: Entity.entityName)
        return [firstEntity]
    }
    
    func fetch<Entity>(by request: any PersistFetchRequestable<Entity>) -> [Entity] where Entity: EntityRepresentable {
        guard let entityDictionary = userDefaultsContainer.dictionary(forKey: Entity.entityName),
              let entity = try? Entity(dictionary: entityDictionary)
        else { return [] }
        
        return [entity]
    }
    
    func fetchDataCount<Entity>(
        by request: any PersistFetchRequestable<Entity>
    ) -> Int where Entity: EntityRepresentable {
        0
    }
    
    func update<Entity>(
        from sourceEntity: Entity,
        to updatingEntity: Entity
    ) -> Entity where Entity: EntityRepresentable {
        let dictionary = updatingEntity.mappingDictionary
        userDefaultsContainer.set(dictionary, forKey: Entity.entityName)
        return updatingEntity
    }
    
    func delete<Entity>(contentsOf entities: [Entity]) where Entity: EntityRepresentable {}
}

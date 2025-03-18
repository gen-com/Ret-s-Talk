//
//  CoreDataManager.swift
//  RetsTalk
//
//  Created on 11/13/24.
//

@preconcurrency import CoreData

actor CoreDataManager: Persistable {
    private let persistentContainer: NSPersistentContainer
    private var lastHistoryDate: Date
    
    // MARK: Initialization
    
    init(inMemory: Bool = false, name: String) async throws {
        persistentContainer = NSPersistentContainer(name: name)
        lastHistoryDate = Date()
        
        do {
            try setupPersistentContainer(inMemory: inMemory)
            _ = try await persistentContainer.loadPersistentStores()
        } catch {
            throw Error.storeSetUpFailed
        }
        deleteOldPersistentHistory()
    }
    
    private func setupPersistentContainer(inMemory: Bool) throws {
        guard let description = persistentContainer.persistentStoreDescriptions.first
        else { throw Error.storeSetUpFailed }
        
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = false
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    // MARK: Persistable conformance
    
    func add<Entity>(contentsOf entities: [Entity]) throws -> [Entity] where Entity: EntityRepresentable {
        guard entities.isNotEmpty else { return [] }
        
        let taskContext = newTaskContext()
        let batchInsertRequest = batchInsertRequest(for: entities)
        try taskContext.performAndWait {
            guard let batchInsertResult = try? taskContext.execute(batchInsertRequest) as? NSBatchInsertResult,
                  let success = batchInsertResult.result as? Bool, success
            else { throw Error.additionFailed }
        }
        try mergePersistentHistoryChanges()
        return entities
    }
    
    func fetch<Entity>(
        by request: any PersistFetchRequestable<Entity>
    ) throws -> [Entity] where Entity: EntityRepresentable {
        let taskContext = newTaskContext()
        let fetchRequest = fetchRequest(from: request)
        let fetchedEntities = try taskContext.performAndWait {
            guard let dictionaryList = try? taskContext.fetch(fetchRequest) as? [NSDictionary],
                  let anyDictionaryList = dictionaryList as? [[String: Any]],
                  let entities = try? anyDictionaryList.map({ try Entity(dictionary: $0) })
            else { throw Error.fetchingFailed }
            
            return entities
        }
        return fetchedEntities
    }
    
    func fetchDataCount<Entity>(
        by request: any PersistFetchRequestable<Entity>
    ) throws -> Int where Entity: EntityRepresentable {
        let taskContext = newTaskContext()
        let fetchRequest = fetchCountRequest(from: request)
        let fetchedCount = try taskContext.performAndWait {
            guard let count = try? taskContext.count(for: fetchRequest) else { throw Error.fetchingFailed }
            
            return count
        }
        return fetchedCount
    }
    
    func update<Entity>(
        from sourceEntity: Entity,
        to updatingEntity: Entity
    ) async throws -> Entity where Entity: EntityRepresentable {
        let taskContext = newTaskContext()
        let batchUpdateRequest = batchUpdateRequest(from: sourceEntity, to: updatingEntity)
        try taskContext.performAndWait {
            guard let batchUpdateResult = try? taskContext.execute(batchUpdateRequest) as? NSBatchUpdateResult,
                  let success = batchUpdateResult.result as? Bool, success
            else { throw Error.updateFailed }
        }
        try mergePersistentHistoryChanges()
        return updatingEntity
    }
    
    func delete<Entity>(contentsOf entities: [Entity]) async throws where Entity: EntityRepresentable {
        let taskContext = newTaskContext()
        for entity in entities {
            let batchDeleteRequest = batchDeleteRequest(for: entity)
            try taskContext.performAndWait {
                guard let batchDeleteResult = try taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult,
                      let success = batchDeleteResult.result as? Bool, success
                else { throw Error.deletionFailed }
            }
        }
        try mergePersistentHistoryChanges()
    }
    
    // MARK: Context creation
    
    private nonisolated func newTaskContext() -> NSManagedObjectContext {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return taskContext
    }
    
    // MARK: Request creation
    
    private nonisolated func fetchRequest<Entity>(
        from request: any PersistFetchRequestable<Entity>
    ) -> NSFetchRequest<NSFetchRequestResult> where Entity: EntityRepresentable {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Entity.entityName)
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.predicate = request.predicate?.nsPredicate
        fetchRequest.sortDescriptors = request.sortDescriptors.map { $0.nsSortDescriptor }
        fetchRequest.fetchLimit = request.fetchLimit
        fetchRequest.fetchOffset = request.fetchOffset
        return fetchRequest
    }
    
    private nonisolated func fetchCountRequest<Entity>(
        from request: any PersistFetchRequestable<Entity>
    ) -> NSFetchRequest<NSNumber> where Entity: EntityRepresentable {
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: Entity.entityName)
        fetchRequest.resultType = .countResultType
        return fetchRequest
    }
    
    private nonisolated func entityPredicate<Entity>(
        _ entity: Entity
    ) -> NSPredicate where Entity: EntityRepresentable {
        let predicates = entity.identifyingDictionary.map { (key, value) in
            NSPredicate(format: "\(key) == %@", argumentArray: [value])
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    // MARK: Batch request creation
    
    private nonisolated func batchInsertRequest<Entity>(
        for entities: [Entity]
    ) -> NSBatchInsertRequest where Entity: EntityRepresentable {
        var index = 0
        let batchInsertRequest = NSBatchInsertRequest(entityName: Entity.entityName) { dictionary in
            guard index < entities.count else { return true }
            
            dictionary.addEntries(from: entities[index].mappingDictionary)
            index += 1
            return false
        }
        return batchInsertRequest
    }
    
    private nonisolated func batchUpdateRequest<Entity>(
        from sourceEntity: Entity,
        to updatingEntity: Entity
    ) -> NSBatchUpdateRequest where Entity: EntityRepresentable {
        let batchUpdateRequest = NSBatchUpdateRequest(entityName: Entity.entityName)
        batchUpdateRequest.predicate = entityPredicate(sourceEntity)
        batchUpdateRequest.propertiesToUpdate = updatingEntity.mappingDictionary
        return batchUpdateRequest
    }
    
    private nonisolated func batchDeleteRequest<Entity>(
        for entity: Entity
    ) -> NSBatchDeleteRequest where Entity: EntityRepresentable {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Entity.entityName)
        fetchRequest.predicate = entityPredicate(entity)
        return NSBatchDeleteRequest(fetchRequest: fetchRequest)
    }
    
    // MARK: Context merge
    
    private func mergePersistentHistoryChanges() throws {
        let viewContext = persistentContainer.viewContext
        let history = try fetchPersistentHistoryTransactionsAndChanges()
        viewContext.performAndWait {
            for transaction in history {
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
            }
        }
        lastHistoryDate = history.last?.timestamp ?? Date()
    }
    
    private func fetchPersistentHistoryTransactionsAndChanges() throws -> [NSPersistentHistoryTransaction] {
        let taskContext = newTaskContext()
        let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryDate)
        let historyChanges = try taskContext.performAndWait {
            let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
            guard let history = historyResult?.result as? [NSPersistentHistoryTransaction]
            else { throw Error.persistentHistoryChangeError }
            
            return history
        }
        return historyChanges
    }
    
    // MARK: Old history deletion
    
    private func deleteOldPersistentHistory() {
        Task {
            let taskContext = newTaskContext()
            let deleteRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: Date().aMonthAgo())
            _ = await taskContext.perform {
                try? taskContext.execute(deleteRequest)
            }
        }
    }
}

// MARK: - Extends NSPersistentContainer for async-await

fileprivate extension NSPersistentContainer {
    func loadPersistentStores() async throws -> NSPersistentStoreDescription {
        try await withCheckedThrowingContinuation { continuation in
            loadPersistentStores { (description, error) in
                if let error {
                    continuation.resume(throwing: error)
                }
                continuation.resume(returning: description)
            }
        }
    }
}

// MARK: - Extends Date for readability

fileprivate extension Date {
    func aMonthAgo() -> Date {
        let secondsInOneMonth = TimeInterval(30 * 24 * 60 * 60)
        return self.addingTimeInterval(-secondsInOneMonth)
    }
}

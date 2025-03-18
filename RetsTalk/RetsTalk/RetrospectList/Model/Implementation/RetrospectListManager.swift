//
//  RetrospectListManager.swift
//  RetsTalk
//
//  Created on 11/19/24.
//

import Foundation

final class RetrospectListManager: RetrospectListManageable {
    
    // MARK: Dependency
    
    private let storage: Persistable
    private let summaryProvider: SummaryProvider
    
    private(set) var retrospectList: RetrospectList {
        willSet { streamListUpdate(newValue) }
    }
    
    // MARK: Data stream
    
    private var onRetrospectCreated: ((Retrospect) -> Void)?
    private var onRetrospectListUpdated: ((RetrospectList) -> Void)?
    private var onError: ((Swift.Error) -> Void)?
    
    var creationStream: AsyncStream<Retrospect> {
        AsyncStream { continuation in
            onRetrospectCreated = { retrospect in
                continuation.yield(retrospect)
            }
        }
    }
    var listStream: AsyncStream<RetrospectList> {
        AsyncStream { continuation in
            onRetrospectListUpdated = { retrospectList in
                continuation.yield(retrospectList)
            }
        }
    }
    var errorStream: AsyncStream<Swift.Error> {
        AsyncStream { continuation in
            onError = { error in
                continuation.yield(error)
            }
        }
    }
    
    // MARK: Task queue
    
    private let taskQueue: MainActorTaskQueue

    // MARK: Initialization
    
    init(dependency: RetrospectListDependency) {
        storage = dependency.storage
        summaryProvider = dependency.summaryProvider
        
        retrospectList = RetrospectList()
        
        taskQueue = MainActorTaskQueue()
    }
    
    // MARK: Retrospect list state
    
    private var isCreationAvailable: Bool {
        retrospectList.inProgress.count < Numerics.inProgressLimit
    }
    
    private var isPinAvailable: Bool {
        retrospectList.pinned.count < Numerics.pinLimit
    }
    
    // MARK: RetrospectManageable conformance
    
    func createRetrospect() {
        taskQueue.enqueue { [weak self] in
            await self?.createRetrospect()
        }
    }

    func fetchRetrospects() {
        taskQueue.enqueue { [weak self] in
            await self?.fetchRetrospects()
        }
    }
    
    func updateRetrospect(to updated: Retrospect) {
        taskQueue.enqueue { [weak self] in
            do {
                try await self?.updateRetrospect(to: updated)
            } catch {
                self?.streamError(error)
            }
        }
    }
    
    func deleteRetrospect(_ retrospect: Retrospect) {
        taskQueue.enqueue { [weak self] in
            await self?.deleteRetrospect(retrospect)
        }
    }
    
    // MARK: Stream
    
    private func streamCreation(_ retrospect: Retrospect) {
        guard let onRetrospectCreated else { return }
        
        onRetrospectCreated(retrospect)
    }
    
    private func streamListUpdate(_ retrospectList: RetrospectList) {
        guard let onRetrospectListUpdated else { return }
        
        onRetrospectListUpdated(retrospectList)
    }
    
    private func streamError(_ error: Swift.Error) {
        guard let onError else { return }
        
        onError(error)
    }
    
    // MARK: Async tasks
    
    private func createRetrospect() async {
        do {
            guard isCreationAvailable else { throw Error.reachInProgressLimit }
            guard let newRetrospect = try await storage.add(contentsOf: [Retrospect()]).first
            else { throw Error.creationFailed }
            
            retrospectList.append(contentsOf: [newRetrospect])
            try await fetchRetrospectsCount()
            streamCreation(newRetrospect)
        } catch {
            streamError(error)
        }
    }
    
    private func fetchRetrospects() async {
        do {
            var fetchedRetrospects = [Retrospect]()
            if retrospectList.finished.isEmpty {
                fetchedRetrospects += try await fetchPinnedRetrospects()
                fetchedRetrospects += try await fetchInProgressRetrospects()
            }
            fetchedRetrospects += try await fetchFinishedRetrospects()
            retrospectList.append(contentsOf: fetchedRetrospects)
            try await fetchRetrospectsCount()
        } catch {
            streamError(error)
        }
    }
    
    private func fetchRetrospectsCount() async throws {
        let totalCount = try await fetchTotalRetrospectCount()
        let monthlyCount = try await fetchMonthlyRetrospectCount()
        retrospectList.updateCount(total: totalCount, monthly: monthlyCount)
    }
    
    private func updateRetrospect(to updated: Retrospect) async throws {
        guard let source = retrospectList.retrospect(matching: updated) else { return }
        
        let updated = try await storage.update(from: source, to: updated)
        retrospectList.updateRetrospect(to: updated)
    }
    
    private func deleteRetrospect(_ retrospect: Retrospect) async {
        do {
            try await storage.delete(contentsOf: [retrospect])
            retrospectList.deleteRetrospect(retrospect)
        } catch {
            streamError(error)
        }
    }
    
    // MARK: Fetching retrospects
    
    private func fetchPinnedRetrospects() async throws -> [Retrospect] {
        let request = PersistFetchRequest<Retrospect>(
            predicate: Retrospect.pinnedPredicate,
            sortDescriptors: [Retrospect.lastest],
            fetchLimit: Numerics.pinLimit
        )
        let pinnedRetrospectList = try await storage.fetch(by: request)
        return pinnedRetrospectList
    }
    
    private func fetchInProgressRetrospects() async throws -> [Retrospect] {
        let request = PersistFetchRequest<Retrospect>(
            predicate: Retrospect.inProgressPredicate,
            sortDescriptors: [Retrospect.lastest],
            fetchLimit: Numerics.inProgressLimit
        )
        let inProgressRetrospectList = try await storage.fetch(by: request)
        return inProgressRetrospectList
    }
    
    private func fetchFinishedRetrospects() async throws -> [Retrospect] {
        let request = PersistFetchRequest<Retrospect>(
            predicate: Retrospect.finishedPredicate,
            sortDescriptors: [Retrospect.lastest],
            fetchLimit: Numerics.retrospectFetchAmount,
            fetchOffset: retrospectList.finished.count
        )
        let finishedRetrospectList = try await storage.fetch(by: request)
        return finishedRetrospectList
    }
    
    // MARK: Fetching retrospects count
    
    private func fetchTotalRetrospectCount() async throws -> Int {
        let request = PersistFetchRequest<Retrospect>()
        let count = try await storage.fetchDataCount(by: request)
        return count
    }
    
    private func fetchMonthlyRetrospectCount() async throws -> Int {
        let request = PersistFetchRequest<Retrospect>(predicate: Retrospect.monthlyPredicate(baseOn: Date()))
        let count = try await storage.fetchDataCount(by: request)
        return count
    }
}

// MARK: - RetrospectChatManagerListener conformance

extension RetrospectListManager {
    func didUpdateRetrospect(
        _ retrospectChatManageable: RetrospectChatManageable,
        updated retrospect: Retrospect
    ) async throws {
        try await updateRetrospect(to: retrospect)
    }
    
    func shouldTogglePin(_ retrospectChatManageable: RetrospectChatManageable, retrospect: Retrospect) -> Bool {
        retrospect.isPinned || isPinAvailable
    }
}

// MARK: - Constant

fileprivate extension RetrospectListManager {
    enum Numerics {
        static let pinLimit = 2
        static let inProgressLimit = 2
        static let retrospectFetchAmount = 20
    }
}

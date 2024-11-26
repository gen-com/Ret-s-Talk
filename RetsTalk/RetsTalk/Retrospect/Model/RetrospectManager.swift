//
//  RetrospectManager.swift
//  RetsTalk
//
//  Created by KimMinSeok on 11/19/24.
//

import Foundation
import Combine

final class RetrospectManager: RetrospectManageable, @unchecked Sendable {
    private let userID: UUID
    private var retrospects: [Retrospect] {
        didSet { retrospectsSubject.send(retrospects) }
    }
    private(set) var retrospectsSubject: CurrentValueSubject<[Retrospect], Never>
    private let retrospectStorage: Persistable
    private let assistantMessageProvider: AssistantMessageProvidable
    
    init(
        userID: UUID,
        retrospectStorage: Persistable,
        assistantMessageProvider: AssistantMessageProvidable
    ) {
        self.userID = userID
        self.retrospects = []
        self.retrospectsSubject = CurrentValueSubject(retrospects)
        self.retrospectStorage = retrospectStorage
        self.assistantMessageProvider = assistantMessageProvider
    }
    
    func fetchRetrospects(offset: Int, amount: Int) async throws {
        let recentFinishedRequest = recentFinishedRetrospectFetchRequest(offset: offset, amount: amount)
        let recentFinishedEntities = try await retrospectStorage.fetch(by: recentFinishedRequest)
        retrospects.append(contentsOf: recentFinishedEntities)
    }
    
    func fetchinitRetrospects(offset: Int, amount: Int) async throws {
        let pinnedRequest = pinnedRetrospectFetchRequest()
        let pinnedEntities = try await retrospectStorage.fetch(by: pinnedRequest)
        
        let inProgressRequest = inProgressRetrospectFetchRequest()
        let inProgressEntities = try await retrospectStorage.fetch(by: inProgressRequest)
        
        let recentFinishedRequest = recentFinishedRetrospectFetchRequest(offset: offset, amount: amount)
        let recentFinishedEntities = try await retrospectStorage.fetch(by: recentFinishedRequest)
        
        let resultRetrospects = pinnedEntities + inProgressEntities + recentFinishedEntities
        retrospects.append(contentsOf: resultRetrospects)
    }
    
    func create() async throws -> RetrospectChatManageable {
        let retrospect = Retrospect(userID: userID)
        _ = try await retrospectStorage.add(contentsOf: [retrospect])
        retrospects.append(retrospect)
        
        let retrospectChatManager = RetrospectChatManager(
            retrospect: retrospect,
            messageStorage: retrospectStorage,
            assistantMessageProvider: assistantMessageProvider,
            retrospectChatManagerListener: self
        )
 
        return retrospectChatManager
    }
    
    func update(_ retrospect: Retrospect) async throws {
        
    }
    
    func delete(_ retrospect: Retrospect) async throws {
        
    }
}

// MARK: - ChatManager Create FetchRequest

extension RetrospectManager {
    private func pinnedRetrospectFetchRequest() -> PersistFetchRequest<Retrospect> {
        let predicate = CustomPredicate(format: "userID = %@ AND isPinned = %@", argumentArray: [userID, true])
        let sortDescriptors = CustomSortDescriptor(key: "createdAt", ascending: false)
        
        let request = PersistFetchRequest<Retrospect>(
            predicate: predicate,
            sortDescriptors: [sortDescriptors],
            fetchLimit: Numerics.isPinnedFetchAmount
        )
        
        return request
    }
    
    private func inProgressRetrospectFetchRequest() -> PersistFetchRequest<Retrospect> {
        let predicate = CustomPredicate(
            format: "userID = %@ AND status != %@",
            argumentArray: [userID, Texts.finishedStatus]
        )
        let sortDescriptors = CustomSortDescriptor(key: "createdAt", ascending: false)
        
        let request = PersistFetchRequest<Retrospect>(
            predicate: predicate,
            sortDescriptors: [sortDescriptors],
            fetchLimit: Numerics.isProgressFetchAmount
        )
        
        return request
    }
    
    private func recentFinishedRetrospectFetchRequest(offset: Int, amount: Int) -> PersistFetchRequest<Retrospect> {
        let predicate = CustomPredicate(
            format: "userID = %@ AND status = %@ AND isPinned = %@",
            argumentArray: [userID, Texts.finishedStatus, false]
        )
        let sortDescriptors = CustomSortDescriptor(key: "createdAt", ascending: false)
        
        let request = PersistFetchRequest<Retrospect>(
            predicate: predicate,
            sortDescriptors: [sortDescriptors],
            fetchLimit: amount,
            fetchOffset: offset
        )
        
        return request
    }
}

// MARK: - MessageManagerListener conformance

extension RetrospectManager: RetrospectChatManagerListener {
    func didUpdateRetrospect(_ retrospectChatManageable: any RetrospectChatManageable, retrospect: Retrospect) {
        guard let matchingIndex = retrospects.firstIndex(where: { $0.id == retrospect.id })
        else { return }
        
        retrospects[matchingIndex] = retrospect
    }
    
    func shouldTogglePin(_ retrospectChatManageable: any RetrospectChatManageable, retrospect: Retrospect) -> Bool {
        true
    }
}

// MARK: - Constant

extension RetrospectManager {
    enum Numerics {
        static let isPinnedFetchAmount = 2
        static let isProgressFetchAmount = 2
    }
    
    enum Texts {
        static let finishedStatus = "retrospectFinished"
    }
}

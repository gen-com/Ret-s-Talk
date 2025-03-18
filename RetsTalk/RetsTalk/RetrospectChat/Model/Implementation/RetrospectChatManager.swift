//
//  RetrospectChatManager.swift
//  RetsTalk
//
//  Created on 11/19/24.
//

import Foundation

final class RetrospectChatManager: RetrospectChatManageable {
    
    // MARK: Dependency
    
    private var retrospect: Retrospect {
        willSet { streamRetrospectUpdate(newValue) }
    }
    
    private let retrospectChatManagerListener: RetrospectChatManagerListener
    private let messageStorage: Persistable
    private let assistantMessageProvider: AssistantMessageProvidable
    
    // MARK: Data stream
    
    private var onRetrospectUpdated: ((Retrospect) -> Void)?
    private var onError: ((Swift.Error) -> Void)?
    
    var retrospectStream: AsyncStream<Retrospect> {
        AsyncStream { continuation in
            onRetrospectUpdated = { retrospect in
                continuation.yield(retrospect)
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

    init(dependency: RetrospectChatDependency) {
        retrospect = dependency.retrospect
        retrospectChatManagerListener = dependency.retrospectChatManagerListener
        messageStorage = dependency.messageStorage
        assistantMessageProvider = dependency.assistantMessageProvider
        
        taskQueue = MainActorTaskQueue()
    }
    
    // MARK: RetrospectChatManageable conformance
    
    func sendMessage(_ content: String) {
        taskQueue.enqueue { [weak self] in
            await self?.addUserMessage(content)
            await self?.requestAssistantMessage()
        }
    }
    
    func requestAssistantMessage() {
        taskQueue.enqueue { [weak self] in
            await self?.requestAssistantMessage()
        }
    }
    
    func fetchPreviousMessages() {
        taskQueue.enqueue { [weak self] in
            await self?.fetchPreviousMessages()
        }
    }
    
    func endRetrospect() {
        retrospect.setState(as: .finished)
        taskQueue.enqueue { [weak self] in
            await self?.updateRetrospect()
        }
    }
    
    func toggleRetrospectPin() {
        guard retrospectChatManagerListener.shouldTogglePin(self, retrospect: retrospect)
        else {
            streamError(Error.pinUnavailable)
            return
        }
        
        retrospect.togglePin()
        taskQueue.enqueue { [weak self] in
            await self?.updateRetrospect()
        }
    }
    
    // MARK: Stream
    
    private func streamRetrospectUpdate(_ retrospect: Retrospect) {
        guard let onRetrospectUpdated else { return }
        
        onRetrospectUpdated(retrospect)
    }
    
    private func streamError(_ error: Swift.Error) {
        guard let onError else { return }
        
        onError(error)
    }
    
    // MARK: Async tasks
    
    private func addUserMessage(_ content: String) async {
        do {
            let userMessage = Message(retrospectID: retrospect.id, role: .user, content: content)
            let addedUserMessage = try await messageStorage.add(contentsOf: [userMessage])
            retrospect.append(contentsOf: addedUserMessage)
        } catch {
            streamError(error)
        }
    }
    
    private func requestAssistantMessage() async {
        do {
            retrospect.setState(as: .waitingForResponse)
            let assistantMessage = try await assistantMessageProvider.requestAssistantMessage(for: retrospect)
            
            let addedAssistantMessage = try await messageStorage.add(contentsOf: [assistantMessage])
            retrospect.append(contentsOf: addedAssistantMessage)
            retrospect.setState(as: .waitingForUserInput)
            try await retrospectChatManagerListener.didUpdateRetrospect(self, updated: retrospect)
        } catch {
            retrospect.setState(as: .responseErrorOccurred)
            streamError(error)
        }
    }
    
    private func fetchPreviousMessages() async {
        do {
            let fetchedMessages = try await messageStorage.fetch(by: messageFetchRequest)
            retrospect.prepend(contentsOf: fetchedMessages.reversed())
        } catch {
            streamError(error)
        }
    }
    
    private func updateRetrospect() async {
        do {
            try await retrospectChatManagerListener.didUpdateRetrospect(self, updated: retrospect)
        } catch {
            streamError(error)
        }
    }
    
    // MARK: Fetch request
    
    private var messageFetchRequest: PersistFetchRequest<Message> {
        PersistFetchRequest<Message>(
            predicate: Retrospect.matchingRetorspect(id: retrospect.id),
            sortDescriptors: [Retrospect.lastest],
            fetchLimit: Numeric.messageFetchAmount,
            fetchOffset: retrospect.chat.count
        )
    }
}

// MARK: - Constants

fileprivate extension RetrospectChatManager {
    enum Numeric {
        static let messageFetchAmount = 30
    }
}

//
//  RetrospectChatDependency.swift
//  RetsTalk
//
//  Created on 3/16/25.
//

protocol RetrospectChatDependency {
    var retrospect: Retrospect { get }
    var retrospectChatManagerListener: RetrospectChatManagerListener { get }
    var messageStorage: Persistable { get }
    var assistantMessageProvider: AssistantMessageProvidable { get }
}

final class RetrospectChatComponent: RetrospectChatDependency {
    var retrospect: Retrospect
    var retrospectChatManagerListener: RetrospectChatManagerListener
    var messageStorage: Persistable
    var assistantMessageProvider: AssistantMessageProvidable
    
    init(
        retrospect: Retrospect,
        retrospectChatManagerListener: RetrospectChatManagerListener,
        messageStorage: Persistable,
        assistantMessageProvider: AssistantMessageProvidable
    ) {
        self.retrospect = retrospect
        self.retrospectChatManagerListener = retrospectChatManagerListener
        self.messageStorage = messageStorage
        self.assistantMessageProvider = assistantMessageProvider
    }
}

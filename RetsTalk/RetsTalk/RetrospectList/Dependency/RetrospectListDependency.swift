//
//  RetrospectListDependency.swift
//  RetsTalk
//
//  Created on 3/16/25.
//

@MainActor
protocol RetrospectListDependency {
    var storage: Persistable { get }
    var summaryProvider: SummaryProvider { get }
    
    func retrospectChatDependency(
        for retrospect: Retrospect,
        on listener: RetrospectChatManagerListener
    ) -> RetrospectChatDependency
}

final class RetrospectListComponent: RetrospectListDependency {
    var storage: Persistable
    var summaryProvider: SummaryProvider
    
    init(storage: Persistable, summaryProvider: SummaryProvider) {
        self.storage = storage
        self.summaryProvider = summaryProvider
    }
    
    func retrospectChatDependency(
        for retrospect: Retrospect,
        on listener: RetrospectChatManagerListener
    ) -> RetrospectChatDependency {
        RetrospectChatComponent(
            retrospect: retrospect,
            retrospectChatManagerListener: listener,
            messageStorage: storage,
            assistantMessageProvider: CLOVAStudioManager(urlSession: .shared)
        )
    }
}

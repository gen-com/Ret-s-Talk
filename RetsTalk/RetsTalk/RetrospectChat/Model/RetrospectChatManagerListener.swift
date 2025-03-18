//
//  RetrospectChatManagerListener.swift
//  RetsTalk
//
//  Created on 11/18/24.
//

@MainActor
protocol RetrospectChatManagerListener {
    func didUpdateRetrospect(
        _ retrospectChatManager: RetrospectChatManageable,
        updated retrospect: Retrospect
    ) async throws
    func shouldTogglePin(_ retrospectChatManager: RetrospectChatManageable, retrospect: Retrospect) -> Bool
}

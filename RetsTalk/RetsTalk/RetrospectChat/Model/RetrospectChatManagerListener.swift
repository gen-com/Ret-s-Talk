//
//  RetrospectChatManagerListener.swift
//  RetsTalk
//
//  Created by KimMinSeok on 11/18/24.
//

@MainActor
protocol RetrospectChatManagerListener {
    func didUpdateRetrospect(_ retrospectChatManageable: RetrospectChatManageable, retrospect: Retrospect) throws
    func shouldTogglePin(_ retrospectChatManageable: RetrospectChatManageable, retrospect: Retrospect) -> Bool
}

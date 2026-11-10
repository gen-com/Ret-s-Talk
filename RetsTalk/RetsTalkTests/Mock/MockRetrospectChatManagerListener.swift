//
//  MockRetrospectChatManagerListener.swift
//  RetsTalkTests
//
//  Created by KimMinSeok on 11/20/24.
//

@MainActor
final class MockRetrospectChatManagerListener: RetrospectChatManagerListener {
    private(set) var updatedRetrospects = [Retrospect]()
    var isPinAvailable = true
    
    func didUpdateRetrospect(
        _ retrospectChatManager: RetrospectChatManageable,
        updated retrospect: Retrospect
    ) async throws {
        updatedRetrospects.append(retrospect)
    }
    
    func shouldTogglePin(_ retrospectChatManager: RetrospectChatManageable, retrospect: Retrospect) -> Bool {
        isPinAvailable
    }
}

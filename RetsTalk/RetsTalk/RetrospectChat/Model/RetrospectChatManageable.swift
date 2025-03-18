//
//  RetrospectChatManageable.swift
//  RetsTalk
//
//  Created on 11/18/24.
//

@MainActor
protocol RetrospectChatManageable: Sendable {
    var retrospectStream: AsyncStream<Retrospect> { get }
    var errorStream: AsyncStream<Error> { get }
    
    func sendMessage(_ content: String)
    func requestAssistantMessage()
    func fetchPreviousMessages()
    func endRetrospect()
    func toggleRetrospectPin()
}

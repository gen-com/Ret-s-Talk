//
//  RetrospectListManageable.swift
//  RetsTalk
//
//  Created on 11/18/24.
//

import Combine

@MainActor
protocol RetrospectListManageable: RetrospectChatManagerListener {
    var creationStream: AsyncStream<Retrospect> { get }
    var listStream: AsyncStream<RetrospectList> { get }
    var errorStream: AsyncStream<Error> { get }
    
    func createRetrospect()
    func fetchRetrospects()
    func updateRetrospect(to updated: Retrospect)
    func deleteRetrospect(_ retrospect: Retrospect)
}

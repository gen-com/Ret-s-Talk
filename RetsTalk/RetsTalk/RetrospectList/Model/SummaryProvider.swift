//
//  summaryProvider.swift
//  RetsTalk
//
//  Created on 11/21/24.
//

protocol SummaryProvider: Sendable {
    func requestSummary(for chat: [Message]) async throws -> String
}

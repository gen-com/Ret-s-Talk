//
//  MockSummaryProvider.swift
//  RetsTalkTests
//
//  Created on 11/10/26.
//

struct MockSummaryProvider: SummaryProvider {
    static let defaultSummary = "회고 요약"
    
    func requestSummary(for chat: [Message]) async throws -> String {
        MockSummaryProvider.defaultSummary
    }
}

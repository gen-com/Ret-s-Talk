//
//  MockAssistantMessageProvider.swift
//  RetsTalkTests
//
//  Created by Byeongjo Koo on 11/21/24.
//

struct MockAssistantMessageProvider: AssistantMessageProvidable {
    typealias Handler = @Sendable (Retrospect) async throws -> Message
    
    private let handler: Handler
    
    init(handler: @escaping Handler = MockAssistantMessageProvider.defaultHandler) {
        self.handler = handler
    }
    
    func requestAssistantMessage(for retrospect: Retrospect) async throws -> Message {
        try await handler(retrospect)
    }
    
    static let defaultContent = "응답 테스트 메시지"
    static let defaultHandler: Handler = { retrospect in
        Message(retrospectID: retrospect.id, role: .assistant, content: MockAssistantMessageProvider.defaultContent)
    }
}

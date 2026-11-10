//
//  AssistantMessageProviderTest.swift
//  NetworkTests
//
//  Created by Byeongjo Koo on 11/20/24.
//

import XCTest

final class AssistantMessageProviderTest: XCTestCase {
    private var assistantMessageProvider: AssistantMessageProvidable?
    
    // MARK: Set up and tear down
    
    override func setUp() {
        super.setUp()
        
        assistantMessageProvider = CLOVAStudioManager(urlSession: MockURLProtocol.stubSession())
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        
        super.tearDown()
    }
    
    // MARK: Test
    
    func test_대화_목록을_바탕으로_도움_메시지를_받아오는지() async throws {
        let assistantMessageProvider = try XCTUnwrap(assistantMessageProvider)
        let retrospect = Retrospect()
        let expectedContent = "오늘 하루는 어떠셨나요?"
        MockURLProtocol.requestHandler = { request in
            try MockURLProtocol.stubResponse(
                for: request,
                statusCode: 200,
                body: """
                {"status":{"code":"20000","message":"OK"},\
                "result":{"message":{"role":"assistant","content":"\(expectedContent)"}}}
                """
            )
        }
        
        let message = try await assistantMessageProvider.requestAssistantMessage(for: retrospect)
        
        XCTAssertEqual(message.content, expectedContent)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.retrospectID, retrospect.id)
    }
    
    func test_요청에_시스템_메시지와_대화가_순서대로_담기는지() async throws {
        let assistantMessageProvider = try XCTUnwrap(assistantMessageProvider)
        var retrospect = Retrospect()
        retrospect.append(contentsOf: [
            Message(retrospectID: retrospect.id, role: .assistant, content: "오늘 어떤 일이 있었나요?"),
            Message(retrospectID: retrospect.id, role: .user, content: "테스트를 복구했어"),
        ])
        MockURLProtocol.requestHandler = { request in
            let bodyData = try XCTUnwrap(request.bodyData)
            let requestedChat = try JSONDecoder().decode(RequestedChat.self, from: bodyData)
            XCTAssertEqual(request.httpMethod, HTTPMethod.post.value)
            XCTAssertEqual(requestedChat.messages.map(\.role), ["system", "assistant", "user"])
            XCTAssertEqual(requestedChat.messages.last?.content, "테스트를 복구했어")
            return try MockURLProtocol.stubResponse(for: request, statusCode: 200, body: "{}")
        }
        
        _ = try await assistantMessageProvider.requestAssistantMessage(for: retrospect)
    }
    
    func test_인증_실패_응답을_서버_오류로_전달하는지() async throws {
        let assistantMessageProvider = try XCTUnwrap(assistantMessageProvider)
        MockURLProtocol.requestHandler = { request in
            try MockURLProtocol.stubResponse(
                for: request,
                statusCode: 401,
                body: #"{"status":{"code":"40103","message":"Invalid Key"}}"#
            )
        }
        
        do {
            _ = try await assistantMessageProvider.requestAssistantMessage(for: Retrospect())
            XCTFail("인증 실패 응답에서 오류가 전달되지 않았습니다.")
        } catch let NetworkError.serverError(message) {
            XCTAssertTrue(message.contains("Invalid Key"))
        }
    }
}

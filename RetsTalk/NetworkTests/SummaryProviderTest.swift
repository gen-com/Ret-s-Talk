//
//  SummaryProviderTest.swift
//  RetsTalk
//
//  Created by KimMinSeok on 11/21/24.
//

import XCTest

final class SummaryProviderTest: XCTestCase {
    private var summaryProvider: SummaryProvider?
    private let chat = [
        Message(
            retrospectID: UUID(),
            role: .assistant,
            content: "오늘 하루 동안 있었던 일들을 한번 되돌아볼까요? 어떤 일들이 있었는지 생각해 보세요."
        ),
        Message(
            retrospectID: UUID(),
            role: .user,
            content: "오늘은 요약 기능을 개발했는데 CLOVAStudio를 사용했어"
        ),
        Message(
            retrospectID: UUID(),
            role: .assistant,
            content: "사용하기 편하셨나요??"
        ),
        Message(
            retrospectID: UUID(),
            role: .user,
            content: "앞에서 채팅 Manager가 구현되어 있어서 정말 편했어요"
        ),
    ]
    
    // MARK: Set up and tear down
    
    override func setUp() {
        super.setUp()
        
        summaryProvider = CLOVAStudioManager(urlSession: MockURLProtocol.stubSession())
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        
        super.tearDown()
    }
    
    // MARK: Test
    
    func test_대화를_통해_요약을_제공하는지() async throws {
        let summaryProvider = try XCTUnwrap(summaryProvider)
        let expectedSummary = "요약 기능을 개발하며 CLOVAStudio를 사용함"
        let expectedMessageCount = chat.count + 1
        MockURLProtocol.requestHandler = { request in
            let bodyData = try XCTUnwrap(request.bodyData)
            let requestedChat = try JSONDecoder().decode(RequestedChat.self, from: bodyData)
            XCTAssertEqual(requestedChat.messages.first?.role, "system")
            XCTAssertEqual(requestedChat.messages.count, expectedMessageCount)
            return try MockURLProtocol.stubResponse(
                for: request,
                statusCode: 200,
                body: """
                {"status":{"code":"20000","message":"OK"},\
                "result":{"message":{"role":"assistant","content":"\(expectedSummary)"}}}
                """
            )
        }
        
        let summary = try await summaryProvider.requestSummary(for: chat)
        
        XCTAssertEqual(summary, expectedSummary)
    }
    
    func test_응답에_요약이_없으면_빈_문자열을_돌려주는지() async throws {
        let summaryProvider = try XCTUnwrap(summaryProvider)
        MockURLProtocol.requestHandler = { request in
            try MockURLProtocol.stubResponse(for: request, statusCode: 200, body: "{}")
        }
        
        let summary = try await summaryProvider.requestSummary(for: chat)
        
        XCTAssertEqual(summary, "")
    }
}

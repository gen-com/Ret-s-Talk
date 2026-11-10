//
//  RetrospectChatManagerTests.swift
//  RetsTalkTests
//
//  Created by KimMinSeok on 11/20/24.
//

import XCTest

final class RetrospectChatManagerTests: XCTestCase {
    
    // MARK: Send
    
    @MainActor
    func test_회고_도움_메시지를_받아왔을때_상태_반영을_하는지() async throws {
        let context = makeContext(assistantMessageHandler: { retrospect in
            XCTAssertEqual(retrospect.state, .waitingForResponse)
            return Message(retrospectID: retrospect.id, role: .assistant, content: "응답 테스트 메시지")
        })
        
        context.manager.sendMessage("안녕하세요.")
        await waitUntil { context.listener.updatedRetrospects.last?.chat.count == 2 }
        
        let retrospect = try XCTUnwrap(context.listener.updatedRetrospects.last)
        XCTAssertEqual(retrospect.state, .waitingForUserInput)
        XCTAssertEqual(retrospect.chat.map(\.role), [.user, .assistant])
        XCTAssertEqual(retrospect.chat.first?.content, "안녕하세요.")
        XCTAssertTrue(context.errors.elements.isEmpty)
    }
    
    @MainActor
    func test_회고_도움_메시지를_받아오는데_실패한_경우_상태_반영을_하는지() async throws {
        let context = makeContext(assistantMessageHandler: { _ in
            throw TestError.custom
        })
        
        context.manager.sendMessage("실패 !")
        await waitUntil { context.listener.updatedRetrospects.last?.state == .responseErrorOccurred }
        
        let retrospect = try XCTUnwrap(context.listener.updatedRetrospects.last)
        XCTAssertEqual(retrospect.chat.map(\.role), [.user])
        XCTAssertEqual(context.errors.elements.count, 1)
    }
    
    @MainActor
    func test_보낸_메시지와_받은_메시지를_저장소에_저장하는지() async throws {
        let context = makeContext()
        
        context.manager.sendMessage("안녕하세요.")
        await waitUntil { context.listener.updatedRetrospects.last?.chat.count == 2 }
        
        let storedMessages = try await context.storage.fetch(by: PersistFetchRequest<Message>(fetchLimit: 10))
        XCTAssertEqual(storedMessages.count, 2)
        XCTAssertTrue(storedMessages.allSatisfy({ $0.retrospectID == context.retrospect.id }))
    }
    
    // MARK: Fetch
    
    @MainActor
    func test_예전_메시지를_최신순으로_나눠서_불러올_수_있는가() async throws {
        let context = makeContext()
        let baseDate = Date()
        let storedMessages = try (1...70).map({ number in
            try Message.stub(
                retrospectID: context.retrospect.id,
                content: "\(number)",
                createdAt: baseDate.addingTimeInterval(TimeInterval(number))
            )
        })
        _ = try await context.storage.add(contentsOf: storedMessages)
        
        context.manager.fetchPreviousMessages()
        await waitUntil { context.retrospects.elements.last?.chat.count == 30 }
        let firstFetchedChat = try XCTUnwrap(context.retrospects.elements.last?.chat)
        
        context.manager.fetchPreviousMessages()
        await waitUntil { context.retrospects.elements.last?.chat.count == 60 }
        let secondFetchedChat = try XCTUnwrap(context.retrospects.elements.last?.chat)
        
        XCTAssertEqual(firstFetchedChat.map(\.content), (41...70).map({ "\($0)" }))
        XCTAssertEqual(secondFetchedChat.map(\.content), (11...70).map({ "\($0)" }))
    }
    
    // MARK: Update
    
    @MainActor
    func test_회고_종료로_상태를_변경할_수_있는가() async throws {
        let context = makeContext()
        
        context.manager.endRetrospect()
        await waitUntil { context.listener.updatedRetrospects.last?.state == .finished }
        
        XCTAssertEqual(context.retrospects.elements.last?.state, .finished)
    }
    
    @MainActor
    func test_회고_고정_상태를_변경할_수_있는가() async throws {
        let context = makeContext()
        let previousPinState = context.retrospect.isPinned
        
        context.manager.toggleRetrospectPin()
        await waitUntil { !context.listener.updatedRetrospects.isEmpty }
        
        XCTAssertNotEqual(context.listener.updatedRetrospects.last?.isPinned, previousPinState)
    }
    
    @MainActor
    func test_회고_고정이_불가능하면_오류를_알리고_상태를_유지하는가() async throws {
        let context = makeContext()
        context.listener.isPinAvailable = false
        
        context.manager.toggleRetrospectPin()
        await waitUntil { !context.errors.elements.isEmpty }
        
        guard case .pinUnavailable = context.errors.elements.first as? RetrospectChatManager.Error
        else { return XCTFail("고정 제한 오류가 전달되지 않았습니다.") }
        XCTAssertTrue(context.listener.updatedRetrospects.isEmpty)
    }
    
    // MARK: Ordering
    
    @MainActor
    func test_응답_대기_중에_종료해도_종료_상태가_마지막에_저장되는가() async throws {
        let (responseGate, responseGateContinuation) = AsyncStream.makeStream(of: Void.self)
        let context = makeContext(assistantMessageHandler: { retrospect in
            for await _ in responseGate { break }
            return Message(retrospectID: retrospect.id, role: .assistant, content: "늦게 도착한 응답")
        })
        
        context.manager.sendMessage("안녕하세요.")
        await waitUntil { context.retrospects.elements.last?.state == .waitingForResponse }
        context.manager.endRetrospect()
        responseGateContinuation.yield()
        await waitUntil { context.listener.updatedRetrospects.last?.state == .finished }
        
        let retrospect = try XCTUnwrap(context.listener.updatedRetrospects.last)
        XCTAssertEqual(retrospect.state, .finished)
        XCTAssertEqual(retrospect.chat.map(\.role), [.user, .assistant])
    }
    
    @MainActor
    func test_종료_직후_매니저를_놓아도_종료_상태가_저장되는가() async throws {
        let (responseGate, responseGateContinuation) = AsyncStream.makeStream(of: Void.self)
        let listener = MockRetrospectChatManagerListener()
        var manager: RetrospectChatManager? = RetrospectChatManager(
            dependency: RetrospectChatComponent(
                retrospect: Retrospect(),
                retrospectChatManagerListener: listener,
                messageStorage: MockStorage(),
                assistantMessageProvider: MockAssistantMessageProvider(handler: { retrospect in
                    for await _ in responseGate { break }
                    return Message(retrospectID: retrospect.id, role: .assistant, content: "늦게 도착한 응답")
                })
            )
        )
        
        manager?.sendMessage("안녕하세요.")
        await waitUntil { listener.updatedRetrospects.count == 1 }
        manager?.endRetrospect()
        manager = nil
        responseGateContinuation.yield()
        await waitUntil { listener.updatedRetrospects.last?.state == .finished }
        
        XCTAssertEqual(listener.updatedRetrospects.last?.state, .finished)
    }
}

// MARK: - Test context

private extension RetrospectChatManagerTests {
    @MainActor
    struct Context {
        let retrospect: Retrospect
        let manager: RetrospectChatManager
        let listener: MockRetrospectChatManagerListener
        let storage: MockStorage
        let retrospects: StreamRecorder<Retrospect>
        let errors: StreamRecorder<Error>
    }
    
    @MainActor
    func makeContext(
        assistantMessageHandler: @escaping MockAssistantMessageProvider.Handler
            = MockAssistantMessageProvider.defaultHandler
    ) -> Context {
        let retrospect = Retrospect()
        let listener = MockRetrospectChatManagerListener()
        let storage = MockStorage()
        let manager = RetrospectChatManager(
            dependency: RetrospectChatComponent(
                retrospect: retrospect,
                retrospectChatManagerListener: listener,
                messageStorage: storage,
                assistantMessageProvider: MockAssistantMessageProvider(handler: assistantMessageHandler)
            )
        )
        return Context(
            retrospect: retrospect,
            manager: manager,
            listener: listener,
            storage: storage,
            retrospects: StreamRecorder(manager.retrospectStream),
            errors: StreamRecorder(manager.errorStream)
        )
    }
}

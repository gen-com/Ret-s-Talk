//
//  RetrospectListManagerTests.swift
//  RetsTalkTests
//
//  Created by KimMinSeok on 11/24/24.
//

import XCTest

final class RetrospectListManagerTests: XCTestCase {
    
    // MARK: Creation tests
    
    @MainActor
    func test_회고_생성에_성공하면_생성된_회고를_알리고_목록에_추가하는지() async throws {
        let context = try await makeContext()
        
        context.manager.createRetrospect()
        await waitUntil { context.creations.elements.count == 1 }
        
        XCTAssertEqual(context.manager.retrospectList.inProgress.map(\.id), context.creations.elements.map(\.id))
        XCTAssertEqual(context.manager.retrospectList.count.total, 1)
        XCTAssertTrue(context.errors.elements.isEmpty)
    }
    
    @MainActor
    func test_진행중인_회고가_한도에_이르면_생성_오류를_알리는지() async throws {
        let context = try await makeContext(retrospects: [
            .stub(state: .waitingForUserInput),
            .stub(state: .waitingForUserInput),
        ])
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.inProgress.count == 2 }
        
        context.manager.createRetrospect()
        await waitUntil { !context.errors.elements.isEmpty }
        
        guard case .reachInProgressLimit = context.errors.elements.first as? RetrospectListManager.Error
        else { return XCTFail("진행 중 한도 오류가 전달되지 않았습니다.") }
        XCTAssertEqual(context.manager.retrospectList.inProgress.count, 2)
        XCTAssertTrue(context.creations.elements.isEmpty)
    }
    
    // MARK: Fetch tests
    
    @MainActor
    func test_고정_진행중_종료된_회고를_나눠서_불러오는지() async throws {
        let context = try await makeContext(retrospects: [
            .stub(state: .finished, isPinned: true),
            .stub(state: .waitingForUserInput),
            .stub(state: .finished),
        ])
        
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.count.total == 3 }
        
        XCTAssertEqual(context.manager.retrospectList.pinned.count, 1)
        XCTAssertEqual(context.manager.retrospectList.inProgress.count, 1)
        XCTAssertEqual(context.manager.retrospectList.finished.count, 1)
        XCTAssertTrue(context.errors.elements.isEmpty)
    }
    
    @MainActor
    func test_종료된_회고를_이어서_불러와도_중복_없이_쌓이는지() async throws {
        let baseDate = Date()
        let finishedRetrospects = try (1...25).map({ number in
            try Retrospect.stub(state: .finished, createdAt: baseDate.addingTimeInterval(TimeInterval(-number)))
        })
        let context = try await makeContext(retrospects: finishedRetrospects)
        
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.finished.count == 20 }
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.finished.count == 25 }
        
        let fetchedIDs = context.manager.retrospectList.finished.map(\.id)
        XCTAssertEqual(Set(fetchedIDs).count, 25)
        XCTAssertEqual(fetchedIDs, finishedRetrospects.map(\.id))
    }
    
    @MainActor
    func test_전체_개수와_이번_달_개수를_따로_세는지() async throws {
        let now = Date()
        let twoMonthsAgo = try XCTUnwrap(Calendar.current.date(byAdding: .month, value: -2, to: now))
        let context = try await makeContext(retrospects: [
            .stub(createdAt: now),
            .stub(createdAt: now),
            .stub(createdAt: twoMonthsAgo),
        ])
        
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.count.total == 3 }
        
        XCTAssertEqual(context.manager.retrospectList.count.monthly, 2)
    }
    
    // MARK: Update tests
    
    @MainActor
    func test_회고_고정_가능한_경우_상태_변경이_반영되는지() async throws {
        let context = try await makeContext(retrospects: [.stub(state: .finished)])
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.finished.count == 1 }
        var retrospect = try XCTUnwrap(context.manager.retrospectList.finished.first)
        
        retrospect.togglePin()
        context.manager.updateRetrospect(to: retrospect)
        await waitUntil { context.manager.retrospectList.pinned.count == 1 }
        
        let storedPinnedCount = try await context.storage.fetchDataCount(
            by: PersistFetchRequest<Retrospect>(predicate: Retrospect.pinnedPredicate)
        )
        XCTAssertEqual(storedPinnedCount, 1)
        XCTAssertTrue(context.errors.elements.isEmpty)
    }
    
    @MainActor
    func test_회고_고정_한도에_걸려_상태_변경이_안되게_막는지() async throws {
        let context = try await makeContext(retrospects: [
            .stub(state: .finished, isPinned: true),
            .stub(state: .finished, isPinned: true),
            .stub(state: .finished),
        ])
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.count.total == 3 }
        let unpinnedRetrospect = try XCTUnwrap(context.manager.retrospectList.finished.first)
        var pinningRetrospect = unpinnedRetrospect
        
        pinningRetrospect.togglePin()
        context.manager.updateRetrospect(to: pinningRetrospect)
        await waitUntil { !context.errors.elements.isEmpty }
        
        guard case .reachPinLimit = context.errors.elements.first as? RetrospectListManager.Error
        else { return XCTFail("고정 한도 오류가 전달되지 않았습니다.") }
        XCTAssertEqual(context.manager.retrospectList.pinned.count, 2)
        XCTAssertFalse(context.manager.shouldTogglePin(context.chatManager, retrospect: unpinnedRetrospect))
    }
    
    @MainActor
    func test_고정_한도가_찬_상태에서도_고정과_무관한_변경은_반영되는지() async throws {
        let context = try await makeContext(retrospects: [
            .stub(state: .finished, isPinned: true),
            .stub(state: .finished, isPinned: true),
            .stub(state: .waitingForUserInput),
        ])
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.count.total == 3 }
        var retrospect = try XCTUnwrap(context.manager.retrospectList.inProgress.first)
        
        retrospect.setState(as: .finished)
        context.manager.updateRetrospect(to: retrospect)
        await waitUntil { context.manager.retrospectList.finished.count == 1 }
        
        XCTAssertTrue(context.manager.retrospectList.inProgress.isEmpty)
        XCTAssertTrue(context.errors.elements.isEmpty)
    }
    
    @MainActor
    func test_대화_매니저가_알린_변경이_목록과_저장소에_반영되는지() async throws {
        let context = try await makeContext(retrospects: [.stub(state: .waitingForUserInput)])
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.inProgress.count == 1 }
        var retrospect = try XCTUnwrap(context.manager.retrospectList.inProgress.first)
        
        retrospect.setState(as: .finished)
        try await context.manager.didUpdateRetrospect(context.chatManager, updated: retrospect)
        
        let storedFinishedCount = try await context.storage.fetchDataCount(
            by: PersistFetchRequest<Retrospect>(predicate: Retrospect.finishedPredicate)
        )
        XCTAssertEqual(context.manager.retrospectList.finished.map(\.id), [retrospect.id])
        XCTAssertEqual(storedFinishedCount, 1)
    }
    
    // MARK: Deletion tests
    
    @MainActor
    func test_회고를_삭제하면_목록과_저장소에서_사라지는지() async throws {
        let context = try await makeContext(retrospects: [
            .stub(state: .finished, isPinned: true),
            .stub(state: .waitingForUserInput),
            .stub(state: .finished),
            .stub(state: .finished),
        ])
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.count.total == 4 }
        let targetRetrospect = try XCTUnwrap(context.manager.retrospectList.finished.first)
        
        context.manager.deleteRetrospect(targetRetrospect)
        await waitUntil { context.manager.retrospectList.count.total == 3 }
        
        let storedCount = try await context.storage.fetchDataCount(by: PersistFetchRequest<Retrospect>())
        XCTAssertFalse(context.manager.retrospectList.finished.contains(targetRetrospect))
        XCTAssertEqual(storedCount, 3)
        XCTAssertTrue(context.errors.elements.isEmpty)
    }
    
    @MainActor
    func test_회고를_삭제하면_그_회고의_메시지만_함께_삭제되는지() async throws {
        let context = try await makeContext(retrospects: [.stub(state: .finished), .stub(state: .finished)])
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.finished.count == 2 }
        let targetRetrospect = context.manager.retrospectList.finished[0]
        let otherRetrospect = context.manager.retrospectList.finished[1]
        try await addMessages(count: 5, of: targetRetrospect, to: context.storage)
        try await addMessages(count: 3, of: otherRetrospect, to: context.storage)
        
        context.manager.deleteRetrospect(targetRetrospect)
        await waitUntil { context.manager.retrospectList.finished.count == 1 }
        
        let targetMessageCount = try await messageCount(of: targetRetrospect, in: context.storage)
        let otherMessageCount = try await messageCount(of: otherRetrospect, in: context.storage)
        XCTAssertEqual(targetMessageCount, 0)
        XCTAssertEqual(otherMessageCount, 3)
    }
    
    @MainActor
    func test_저장소_삭제에_실패하면_오류를_알리고_목록을_유지하는지() async throws {
        let context = try await makeContext(
            retrospects: [.stub(state: .finished)],
            storage: MockStorage(failingOperations: [.delete])
        )
        context.manager.fetchRetrospects()
        await waitUntil { context.manager.retrospectList.finished.count == 1 }
        let targetRetrospect = try XCTUnwrap(context.manager.retrospectList.finished.first)
        
        context.manager.deleteRetrospect(targetRetrospect)
        await waitUntil { !context.errors.elements.isEmpty }
        
        XCTAssertEqual(context.manager.retrospectList.finished.count, 1)
    }
}

// MARK: - Test context

private extension RetrospectListManagerTests {
    @MainActor
    struct Context {
        let manager: RetrospectListManager
        let storage: MockStorage
        let creations: StreamRecorder<Retrospect>
        let errors: StreamRecorder<Error>
        let chatManager: RetrospectChatManager
    }
    
    @MainActor
    func makeContext(
        retrospects: [Retrospect] = [],
        storage: MockStorage = MockStorage()
    ) async throws -> Context {
        _ = try await storage.add(contentsOf: retrospects)
        let manager = RetrospectListManager(
            dependency: RetrospectListComponent(storage: storage, summaryProvider: MockSummaryProvider())
        )
        let chatManager = RetrospectChatManager(
            dependency: RetrospectChatComponent(
                retrospect: Retrospect(),
                retrospectChatManagerListener: manager,
                messageStorage: storage,
                assistantMessageProvider: MockAssistantMessageProvider()
            )
        )
        return Context(
            manager: manager,
            storage: storage,
            creations: StreamRecorder(manager.creationStream),
            errors: StreamRecorder(manager.errorStream),
            chatManager: chatManager
        )
    }
    
    @MainActor
    func addMessages(count: Int, of retrospect: Retrospect, to storage: MockStorage) async throws {
        let messages = (1...count).map({
            Message(retrospectID: retrospect.id, role: .user, content: "\($0)번 메시지")
        })
        _ = try await storage.add(contentsOf: messages)
    }
    
    @MainActor
    func messageCount(of retrospect: Retrospect, in storage: MockStorage) async throws -> Int {
        try await storage.fetchDataCount(
            by: PersistFetchRequest<Message>(predicate: Retrospect.matchingRetorspect(id: retrospect.id))
        )
    }
}

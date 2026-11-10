//
//  PersistTests.swift
//  PersistTests
//
//  Created by Byeongjo Koo on 11/19/24.
//

import XCTest

final class PersistTests: XCTestCase {
    private let testableContents = [
        "안녕하세요",
        "반갑습니다",
        "오히려좋아",
        "뿌끼먼취킹",
        "다시작성중",
    ]
    
    // MARK: Test
    
    func test_추가_연산으로_원하는_엔티티_데이터를_저장할_수_있는지() async throws {
        let persistentManager = try await makePersistentManager()
        let targetContent = try XCTUnwrap(testableContents.randomElement())
        let targetEntity = TestEntity(content: targetContent)
        
        let addedEntities = try await persistentManager.add(contentsOf: [targetEntity])
        
        XCTAssertEqual(addedEntities.first?.content, targetContent)
    }
    
    func test_불러오기_연산으로_특정_엔티티_데이터를_가져올_수_있는지() async throws {
        let persistentManager = try await makePersistentManager()
        try await addMultipleEntities(ofContents: testableContents, to: persistentManager)
        let targetContent = try XCTUnwrap(testableContents.randomElement())
        
        let request = PersistFetchRequest<TestEntity>(predicate: contentPredicate(targetContent), fetchLimit: 5)
        let fetchedEntities = try await persistentManager.fetch(by: request)
        
        XCTAssertEqual(fetchedEntities.count, 1)
        XCTAssertEqual(fetchedEntities.first?.content, targetContent)
    }
    
    func test_개수_연산이_조건에_맞는_엔티티_데이터만_세는지() async throws {
        let persistentManager = try await makePersistentManager()
        try await addMultipleEntities(ofContents: testableContents, to: persistentManager)
        let targetContent = try XCTUnwrap(testableContents.randomElement())
        
        let totalCount = try await persistentManager.fetchDataCount(by: PersistFetchRequest<TestEntity>())
        let matchingCount = try await persistentManager.fetchDataCount(
            by: PersistFetchRequest<TestEntity>(predicate: contentPredicate(targetContent))
        )
        
        XCTAssertEqual(totalCount, testableContents.count)
        XCTAssertEqual(matchingCount, 1)
    }
    
    func test_업데이트_연산으로_기존_엔티티_값을_변경할_수_있는지() async throws {
        let persistentManager = try await makePersistentManager()
        try await addMultipleEntities(ofContents: testableContents, to: persistentManager)
        let targetContent = try XCTUnwrap(testableContents.randomElement())
        let sourceEntity = TestEntity(content: targetContent)
        let updatingEntity = TestEntity(content: "아파트아파트")
        
        let updatedEntity = try await persistentManager.update(from: sourceEntity, to: updatingEntity)
        
        let allEntities = try await persistentManager.fetch(by: PersistFetchRequest<TestEntity>(fetchLimit: 5))
        XCTAssertEqual(updatedEntity.content, updatingEntity.content)
        XCTAssertTrue(allEntities.contains(where: { $0.content == updatingEntity.content }))
        XCTAssertFalse(allEntities.contains(where: { $0.content == targetContent }))
    }
    
    func test_삭제_연산으로_특정_엔티티_데이터를_제거할_수_있는지() async throws {
        let persistentManager = try await makePersistentManager()
        try await addMultipleEntities(ofContents: testableContents, to: persistentManager)
        let targetContent = try XCTUnwrap(testableContents.randomElement())
        let targetEntity = TestEntity(content: targetContent)
        
        try await persistentManager.delete(contentsOf: [targetEntity])
        
        let allEntities = try await persistentManager.fetch(by: PersistFetchRequest<TestEntity>(fetchLimit: 5))
        XCTAssertEqual(allEntities.count, testableContents.count - 1)
        XCTAssertFalse(allEntities.contains(where: { $0.content == targetContent }))
    }
    
    func test_조건_삭제_연산으로_조건에_맞는_엔티티_데이터만_제거하는지() async throws {
        let persistentManager = try await makePersistentManager()
        try await addMultipleEntities(ofContents: testableContents, to: persistentManager)
        let targetContent = try XCTUnwrap(testableContents.randomElement())
        
        try await persistentManager.delete(by: PersistFetchRequest<TestEntity>(predicate: contentPredicate(targetContent)))
        
        let allEntities = try await persistentManager.fetch(by: PersistFetchRequest<TestEntity>(fetchLimit: 5))
        XCTAssertEqual(allEntities.count, testableContents.count - 1)
        XCTAssertFalse(allEntities.contains(where: { $0.content == targetContent }))
    }
    
    func test_조건_삭제_연산이_조건_없는_요청을_거부하는지() async throws {
        let persistentManager = try await makePersistentManager()
        try await addMultipleEntities(ofContents: testableContents, to: persistentManager)
        
        do {
            try await persistentManager.delete(by: PersistFetchRequest<TestEntity>())
            XCTFail("조건 없는 삭제 요청이 거부되지 않았습니다.")
        } catch {
            let totalCount = try await persistentManager.fetchDataCount(by: PersistFetchRequest<TestEntity>())
            XCTAssertEqual(totalCount, testableContents.count)
        }
    }
    
    // MARK: Supporting method
    
    private func makePersistentManager() async throws -> Persistable {
        try await CoreDataManager(inMemory: true, name: "TestModel", bundle: Bundle(for: PersistTests.self))
    }
    
    private func contentPredicate(_ content: String) -> CustomPredicate {
        CustomPredicate(format: "content = %@ AND integer = %@", argumentArray: [content, 0])
    }
    
    private func addMultipleEntities(ofContents contents: [String], to persistentManager: Persistable) async throws {
        _ = try await persistentManager.add(contentsOf: contents.map({ TestEntity(content: $0) }))
    }
}

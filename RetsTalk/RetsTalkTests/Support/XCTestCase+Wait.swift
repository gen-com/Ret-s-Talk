//
//  XCTestCase+Wait.swift
//  RetsTalkTests
//
//  Created on 11/10/26.
//

import XCTest

extension XCTestCase {
    @MainActor
    func waitUntil(
        timeout: Duration = .seconds(2),
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            guard ContinuousClock.now < deadline
            else {
                XCTFail("조건이 제한 시간 안에 충족되지 않았습니다.", file: file, line: line)
                return
            }
            
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
}

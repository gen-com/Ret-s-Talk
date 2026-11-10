//
//  Entity+Stub.swift
//  RetsTalkTests
//
//  Created on 11/10/26.
//

import Foundation

extension Retrospect {
    static func stub(
        state: State = .finished,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        summary: String = ""
    ) throws -> Retrospect {
        try Retrospect(dictionary: [
            "id": UUID(),
            "createdAt": createdAt,
            "status": state.rawValue,
            "isPinned": isPinned,
            "summary": summary,
        ])
    }
}

extension Message {
    static func stub(
        retrospectID: UUID,
        role: Role = .user,
        content: String,
        createdAt: Date = Date()
    ) throws -> Message {
        try Message(dictionary: [
            "retrospectID": retrospectID,
            "createdAt": createdAt,
            "isUser": role == .user,
            "content": content,
        ])
    }
}

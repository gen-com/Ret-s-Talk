//
//  Retrospect.swift
//  RetsTalk
//
//  Created on 11/7/24.
//

import Foundation

struct Retrospect {
    let id: UUID
    let createdAt: Date
    
    private(set) var state: State
    private(set) var isPinned: Bool
    private(set) var summary: String
    private(set) var chat: [Message]
    
    // MARK: Initializer
    
    init() {
        id = UUID()
        createdAt = Date()
        state = .waitingForUserInput
        isPinned = false
        summary = String()
        chat = []
    }
    
    // MARK: Mutating methods
    
    mutating func setState(as state: State) {
        self.state = state
    }
    
    mutating func togglePin() {
        isPinned.toggle()
    }
    
    mutating func setSummary(_ summary: String) {
        self.summary = summary
    }
    
    mutating func prepend(contentsOf messages: [Message]) {
        chat.insert(contentsOf: messages, at: chat.startIndex)
    }
    
    mutating func append(contentsOf messages: [Message]) {
        chat.append(contentsOf: messages)
        summary = messages.last?.content ?? ""
    }
    
    mutating func removeAllChat() {
        chat.removeAll(keepingCapacity: true)
    }
}

// MARK: - Hashable conformance

extension Retrospect: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(state)
        hasher.combine(isPinned)
        hasher.combine(summary)
    }
    
    static func == (lhs: Retrospect, rhs: Retrospect) -> Bool {
        lhs.id == rhs.id
        && lhs.state == rhs.state
        && lhs.isPinned == rhs.isPinned
        && lhs.summary == rhs.summary
    }
}

// MARK: - EntityRepresentable conformance

extension Retrospect: EntityRepresentable {
    static let entityName = "RetrospectEntity"
    
    init(dictionary: [String: Any]) throws {
        guard let id = dictionary["id"] as? UUID,
              let createdAt = dictionary["createdAt"] as? Date,
              let stateString = dictionary["status"] as? String,
              let state = State(rawValue: stateString),
              let isPinned = dictionary["isPinned"] as? Bool,
              let summary = dictionary["summary"] as? String
        else { throw CommonError.invalidData }
        
        self.id = id
        self.createdAt = createdAt
        self.state = state
        self.isPinned = isPinned
        self.summary = summary
        chat = []
    }
    
    var mappingDictionary: [String: Any] {
        [
            "id": id,
            "createdAt": createdAt,
            "status": state.rawValue,
            "isPinned": isPinned,
            "summary": summary,
        ]
    }
    
    var identifyingDictionary: [String: Any] {
        ["id": id]
    }
}

// MARK: - Nested state

extension Retrospect {
    enum State: String {
        case finished
        case waitingForUserInput
        case waitingForResponse
        case responseErrorOccurred
    }
}

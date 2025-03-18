//
//  Message.swift
//  RetsTalk
//
//  Created on 11/7/24.
//

import Foundation

struct Message: Hashable {
    let retrospectID: UUID
    let createdAt: Date
    let role: Role
    var content: String
    
    init(retrospectID: UUID, role: Role, content: String) {
        self.retrospectID = retrospectID
        self.createdAt = Date()
        self.role = role
        self.content = content
    }
}

// MARK: - EntityRepresentable conformance

extension Message: EntityRepresentable {
    static let entityName = "MessageEntity"
    
    init(dictionary: [String: Any]) throws {
        guard let retrospectID = dictionary["retrospectID"] as? UUID,
              let createdAt = dictionary["createdAt"] as? Date,
              let isUser = dictionary["isUser"] as? Bool,
              let content = dictionary["content"] as? String
        else { throw CommonError.invalidData }
        
        self.retrospectID = retrospectID
        self.createdAt = createdAt
        self.role = isUser ? Role.user : .assistant
        self.content = content
    }
    
    var mappingDictionary: [String: Any] {
        [
            "retrospectID": retrospectID,
            "createdAt": createdAt,
            "isUser": role == .user,
            "content": content,
        ]
    }
    
    var identifyingDictionary: [String: Any] {
        [
            "retrospectID": retrospectID,
            "createdAt": createdAt,
        ]
    }
}

// MARK: - Nested role

extension Message {
    enum Role: String {
        case user
        case assistant
    }
}

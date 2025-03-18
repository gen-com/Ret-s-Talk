//
//  RetrospectChatManager+Error.swift
//  RetsTalk
//
//  Created on 3/15/25.
//

import Foundation

extension RetrospectChatManager {
    enum Error: LocalizedError {
        case messageContentCountExceeded(currentCount: Int)
        case pinUnavailable
        
        var errorDescription: String? {
            switch self {
            case .messageContentCountExceeded:
                "메시지 내용 수 초과"
            case .pinUnavailable:
                "회고 고정 제한"
            }
        }
        
        var failureReason: String? {
            switch self {
            case let .messageContentCountExceeded(currentCount):
                "현재 입력된 글자 수는 \(currentCount)자입니다. 최대 100자까지 입력할 수 있습니다."
            case .pinUnavailable:
                "최대 2개의 회고만 고정할 수 있습니다.\n다른 회고의 고정을 해제해주세요."
            }
        }
    }
}

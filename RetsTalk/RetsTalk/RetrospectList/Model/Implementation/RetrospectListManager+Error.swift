//
//  Error.swift
//  RetsTalk
//
//  Created on 3/11/25.
//

import Foundation

extension RetrospectListManager {
    enum Error: LocalizedError {
        case creationFailed
        case reachInProgressLimit
        case reachPinLimit
        case invalidRetrospect
        
        var errorDescription: String? {
            switch self {
            case .creationFailed:
                "회고를 생성할 수 없습니다."
            case .reachInProgressLimit:
                "회고 생성 제한"
            case .reachPinLimit:
                "회고 고정 제한"
            case .invalidRetrospect:
                "존재하지 않는 회고입니다."
            }
        }
        
        var failureReason: String? {
            switch self {
            case .creationFailed:
                "회고 생성에 실패했습니다."
            case .reachInProgressLimit:
                "최대 2개의 회고만 진행할 수 있습니다.\n새로 생성하려면 기존 회고를 종료해주세요."
            case .reachPinLimit:
                "최대 2개의 회고만 고정할 수 있습니다.\n다른 회고의 고정을 해제해주세요."
            case .invalidRetrospect:
                "존재하지 않는 회고입니다."
            }
        }
    }
}

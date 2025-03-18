//
//  RetrospectListViewController+Alert.swift
//  RetsTalk
//
//  Created on 3/11/25.
//

import Foundation

extension RetrospectListViewController: AlertPresentable {
    enum Situation: AlertSituation {
        case delete
        case error(Error)
        
        var title: String {
            switch self {
            case .delete:
                "회고를 삭제하시겠습니까?"
            case .error(let error as LocalizedError):
                error.errorDescription ?? "오류"
            default:
                "오류"
            }
        }
        
        var message: String {
            switch self {
            case .delete:
                "삭제된 회고는 복구할 수 없습니다."
            case .error(let error as LocalizedError):
                error.failureReason ?? ""
            default:
                ""
            }
        }
    }
}

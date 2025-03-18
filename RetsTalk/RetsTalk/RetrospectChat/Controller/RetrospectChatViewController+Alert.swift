//
//  RetrospectChatViewController+Alert.swift
//  RetsTalk
//
//  Created by Byeongjo Koo on 2/7/25.
//

import Foundation

extension RetrospectChatViewController: AlertPresentable {
    enum Situation: AlertSituation {
        case error(Error)
        case finish
        
        var title: String {
            switch self {
            case let .error(error as LocalizedError):
                error.errorDescription ?? "오류 발생"
            case .error:
                "오류 발생"
            case .finish:
                "회고 종료"
            }
        }
        
        var message: String {
            switch self {
            case let .error(error as LocalizedError):
                error.failureReason ?? "알 수 없는 오류가 발생했습니다."
            case let .error(error):
                error.localizedDescription
            case .finish:
                "종료된 회고는 더 이상 작성할 수 없습니다.\n정말 종료하시겠습니까?"
            }
        }
    }
}

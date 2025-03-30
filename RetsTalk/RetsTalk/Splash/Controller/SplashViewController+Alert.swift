//
//  SplashViewController+Alert.swift
//  RetsTalk
//
//  Created on 3/30/25.
//

extension SplashViewController: AlertPresentable {
    enum Situation: AlertSituation {
        case storeLoadingFailed
        
        var title: String {
            switch self {
            case .storeLoadingFailed:
                "저장소를 불러오는데 실패했습니다."
            }
        }
        
        var message: String {
            switch self {
            case .storeLoadingFailed:
                "다시 시도해 보겠습니까?"
            }
        }
    }
}

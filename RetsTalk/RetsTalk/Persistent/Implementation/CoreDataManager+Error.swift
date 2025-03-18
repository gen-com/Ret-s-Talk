//
//  CoreDataManager+Error.swift
//  RetsTalk
//
//  Created on 3/9/25.
//

import Foundation

extension CoreDataManager {
    enum Error: LocalizedError {
        case storeSetUpFailed
        
        case additionFailed
        case updateFailed
        case fetchingFailed
        case deletionFailed
        
        case persistentHistoryChangeError
        
        var errorDescription: String? {
            switch self {
            case .storeSetUpFailed:
                "저장소를 설정하는데 실패했습니다."
            case .persistentHistoryChangeError:
                "변경 기록을 처리하는데 오류가 발생했습니다."
            case .additionFailed:
                "데이터를 추가하는데 실패했습니다."
            case .updateFailed:
                "데이터를 최신화하는데 실패했습니다."
            case .fetchingFailed:
                "데이터를 불러오는데 실패했습니다."
            case .deletionFailed:
                "데이터를 삭제하는데 실패했습니다."
            }
        }
    }
}

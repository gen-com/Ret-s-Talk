//
//  RetrospectListTableViewDelegate.swift
//  RetsTalk
//
//  Created on 3/16/25.
//

import Foundation

@MainActor
protocol RetrospectListTableViewDelegate: AnyObject {
    func retrospectListTableView(
        _ retrospectListTableView: RetrospectListTableView,
        didSelectRetrospectAt indexPath: IndexPath
    )
}

//
//  RetrospectListViewDelegate.swift
//  RetsTalk
//
//  Created on 3/16/25.
//

import Foundation

@MainActor
protocol RetrospectListViewDelegate: AnyObject {
    func retrospectListView(
        _ retrospectListView: RetrospectListView,
        didSelectRetrospectAt indexPath: IndexPath
    )
    
    func retrospectListView(
        _ retrospectListView: RetrospectListView,
        didTapCreateRetrospectButton: CreateRetrospectButton
    )
}

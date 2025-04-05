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
        didTapCreateRetrospectButton: CreateRetrospectButton
    )
    
    func retrospectListView(
        _ retrospectListView: RetrospectListView,
        didSelectRetrospectAt indexPath: IndexPath
    )
    func retrospectListView(
        _ retrospectListView: RetrospectListView,
        didTogglePinRetrospectAt indexPath: IndexPath
    )
    func retrospectListView(
        _ retrospectListView: RetrospectListView,
        didDeleteRetrospectAt indexPath: IndexPath
    )
    
    func retrospectListView(
        _ retrospectListView: RetrospectListView,
        didReachAppendablePoint point: CGPoint
    )
}

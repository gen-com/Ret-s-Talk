//
//  MessageCollectionViewDataSource.swift
//  RetsTalk
//
//  Created on 2/6/25.
//

import Foundation

@MainActor
protocol MessageCollectionViewDataSource: AnyObject {
    func numberOfMessages(in messageCollectionView: MessageCollectionView) -> Int
    func messageCollectionView(
        _ messageCollectionView: MessageCollectionView,
        messageForItemAt indexPath: IndexPath
    ) -> Message?
}

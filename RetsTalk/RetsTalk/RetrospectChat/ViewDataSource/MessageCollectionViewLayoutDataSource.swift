//
//  MessageCollectionViewLayoutDataSource.swift
//  RetsTalk
//
//  Created by Byeongjo Koo on 2/11/25.
//

import Foundation

@MainActor
protocol MessageCollectionViewLayoutDataSource: AnyObject {
    func messageCollectionViewLayout(
        _ messageCollectionViewLayout: MessageCollectionViewLayout,
        messageForItemAt indexPath: IndexPath
    ) -> Message?
}

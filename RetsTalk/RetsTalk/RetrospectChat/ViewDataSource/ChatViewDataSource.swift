//
//  ChatViewDataSource.swift
//  RetsTalk
//
//  Created by Byeongjo Koo on 2/6/25.
//

import Foundation

@MainActor
protocol ChatViewDataSource: AnyObject {
    func numberOfMessages(in chatView: ChatView) -> Int
    func chatView(_ chatView: ChatView, messageForItemAt indexPath: IndexPath) -> Message?
}

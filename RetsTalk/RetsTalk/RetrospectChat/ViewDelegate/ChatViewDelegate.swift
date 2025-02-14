//
//  ChatViewDelegate.swift
//  RetsTalk
//
//  Created on 2/5/25.
//

import UIKit

@MainActor
protocol ChatViewDelegate: AnyObject {
    func willSendMessage(from chatView: ChatView, with content: String) -> Bool
    func didTapRetryButton(_ retryButton: UIButton)
    
    func chatViewDidReachPrependablePoint(_ chatView: ChatView)
}

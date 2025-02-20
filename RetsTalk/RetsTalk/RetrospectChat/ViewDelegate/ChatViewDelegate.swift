//
//  ChatViewDelegate.swift
//  RetsTalk
//
//  Created on 2/5/25.
//

import UIKit

@MainActor
protocol ChatViewDelegate: AnyObject {
    func chatViewDidReachPrependablePoint(_ chatView: ChatView)
    
    func chatView(_ chatView: ChatView, shouldSendMessageWith content: String) -> Bool
    func chatView(_ chatView: ChatView, didSendMessage content: String)
    
    func chatView(_ chatView: ChatView, didTapRetryButton sender: UIButton)
}

//
//  MessageInputViewDelegate.swift
//  RetsTalk
//
//  Created on 12/29/24.
//

@MainActor
protocol MessageInputViewDelegate: AnyObject {
    func messageInputView(_ messageInputView: MessageInputView, shouldSendMessageWith content: String) -> Bool
    func messageInputView(_ messageInputView: MessageInputView, didSendMessage content: String)
}

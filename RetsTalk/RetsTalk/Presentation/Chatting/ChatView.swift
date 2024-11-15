//
//  ChatView.swift
//  RetsTalk
//
//  Created by KimMinSeok on 11/13/24.
//

import UIKit

@MainActor
final class ChatView: UIView {
    private let chattingTableView = UITableView()
    private let messageInputView = MessageInputView()
    private var messageInputViewHeightConstraint: NSLayoutConstraint?
    private var chatViewBottomConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        messageInputViewSetUp()
        chattingTableViewSetUp()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        messageInputViewSetUp()
        chattingTableViewSetUp()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollToBottom()
    }
    
    private func messageInputViewSetUp() {
        addSubview(messageInputView)
        
        messageInputView.delegate = self
        messageInputView.translatesAutoresizingMaskIntoConstraints = false
        
        messageInputViewHeightConstraint = messageInputView.heightAnchor.constraint(equalToConstant: 54)
        chatViewBottomConstraint = messageInputView.bottomAnchor.constraint(
            equalTo: bottomAnchor,
            constant: -40
        )
        
        guard let messageInputViewHeightConstraint = messageInputViewHeightConstraint,
              let chatViewBottomConstraint = chatViewBottomConstraint else {
            fatalError("chatViewBottomConstraint가 초기화되지 않았습니다.")
        }
        
        NSLayoutConstraint.activate([
            messageInputViewHeightConstraint,
            chatViewBottomConstraint,
            messageInputView.leftAnchor.constraint(equalTo: leftAnchor),
            messageInputView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
    
    private func chattingTableViewSetUp() {
        addSubview(chattingTableView)
        
        chattingTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            chattingTableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            chattingTableView.bottomAnchor.constraint(equalTo: messageInputView.topAnchor),
            chattingTableView.leftAnchor.constraint(equalTo: leftAnchor),
            chattingTableView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
        
        chattingTableView.separatorStyle = .none
        chattingTableView.backgroundColor = UIColor.appColor(.backgroundMain)
        chattingTableView.allowsSelection = false
        chattingTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MessageCell")
    }
    
    func scrollToBottom() {
        let rows = chattingTableView.numberOfRows(inSection: 0)
        guard 0 < rows else { return }
        
        let indexPath = IndexPath(row: rows - 1, section: 0)
        chattingTableView.scrollToRow(
            at: indexPath,
            at: .bottom,
            animated: false
        )
    }
    
    func setTableViewDelegate(_ delegate: UITableViewDelegate & UITableViewDataSource) {
        chattingTableView.delegate = delegate
        chattingTableView.dataSource = delegate
    }

    func updateBottomConstraintForKeyboard(height: CGFloat) {
        chatViewBottomConstraint?.constant = -height
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
}

extension ChatView: MessageInputViewDelegate {
    func updateMessageInputViewHeight(to height: CGFloat) {
        guard let messageInputViewHeightConstraint = messageInputViewHeightConstraint else {
            fatalError("chatViewBottomConstraint가 초기화되지 않았습니다.")
        }
        
        messageInputViewHeightConstraint.constant = height
        UIView.performWithoutAnimation {
            self.layoutIfNeeded()
        }
    }
}

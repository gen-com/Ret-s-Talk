//
//  ChatView.swift
//  RetsTalk
//
//  Created by KimMinSeok on 11/13/24.
//

import UIKit

@MainActor
protocol ChatViewDelegate: AnyObject {
    func willSendMessage(from chatView: ChatView, with content: String) -> Bool
    func didTapRetryButton(_ retryButton: UIButton)
}

final class ChatView: BaseView {
    
    // MARK: Subviews
    
    private let chatTableView: UITableView = {
        let tableView = UITableView()
        tableView.scrollsToTop = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .backgroundMain
        tableView.allowsSelection = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Texts.messageCellIdentifier)
        return tableView
    }()
    private let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.color = .blazingOrange
        return activityIndicatorView
    }()
    private let retryView: RetryView = {
        let retryView = RetryView()
        retryView.isHidden = true
        return retryView
    }()
    private let messageInputView = MessageInputView()
    
    // MARK: Layout constraint
    
    private var chatViewBottomConstraint: NSLayoutConstraint?

    // MARK: RetsTalk lifecycle
    
    override func setupStyles() {
        super.setupStyles()
        
        backgroundColor = .backgroundMain
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        
        addSubview(chatTableView)
        addSubview(activityIndicatorView)
        addSubview(retryView)
        addSubview(messageInputView)
    }
    
    override func setupLayouts() {
        super.setupLayouts()
        
        setupChatTableViewLayouts()
        setupActivityIndicatorViewLayouts()
        setupRetryViewLayouts()
        setupMessageInputViewLayouts()
    }
    
    override func setupDelegation() {
        super.setupDelegation()
        
        messageInputView.delegate = self
    }
    
    override func setupActions() {
        super.setupActions()
        
        retryView.addAction { [weak self] in
            guard let self else { return }
            
            self.delegate?.didTapRetryButton(self.retryView.retryButton)
        }
    }
    
    // MARK: Delegation
    
    weak var delegate: ChatViewDelegate?
    
    func setChatTableViewDelegate(_ delegate: UITableViewDelegate & UITableViewDataSource) {
        chatTableView.delegate = delegate
    }
    
    func setChatTableViewDataSource(_ delegate: UITableViewDataSource) {
        chatTableView.dataSource = delegate
    }
    
    // MARK: TableView actions
    
    func scrollToBottom() {
        let rows = chatTableView.numberOfRows(inSection: 0)
        guard 0 < rows else { return }
        
        let indexPath = IndexPath(row: rows - 1, section: 0)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
    
    func insertMessages(at indexPaths: [IndexPath]) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        chatTableView.insertRows(at: indexPaths, with: .none)
        CATransaction.commit()
    }
    
    // MARK: Keyboard action
    
    func updateLayoutForKeyboard(using keyboardInfo: KeyboardInfo) {
        let willKeyboardShow = 0 < keyboardInfo.frame.height
        let updatedChatViewBottomConstant = -(keyboardInfo.frame.height - safeAreaInsets.bottom)
        chatViewBottomConstraint?.constant = min(updatedChatViewBottomConstant, 0)
        UIView.animate(withDuration: keyboardInfo.animationDuration) { [self] in
            layoutIfNeeded()
            if willKeyboardShow {
                scrollToBottom()
            }
        }
    }
    
    func addTapGestureToDismissKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
        chatTableView.addGestureRecognizer(gestureRecognizer)
    }
    
    // MARK: Retrospect Status handling
    
    func updateChatView(by status: Retrospect.Status) {
        switch status {
        case .finished:
            messageInputView.isHidden = true
        case .inProgress(.waitingForUserInput):
            setViewAsWaitingForUserInput()
        case .inProgress(.waitingForResponse):
            setViewAsWaitingForResponse()
        case .inProgress(.responseErrorOccurred):
            setViewAsResponseErrorOccurred()
        }
    }
    
    private func setViewAsWaitingForUserInput() {
        activityIndicatorView.stopAnimating()
        messageInputView.isMessageSendable = true
    }
    
    private func setViewAsWaitingForResponse() {
        retryView.isHidden = true
        activityIndicatorView.startAnimating()
        messageInputView.isMessageSendable = false
    }
    
    private func setViewAsResponseErrorOccurred() {
        activityIndicatorView.stopAnimating()
        retryView.isHidden = false
        messageInputView.isMessageSendable = false
    }
}

// MARK: - MessageInputViewDelegate

extension ChatView: MessageInputViewDelegate {
    func messageInputView(_ messageInputView: MessageInputView, shouldSendMessageWith content: String) -> Bool {
        delegate?.willSendMessage(from: self, with: content) ?? false
    }
}

// MARK: - Subviews layouts

fileprivate extension ChatView {
    func setupChatTableViewLayouts() {
        chatTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            chatTableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            chatTableView.bottomAnchor.constraint(equalTo: messageInputView.topAnchor),
            chatTableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            chatTableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        ])
    }
    
    func setupMessageInputViewLayouts() {
        messageInputView.translatesAutoresizingMaskIntoConstraints = false
        
        let messageInputViewBottomConstraint = messageInputView.bottomAnchor.constraint(
            equalTo: safeAreaLayoutGuide.bottomAnchor
        )
        NSLayoutConstraint.activate([
            messageInputViewBottomConstraint,
            messageInputView.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            messageInputView.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
        ])
        chatViewBottomConstraint = messageInputViewBottomConstraint
    }
    
    func setupActivityIndicatorViewLayouts() {
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            activityIndicatorView.bottomAnchor.constraint(
                equalTo: messageInputView.topAnchor,
                constant: -Metrics.defaultPadding
            ),
            activityIndicatorView.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: Metrics.defaultPadding
            ),
        ])
    }
    
    func setupRetryViewLayouts() {
        retryView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            retryView.bottomAnchor.constraint(
                equalTo: messageInputView.topAnchor,
                constant: -Metrics.defaultPadding
            ),
            retryView.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: Metrics.defaultPadding
            ),
            retryView.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -Metrics.defaultPadding
            ),
        ])
    }
}

// MARK: - Constants

private extension ChatView {
    enum Metrics {
        static let messageInputViewHeight = 27.0
        static let chatViewBottomFromBottom = -40.0
        static let defaultPadding = 16.0
    }
    
    enum Texts {
        static let messageCellIdentifier = "MessageCell"
    }
}

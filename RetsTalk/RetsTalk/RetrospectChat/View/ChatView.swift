//
//  ChatView.swift
//  RetsTalk
//
//  Created on 11/13/24.
//

import UIKit

final class ChatView: BaseView {
    
    // MARK: Subviews
    
    private let messageCollectionView = MessageCollectionView()
    private let messageInputView = MessageInputView()
    private let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.color = .blazingOrange
        return activityIndicatorView
    }()
    private let retryView = RetryView()
    
    // MARK: DataSource & Delegate
    
    weak var dataSource: ChatViewDataSource?
    weak var delegate: ChatViewDelegate?

    // MARK: RetsTalk lifecycle
    
    override func setupStyles() {
        super.setupStyles()
        
        backgroundColor = .backgroundMain
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        
        addSubview(messageCollectionView)
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
    
    override func setupDataSource() {
        super.setupDataSource()
        
        messageCollectionView.dataSource = self
    }
    
    override func setupDelegation() {
        super.setupDelegation()
        
        messageCollectionView.delegate = self
        messageInputView.delegate = self
        retryView.delegate = self
    }
    
    // MARK: Updating collectionView
    
    func updateMessageCollectionViewItems(with indexPathDifferences: [IndexPath]) {
        guard indexPathDifferences.isNotEmpty else { return }
        
        messageCollectionView.updateItems(with: indexPathDifferences)
    }
    
    // MARK: Keyboard action
    
    func updateLayoutForKeyboard(using keyboardInfo: KeyboardInfo) {
        messageCollectionView.updateTopInset(keyboardInfo.frame.height)
    }
    
    func addTapGestureToDismissKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
        messageCollectionView.addGestureRecognizer(gestureRecognizer)
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
        activityIndicatorView.startAnimating()
        retryView.isHidden = true
        messageInputView.isMessageSendable = false
    }
    
    private func setViewAsResponseErrorOccurred() {
        activityIndicatorView.stopAnimating()
        retryView.isHidden = false
        messageInputView.isMessageSendable = false
    }
}

// MARK: - MessageCollectionViewDataSource conformance

extension ChatView: MessageCollectionViewDataSource {
    func numberOfMessages(in messageCollectionView: MessageCollectionView) -> Int {
        dataSource?.numberOfMessages(in: self) ?? 0
    }
    
    func messageCollectionView(
        _ messageCollectionView: MessageCollectionView,
        messageForItemAt indexPath: IndexPath
    ) -> Message? {
        dataSource?.chatView(self, messageForItemAt: indexPath)
    }
}

// MARK: - MessageCollectionViewDelegate conformance

extension ChatView: MessageCollectionViewDelegate {
    func messageCollectionViewDidReachPrependablePoint(_ messageCollectionView: MessageCollectionView) {
        delegate?.chatViewDidReachPrependablePoint(self)
    }
}

// MARK: - MessageInputViewDelegate conformance

extension ChatView: MessageInputViewDelegate {
    func messageInputView(_ messageInputView: MessageInputView, shouldSendMessageWith content: String) -> Bool {
        delegate?.chatView(self, shouldSendMessageWith: content) ?? false
    }
    
    func messageInputView(_ messageInputView: MessageInputView, didSendMessage content: String) {
        delegate?.chatView(self, didSendMessage: content)
    }
}

// MARK: - RetryViewDelegate conformance

extension ChatView: RetryViewDelegate {
    func retryView(_ retryView: RetryView, didTapRetryButton sender: UIButton) {
        delegate?.chatView(self, didTapRetryButton: sender)
    }
}

// MARK: - Subviews layouts

fileprivate extension ChatView {
    func setupChatTableViewLayouts() {
        messageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageCollectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            messageCollectionView.bottomAnchor.constraint(equalTo: messageInputView.topAnchor),
            messageCollectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            messageCollectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        ])
    }
    
    func setupMessageInputViewLayouts() {
        messageInputView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageInputView.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: Metrics.defaultPadding
            ),
            messageInputView.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -Metrics.defaultPadding
            ),
            messageInputView.bottomAnchor.constraint(
                equalTo: safeAreaLayoutGuide.bottomAnchor
            ),
        ])
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

fileprivate extension ChatView {
    enum Metrics {
        static let messageInputViewHeight = 27.0
        static let chatViewBottomFromBottom = -40.0
        static let defaultPadding = 16.0
    }
}

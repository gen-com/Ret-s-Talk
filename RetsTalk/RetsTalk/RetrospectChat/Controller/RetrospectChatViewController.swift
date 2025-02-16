//
//  RetrospectChatViewController.swift
//  RetsTalk
//
//  Created on 11/13/24.
//

@preconcurrency import Combine
import SwiftUI
import UIKit

final class RetrospectChatViewController: BaseKeyBoardViewController {
    private let retrospectChatManager: RetrospectChatManageable
    
    private var retrospect: Retrospect
    
    // MARK: View
    
    private let chatView = ChatView()
    
    private var rightBarButtonItem: UIBarButtonItem {
        switch retrospect.status {
        case .finished:
            UIBarButtonItem(
                image: retrospect.isPinned ? .pinned : .unpinned,
                primaryAction: UIAction(handler: { [weak self] _ in self?.toggleRetrospectPin() })
            )
        case .inProgress:
            UIBarButtonItem(
                title: Texts.endChattingButtonTitle,
                primaryAction: UIAction(handler: { [weak self] _ in self?.endRetrospectChat() })
            )
        }
    }
    
    // MARK: Initialization
    
    init(retrospect: Retrospect, retrospectChatManager: RetrospectChatManageable) {
        self.retrospect = retrospect
        self.retrospect.removeAllChat()
        self.retrospectChatManager = retrospectChatManager
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: ViewController lifecycle
    
    override func loadView() {
        view = chatView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addTapGestureOfDismissingKeyboard()
    }
    
    // MARK: RetsTalk lifecycle
    
    override func setupDataSource() {
        super.setupDataSource()
        
        chatView.dataSource = self
    }
    
    override func setupDelegation() {
        super.setupDelegation()
        
        chatView.delegate = self
    }
    
    override func setupNavigationBar() {
        super.setupNavigationBar()
        
        title = retrospect.createdAt.formattedToKoreanStyle
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    override func setupSubscription() {
        super.setupSubscription()
        
        subscribeRetrospectManager()
        subscribeRetrospectManagerError()
    }
    
    // MARK: Subscriptions
    
    private func subscribeRetrospectManager() {
        Task {
            await retrospectChatManager.retrospectPublisher
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] updatedRetrospect in
                    self?.updateChatView(with: updatedRetrospect)
                    self?.requestAssistantMessageIfNeeded()
                })
                .store(in: &subscriptionSet)
        }
    }
    
    private func subscribeRetrospectManagerError() {
        Task {
            await retrospectChatManager.errorPublisher
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] error in
                    self?.presentAlert(for: .error(error), actions: [.close()])
                })
                .store(in: &subscriptionSet)
        }
    }
    
    // MARK: Retrospect chat manager action
    
    private func fetchPreviousChat(isInitial: Bool) {
        Task {
            await retrospectChatManager.fetchPreviousMessages()
        }
    }
    
    private func sendUserMessage(with content: String) {
        Task {
            await retrospectChatManager.sendMessage(content)
        }
    }
    
    private func requestAssistantMessage() {
        Task {
            await retrospectChatManager.requestAssistantMessage()
        }
    }
    
    private func requestAssistantMessageIfNeeded() {
        guard retrospect.status == .inProgress(.waitingForUserInput),
              retrospect.chat.isEmpty
        else { return }
        
        requestAssistantMessage()
    }
    
    private func endRetrospectChat() {
        let confirmAction = UIAlertAction.confirm { [weak self] _ in
            Task {
                await self?.retrospectChatManager.endRetrospect()
                self?.navigationController?.popViewController(animated: true)
            }
        }
        presentAlert(for: .finish, actions: [.close(), confirmAction])
    }
    
    private func toggleRetrospectPin() {
        Task {
            await retrospectChatManager.toggleRetrospectPin()
            navigationItem.rightBarButtonItem = rightBarButtonItem
        }
    }
    
    // MARK: Updating views
    
    private func updateChatView(with updatedRetrospect: Retrospect) {
        let updatedIndexPaths = updatedIndexPaths(from: updatedRetrospect)
        retrospect = updatedRetrospect
        chatView.updateChatView(by: updatedRetrospect.status)
        chatView.updateMessageCollectionViewItems(with: updatedIndexPaths)
    }
    
    // MARK: Message difference managing
    
    private func updatedIndexPaths(from updatedRetrospect: Retrospect) -> [IndexPath] {
        var updatedIndexPaths = [IndexPath]()
        for (index, message) in updatedRetrospect.chat.enumerated() where retrospect.chat.notContains(message) {
            updatedIndexPaths.append(IndexPath(item: index, section: .zero))
        }
        return updatedIndexPaths
    }
    
    // MARK: Keyboard control
    
    override func handleKeyboardWillShowEvent(using keyboardInfo: KeyboardInfo) {
        super.handleKeyboardWillShowEvent(using: keyboardInfo)
        
        chatView.updateLayoutForKeyboard(using: keyboardInfo)
    }
    
    override func handleKeyboardWillHideEvent(using keyboardInfo: KeyboardInfo) {
        super.handleKeyboardWillHideEvent(using: keyboardInfo)
        
        chatView.updateLayoutForKeyboard(using: keyboardInfo)
    }
    
    private func addTapGestureOfDismissingKeyboard() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        chatView.addTapGestureToDismissKeyboard(tapGestureRecognizer)
    }
    
    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - ChatViewDataSource conformance

extension RetrospectChatViewController: ChatViewDataSource {
    func numberOfMessages(in chatView: ChatView) -> Int {
        retrospect.chat.count
    }
    
    func chatView(_ chatView: ChatView, messageForItemAt indexPath: IndexPath) -> Message? {
        retrospect.chat[indexPath.row]
    }
}

// MARK: - ChatViewDelegate conformance

extension RetrospectChatViewController: ChatViewDelegate {
    func willSendMessage(from chatView: ChatView, with content: String) -> Bool {
        sendUserMessage(with: content)
        return content.count <= Numerics.messageContentCountLimit
    }
    
    func didTapRetryButton(_ retryButton: UIButton) {
        requestAssistantMessage()
    }
    
    func chatViewDidReachPrependablePoint(_ chatView: ChatView) {
        fetchPreviousChat(isInitial: false)
    }
}

// MARK: - Constants

fileprivate extension RetrospectChatViewController {
    enum Numerics {
        static let prependingRatio = 0.2
        static let maxOffsetWhilePrepending = 1.0
        
        static let messageContentCountLimit = 100
    }
    
    enum Texts {
        static let endChattingButtonTitle = "끝내기"
    }
}

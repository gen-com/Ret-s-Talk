//
//  RetrospectChatViewController.swift
//  RetsTalk
//
//  Created on 11/13/24.
//

import SwiftUI
import UIKit

final class RetrospectChatViewController: BaseKeyBoardViewController {
    
    // MARK: Dependency
    
    private let retrospectChatManager: RetrospectChatManageable?
    
    private var retrospect: Retrospect
    
    // MARK: View
    
    private var rightBarButtonItem: UIBarButtonItem {
        switch retrospect.state {
        case .finished:
            UIBarButtonItem(
                image: retrospect.isPinned ? .unpinned : .pinned,
                primaryAction: UIAction { [weak self] _ in self?.retrospectChatManager?.toggleRetrospectPin() }
            )
        default:
            UIBarButtonItem(
                title: Texts.endChattingButtonTitle,
                primaryAction: UIAction { [weak self] _ in self?.endRetrospectChat() }
            )
        }
    }
    private let chatView = ChatView()
    
    // MARK: Initialization
    
    init(dependency: RetrospectChatDependency) {
        retrospectChatManager = RetrospectChatManager(dependency: dependency)
        retrospect = dependency.retrospect
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        retrospectChatManager = nil
        retrospect = Retrospect()
        
        super.init(coder: coder)
    }
    
    // MARK: ViewController lifecycle
    
    override func loadView() {
        view = chatView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addTapGestureOfDismissingKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task {
            retrospectChatManager?.fetchPreviousMessages()
        }
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
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    override func setupDataStream() {
        super.setupDataStream()
        
        setupRetrospectStream()
        setupErrorStream()
    }
    
    // MARK: Data stream setup
    
    private func setupRetrospectStream() {
        guard let retrospectChatManager else { return }
        
        let task = Task {
            for await updatedRetrospect in retrospectChatManager.retrospectStream {
                updateChatView(with: updatedRetrospect)
                requestAssistantMessageIfNeeded()
            }
        }
        taskSet.insert(task)
    }
    
    private func setupErrorStream() {
        guard let retrospectChatManager else { return }
        
        let task = Task {
            for await error in retrospectChatManager.errorStream {
                presentAlert(for: .error(error), actions: [.close()])
            }
        }
        taskSet.insert(task)
    }
   
    // MARK: Retrospect chat manager action
    
    private func requestAssistantMessageIfNeeded() {
        guard retrospect.state == .waitingForUserInput,
              retrospect.chat.isEmpty
        else { return }
        
        retrospectChatManager?.requestAssistantMessage()
    }
    
    private func endRetrospectChat() {
        let confirmAction = UIAlertAction.confirm { [weak self] _ in
            self?.retrospectChatManager?.endRetrospect()
            self?.navigationController?.popViewController(animated: true)
        }
        presentAlert(for: .finish, actions: [.close(), confirmAction])
    }
    
    // MARK: Updating views
    
    private func updateChatView(with updatedRetrospect: Retrospect) {
        let updatedIndexPaths = updatedIndexPaths(from: updatedRetrospect)
        retrospect = updatedRetrospect
        chatView.updateChatView(by: updatedRetrospect.state)
        chatView.updateMessageCollectionViewItems(with: updatedIndexPaths)
        navigationItem.rightBarButtonItem = rightBarButtonItem
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
        
        let bottomInset = view.safeAreaInsets.bottom
        additionalSafeAreaInsets.bottom = bottomInset
        UIView.animate(withDuration: keyboardInfo.animationDuration) { [self] in
            chatView.transform = CGAffineTransform(translationX: .zero, y: -(keyboardInfo.frame.height - bottomInset))
            chatView.updateLayoutForKeyboard(using: keyboardInfo)
        }
    }
    
    override func handleKeyboardWillHideEvent(using keyboardInfo: KeyboardInfo) {
        super.handleKeyboardWillHideEvent(using: keyboardInfo)
        
        additionalSafeAreaInsets.bottom = .zero
        UIView.animate(withDuration: keyboardInfo.animationDuration) { [self] in
            chatView.transform = .identity
            chatView.updateLayoutForKeyboard(using: keyboardInfo)
        }
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
    func chatViewDidReachPrependablePoint(_ chatView: ChatView) {
        retrospectChatManager?.fetchPreviousMessages()
    }
    
    func chatView(_ chatView: ChatView, shouldSendMessageWith content: String) -> Bool {
        content.count <= Numerics.messageContentCountLimit
    }
    
    func chatView(_ chatView: ChatView, didSendMessage content: String) {
        retrospectChatManager?.sendMessage(content)
    }
    
    func chatView(_ chatView: ChatView, didTapRetryButton sender: UIButton) {
        retrospectChatManager?.requestAssistantMessage()
    }
}

// MARK: - Constants

fileprivate extension RetrospectChatViewController {
    enum Numerics {
        static let messageContentCountLimit = 100
    }
    
    enum Texts {
        static let endChattingButtonTitle = "끝내기"
    }
}

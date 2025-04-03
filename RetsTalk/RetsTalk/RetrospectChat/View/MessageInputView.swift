//
//  MessageInputView.swift
//  RetsTalk
//
//  Created on 11/13/24.
//

import UIKit

final class MessageInputView: BaseView {
    
    // MARK: Property
    
    var isMessageSendable = false {
        didSet { updateSendButtonState() }
    }
    
    // MARK: Constraint
    
    private var heightLayoutConstraint: NSLayoutConstraint?
    
    // MARK: Subviews
    
    private let placeholderTextView: PlaceholderTextView = {
        let textView = PlaceholderTextView()
        textView.placeholderText = Texts.textInputPlaceholder
        return textView
    }()
    private let sendButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(.arrowUp, for: .normal)
        button.tintColor = .blazingOrange
        return button
    }()
    
    // MARK: Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let roundedRectPath = UIBezierPath(roundedRect: rect, cornerRadius: Metrics.backgroundCornerRadius)
        UIColor.secondarySystemFill.setFill()
        roundedRectPath.fill()
    }
    
    // MARK: RetsTalk lifecycle
    
    override func setupStyles() {
        super.setupStyles()
        
        backgroundColor = .systemBackground
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        
        addSubview(placeholderTextView)
        addSubview(sendButton)
    }
    
    override func setupLayouts() {
        super.setupLayouts()
        
        translatesAutoresizingMaskIntoConstraints = false
        heightLayoutConstraint = heightAnchor.constraint(equalToConstant: Metrics.defaultHeight)
        heightLayoutConstraint?.isActive = true
        
        setupSendButtonLayout()
        setupTextInputViewLayout()
    }
    
    override func setupDelegation() {
        super.setupDelegation()
        
        placeholderTextView.delegate = self
    }
    
    override func setupActions() {
        super.setupActions()
        
        let sendAction = UIAction { [weak self] _ in
            self?.sendMessageAction()
        }
        sendButton.addAction(sendAction, for: .touchUpInside)
    }
    
    // MARK: Delegation
    
    weak var delegate: MessageInputViewDelegate?
    
    // MARK: Actions
    
    private func sendMessageAction() {
        let content = placeholderTextView.text
        guard let delegate, delegate.messageInputView(self, shouldSendMessageWith: content)
        else { return }
        
        delegate.messageInputView(self, didSendMessage: content)
        placeholderTextView.clearText()
    }
    
    // MARK: Update subviews
    
    private func updateSendButtonState() {
        sendButton.isEnabled = isMessageSendable && placeholderTextView.text.isNotEmpty
    }
    
    private func updateViewHeight(to value: CGFloat) {
        let verticalMargin = 2 * Metrics.textViewMargin
        heightLayoutConstraint?.constant = value + verticalMargin
        setNeedsUpdateConstraints()
        setNeedsDisplay()
    }
}

// MARK: - PlaceholderTextViewDelegate conformance

extension MessageInputView: PlaceholderTextViewDelegate {
    func textViewDidChange(_ placeholderTextView: PlaceholderTextView) {
        let adjustedTextViewHeight = min(placeholderTextView.fittingContentSize.height, Metrics.textViewMaxHeight)
        let didReachMaxHeight = Metrics.textViewMaxHeight <= adjustedTextViewHeight
        placeholderTextView.isScrollEnabled = didReachMaxHeight
        updateViewHeight(to: adjustedTextViewHeight)
        updateSendButtonState()
    }
 }

// MARK: - Subviews layouts

fileprivate extension MessageInputView {
    func setupTextInputViewLayout() {
        placeholderTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderTextView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: Metrics.textViewMargin
            ),
            placeholderTextView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -Metrics.textViewMargin
            ),
            placeholderTextView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Metrics.textViewMargin
            ),
            placeholderTextView.trailingAnchor.constraint(
                equalTo: sendButton.leadingAnchor,
                constant: -Metrics.sendButtonMargin
            ),
        ])
    }
    
    func setupSendButtonLayout() {
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sendButton.heightAnchor.constraint(
                equalToConstant: Metrics.sendButtonLength
            ),
            sendButton.widthAnchor.constraint(
                equalToConstant: Metrics.sendButtonLength
            ),
            sendButton.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -Metrics.sendButtonMargin
            ),
            sendButton.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Metrics.sendButtonMargin
            ),
        ])
    }
}

// MARK: - Constants

fileprivate extension MessageInputView {
    enum Metrics {
        static let defaultHeight = 47.0
        static let backgroundCornerRadius = 10.0

        static let sendButtonLength = 27.0
        static let sendButtonMargin = 10.0

        static let textViewMaxHeight = 100.0
        static let textViewMargin = 10.0
    }

    enum Texts {
        static let textInputPlaceholder = "메시지를 입력하세요 (최대 100자)"
    }
}

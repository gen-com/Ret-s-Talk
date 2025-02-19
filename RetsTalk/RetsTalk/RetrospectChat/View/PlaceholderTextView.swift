//
//  PlaceholderTextView.swift
//  RetsTalk
//
//  Created on 12/14/24.
//

import UIKit

// MARK: - Delegation

@MainActor
protocol PlaceholderTextViewDelegate: AnyObject {
    func textViewDidChange(_ placeholderTextView: PlaceholderTextView)
}

extension PlaceholderTextViewDelegate {
    func textViewDidChange(_ placeholderTextView: PlaceholderTextView) {}
}

// MARK: - View

final class PlaceholderTextView: BaseView {
    
    // MARK: Property
    
    private(set) var fittingContentSize: CGSize = .zero
    
    var text: String {
        textView.text
    }
    
    var placeholderText: String? {
        didSet { placeholderLabel.text = placeholderText }
    }
    var isScrollEnabled: Bool {
        get { textView.isScrollEnabled }
        set { textView.isScrollEnabled = newValue }
    }
    
    // MARK: Delegate
    
    weak var delegate: PlaceholderTextViewDelegate?
    
    // MARK: Subviews
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.font = .appFont(.body)
        return textView
    }()
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .appFont(.body)
        label.textColor = .placeholderText
        return label
    }()
    
    // MARK: Custom lifecycle
    
    override func setupSubviews() {
        super.setupSubviews()
        
        addSubview(textView)
        textView.addSubview(placeholderLabel)
    }
    
    override func setupLayouts() {
        super.setupLayouts()
        
        setupTextViewLayouts()
        setupPlaceholderLabelLayouts()
    }
    
    override func setupDelegation() {
        super.setupDelegation()
        
        textView.delegate = self
    }
    
    // MARK: Text edit
    
    func clearText() {
        textView.text.removeAll()
        textViewDidChange(textView)
    }
}

// MARK: - UITextViewDelegate conformance

extension PlaceholderTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = textView.text.isNotEmpty
        fittingContentSize = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .infinity))
        delegate?.textViewDidChange(self)
    }
}

// MARK: - Subview layouts

fileprivate extension PlaceholderTextView {
    private func setupTextViewLayouts() {
        textView.textContainerInset = UIEdgeInsets(
            top: Metrics.textPadding,
            left: .zero,
            bottom: Metrics.textPadding,
            right: .zero
        )
        textView.textContainer.lineFragmentPadding = Metrics.textPadding
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    private func setupPlaceholderLabelLayouts() {
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(
                equalTo: textView.topAnchor,
                constant: Metrics.textPadding
            ),
            placeholderLabel.leadingAnchor.constraint(
                equalTo: textView.leadingAnchor,
                constant: Metrics.textPadding
            ),
            placeholderLabel.trailingAnchor.constraint(
                equalTo: textView.trailingAnchor,
                constant: -Metrics.textPadding
            ),
            placeholderLabel.bottomAnchor.constraint(
                equalTo: textView.bottomAnchor,
                constant: -Metrics.textPadding
            ),
        ])
    }
}

// MARK: - Costants

fileprivate extension PlaceholderTextView {
    enum Metrics {
        static let textPadding = 5.0
    }
}

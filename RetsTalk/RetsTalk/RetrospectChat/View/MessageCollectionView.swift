//
//  MessageCollectionView.swift
//  RetsTalk
//
//  Created on 2/5/25.
//

import UIKit

final class MessageCollectionView: BaseView {
    
    // MARK: Properties
    
    private var lastPrependOffsetY = CGFloat.zero
    
    // MARK: Subview
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: messageCollectionViewLayout)
        collectionView.register(
            MessageCollectionViewCell.self,
            forCellWithReuseIdentifier: MessageCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()
    private let messageCollectionViewLayout = MessageCollectionViewLayout()
    
    // MARK: DataSource & Delegate
    
    weak var dataSource: MessageCollectionViewDataSource?
    weak var delegate: MessageCollectionViewDelegate?
    
    // MARK: RetsTalk lifecycle
    
    override func setupSubviews() {
        super.setupSubviews()
        
        addSubview(collectionView)
    }
    
    override func setupLayouts() {
        super.setupLayouts()
        
        setupCollectionViewLayout()
    }
    
    override func setupDataSource() {
        super.setupDataSource()
        
        collectionView.dataSource = self
        messageCollectionViewLayout.dataSource = self
    }
    
    override func setupDelegation() {
        super.setupDelegation()
        
        collectionView.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        messageCollectionViewLayout.recalculateLayouts()
        collectionView.reloadData()
    }
    
    // MARK: Managing items
    
    func updateItems(with indexPathDifferences: [IndexPath]) {
        collectionView.reloadData()
        messageCollectionViewLayout.updateLayout(for: indexPathDifferences)
    }
    
    func updateTopInset(_ value: CGFloat) {
        collectionView.contentInset.top = value
        collectionView.verticalScrollIndicatorInsets.top = value
    }
}

// MARK: - UICollectionViewDataSource conformance

extension MessageCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource?.numberOfMessages(in: self) ?? .zero
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let message = dataSource?.messageCollectionView(self, messageForItemAt: indexPath),
              let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MessageCollectionViewCell.reuseIdentifier,
                for: indexPath
              ) as? MessageCollectionViewCell
        else { return UICollectionViewCell() }
        
        cell.configure(with: message, width: collectionView.bounds.width)
        return cell
    }
}

// MARK: - UICollectionViewDelegate conformance

extension MessageCollectionView: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView)
        let contentHeight = scrollView.contentSize.height
        let currentOffsetY = scrollView.contentOffset.y
        
        let isScrollDown = .zero < translation.y
        let didReachPrependablePoint = currentOffsetY < contentHeight * Numerics.prependingYRatio
        let isGreaterThanOrEqualToLastPrependOffsetY = lastPrependOffsetY <= currentOffsetY
        
        if isScrollDown, didReachPrependablePoint, isGreaterThanOrEqualToLastPrependOffsetY {
            lastPrependOffsetY = currentOffsetY
            delegate?.messageCollectionViewDidReachPrependablePoint(self)
        }
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        lastPrependOffsetY = .zero
    }
}

// MARK: - MessageCollectionViewLayoutDataSource conformance

extension MessageCollectionView: MessageCollectionViewLayoutDataSource {
    func messageCollectionViewLayout(
        _ messageCollectionViewLayout: MessageCollectionViewLayout,
        messageForItemAt indexPath: IndexPath
    ) -> Message? {
        dataSource?.messageCollectionView(self, messageForItemAt: indexPath)
    }
}

// MARK: - Subview layout

fileprivate extension MessageCollectionView {
    func setupCollectionViewLayout() {
        collectionView.collectionViewLayout = messageCollectionViewLayout
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

// MARK: - Constants

fileprivate extension MessageCollectionView {
    enum Numerics {
        static let prependingYRatio = 0.1
    }
}

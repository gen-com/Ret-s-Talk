//
//  RetrospectView.swift
//  RetsTalk
//
//  Created on 11/18/24.
//

import UIKit

final class RetrospectListView: BaseView {
    
    // MARK: Subviews
    
    private let retrospectListTableView = RetrospectListTableView()
    private let createRetrospectButton = CreateRetrospectButton()
    
    // MARK: Delegate
    
    weak var delegate: RetrospectListViewDelegate?
    
    // MARK: RetsTalk lifecycle
    
    override func setupSubviews() {
        super.setupSubviews()
        
        addSubview(retrospectListTableView)
        addSubview(createRetrospectButton)
    }
    
    override func setupLayouts() {
        super.setupLayouts()
        
        setupTableViewLayouts()
        setupCreateButtonLayouts()
    }
    
    override func setupDelegation() {
        retrospectListTableView.delegate = self
    }
    
    override func setupActions() {
        super.setupSubviews()
        
        let createRetrospectAction = UIAction { [weak self] _ in
            guard let self else { return }
            
            self.delegate?.retrospectListView(self, didTapCreateRetrospectButton: self.createRetrospectButton)
        }
        createRetrospectButton.addAction(createRetrospectAction, for: .touchUpInside)
    }
    
    // MARK: Update dataSource
    
    func updateDataSource(with retrospectList: RetrospectList) {
        retrospectListTableView.updateDataSource(with: retrospectList)
    }
}

// MARK: - RetrospectListTableViewDelegate conformance

extension RetrospectListView: RetrospectListTableViewDelegate {
    func retrospectListTableView(
        _ retrospectListTableView: RetrospectListTableView,
        didSelectRetrospectAt indexPath: IndexPath
    ) {
        delegate?.retrospectListView(self, didSelectRetrospectAt: indexPath)
    }
    
    func retrospectListTableView(
        _ retrospectListTableView: RetrospectListTableView,
        didTogglePinRetrospectAt indexPath: IndexPath
    ) {
        delegate?.retrospectListView(self, didTogglePinRetrospectAt: indexPath)
    }
    
    func retrospectListTableView(
        _ retrospectListTableView: RetrospectListTableView,
        didDeleteRetrospectAt indexPath: IndexPath
    ) {
        delegate?.retrospectListView(self, didDeleteRetrospectAt: indexPath)
    }
    
    func retrospectListTableView(
        _ retrospectListTableView: RetrospectListTableView,
        didReachAppendablePoint point: CGPoint
    ) {
        delegate?.retrospectListView(self, didReachAppendablePoint: point)
    }
}

// MARK: - Subviews layouts

fileprivate extension RetrospectListView {
    func setupTableViewLayouts() {
        retrospectListTableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            retrospectListTableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            retrospectListTableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            retrospectListTableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            retrospectListTableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
        ])
    }
    
    func setupCreateButtonLayouts() {
        createRetrospectButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            createRetrospectButton.bottomAnchor.constraint(
                equalTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -Metrics.buttonBottomMargin
            ),
            createRetrospectButton.centerXAnchor.constraint(
                equalTo: centerXAnchor
            ),
            createRetrospectButton.widthAnchor.constraint(
                equalToConstant: Metrics.diameter
            ),
            createRetrospectButton.heightAnchor.constraint(
                equalToConstant: Metrics.diameter
            ),
        ])
        
        bringSubviewToFront(createRetrospectButton)
    }
}

// MARK: - Constants

fileprivate extension RetrospectListView {
    enum Metrics {
        static let diameter = 80.0
        static let buttonBottomMargin = 10.0
    }
}

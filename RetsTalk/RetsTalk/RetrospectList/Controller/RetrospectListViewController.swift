//
//  RetrospectListViewController.swift
//  RetsTalk
//
//  Created on 11/18/24.
//

import SwiftUI
import UIKit

final class RetrospectListViewController: BaseViewController {
    
    // MARK: Dependencies
    
    private let dependency: RetrospectListDependency?
    private let retrospectListManager: RetrospectListManageable?
    
    private var retrospectList: RetrospectList
    
    // MARK: View
    
    private let retrospectListView = RetrospectListView()
    
    // MARK: Initializers
    
    init(dependency: RetrospectListDependency) {
        self.dependency = dependency
        retrospectListManager = RetrospectListManager(dependency: dependency)
        retrospectList = RetrospectList()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        dependency = nil
        retrospectListManager = nil
        retrospectList = RetrospectList()
        
        super.init(coder: coder)
    }
    
    // MARK: Lifecycle
    
    override func loadView() {
        view = retrospectListView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task {
            retrospectListManager?.fetchRetrospects()
        }
    }

    // MARK: RetsTalk lifecycle
    
    override func setupNavigationBar() {
        super.setupNavigationBar()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        title = Texts.navigationTitle
    }
    
    override func setupDelegation() {
        super.setupDelegation()
        
        retrospectListView.delegate = self
    }
    
    override func setupDataStream() {
        super.setupDataStream()
        
        createRetrospectListStream()
        setupRetrospectListStream()
        setupErrorStream()
    }
    
    // MARK: Data stream setup
    
    func createRetrospectListStream() {
        guard let retrospectListManager else { return }
        
        let task = Task {
            for await createdRetrospect in retrospectListManager.creationStream {
                pushToChat(for: createdRetrospect)
            }
        }
        taskSet.insert(task)
    }
    
    func setupRetrospectListStream() {
        guard let retrospectListManager else { return }
        
        let task = Task {
            for await updatedList in retrospectListManager.listStream {
                retrospectList = updatedList
                retrospectListView.updateDataSource(with: updatedList)
            }
        }
        taskSet.insert(task)
    }
    
    func setupErrorStream() {
        guard let retrospectListManager else { return }
        
        let task = Task {
            for await error in retrospectListManager.errorStream {
                presentAlert(for: .error(error), actions: [.confirm()])
            }
        }
        taskSet.insert(task)
    }
    
    // MARK: Navigation
    
    private func pushToChat(for retrospect: Retrospect) {
        guard let dependency, let retrospectListManager else { return }
        
        let retrospectChatDependency = dependency.retrospectChatDependency(
            for: retrospect,
            on: retrospectListManager
        )
        let retrospectChatViewController = RetrospectChatViewController(dependency: retrospectChatDependency)
        navigationController?.pushViewController(retrospectChatViewController, animated: true)
    }
}

// MARK: - RetrospectListViewDelegate conformance

extension RetrospectListViewController: RetrospectListViewDelegate {
    func retrospectListView(
        _ retrospectListView: RetrospectListView,
        didTapCreateRetrospectButton: CreateRetrospectButton
    ) {
        retrospectListManager?.createRetrospect()
    }
    
    func retrospectListView(_ retrospectListView: RetrospectListView, didSelectRetrospectAt indexPath: IndexPath) {
        guard let retrospect = retrospect(at: indexPath) else { return }
        
        pushToChat(for: retrospect)
    }
    
    func retrospectListView(_ retrospectListView: RetrospectListView, didTogglePinRetrospectAt indexPath: IndexPath) {
        guard var retrospect = retrospect(at: indexPath) else { return }
        
        retrospect.togglePin()
        retrospectListManager?.updateRetrospect(to: retrospect)
    }
    
    func retrospectListView(_ retrospectListView: RetrospectListView, didDeleteRetrospectAt indexPath: IndexPath) {
        guard let retrospect = retrospect(at: indexPath) else { return }
        
        retrospectListManager?.deleteRetrospect(retrospect)
    }
    
    private func retrospect(at indexPath: IndexPath) -> Retrospect? {
        switch Section(rawValue: indexPath.section) {
        case .pinned:
            retrospectList.pinned[indexPath.row]
        case .inProgress:
            retrospectList.inProgress[indexPath.row]
        case .finished:
            retrospectList.finished[indexPath.row]
        default:
            nil
        }
    }
}

// MARK: - Constants

fileprivate extension RetrospectListViewController {
    enum Section: Int {
        case pinned = 1
        case inProgress
        case finished
    }
    
    enum Texts {
        static let cancelAlertTitle = "취소"
        static let deleteAlertTitle = "삭제"
        static let confirmAlertTitle = "확인"
        
        static let settingButtonImageName = "gearshape"
        static let deleteIconImageName = "trash.fill"
        static let pinIconImageName = "pin.fill"
        static let unpinIconImageName = "pin.slash.fill"
        
        static let navigationTitle = "회고"
        static let defaultSummaryText = "대화를 종료해 요약을 확인하세요"
    }
}

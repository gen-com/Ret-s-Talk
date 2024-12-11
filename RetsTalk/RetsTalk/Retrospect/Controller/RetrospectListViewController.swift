//
//  RetrospectListViewController.swift
//  RetsTalk
//
//  Created by KimMinSeok on 11/18/24.
//

@preconcurrency import Combine
import SwiftUI
import UIKit

final class RetrospectListViewController: BaseViewController {
    typealias Situation = RetrospectListSituation
    private typealias Snapshot = NSDiffableDataSourceSnapshot<RetrospectSection, Retrospect>
    private typealias RetrospectDataSource = UITableViewDiffableDataSource<RetrospectSection, Retrospect>
    
    private let retrospectManager: RetrospectManageable
    private let userDefaultsManager: Persistable
    private let userSettingManager: UserSettingManager

    private var retrospectsSubject: CurrentValueSubject<SortedRetrospects, Never>
    private var fetchingDebounceSubject = PassthroughSubject<Void, Never>()
    private let errorSubject: PassthroughSubject<Error?, Never>
    
    private var dataSource: RetrospectDataSource?
    private var isRetrospectFetching: Bool
    private var isRetrospectAppendable: Bool
    
    private let isFirstLaunch: Bool
    
    // MARK: UI Components
    
    private let retrospectListView: RetrospectListView
    
    // MARK: Init Method
    
    init(
        retrospectManager: RetrospectManageable,
        userDefaultsManager: Persistable,
        isFirstLaunch: Bool
    ) {
        self.retrospectManager = retrospectManager
        self.userDefaultsManager = userDefaultsManager
        userSettingManager = UserSettingManager(userDataStorage: userDefaultsManager)

        retrospectListView = RetrospectListView()
        retrospectsSubject = CurrentValueSubject(SortedRetrospects())
        errorSubject = PassthroughSubject()
        
        self.isFirstLaunch = isFirstLaunch
        isRetrospectFetching = false
        isRetrospectAppendable = false
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: ViewController lifecycle
    
    override func loadView() {
        view = retrospectListView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addCreateButtondidTapAction()
        addCalendarButtonDidTapAction()
        fetchInitialRetrospect()
        onBoarding()
    }

    // MARK: RetsTalk lifecycle method
    
    override func setupNavigationBar() {
        title = Texts.navigationTitle
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: Texts.settingButtonImageName),
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.rightBarButtonItem = settingsButton
        navigationItem.rightBarButtonItem?.tintColor = .black
    }
    
    override func setupDelegation() {
        super.setupDelegation()
        
        retrospectListView.setTableViewDelegate(self)
        userSettingManager.cloudDelegate = self
    }
    
    override func setupDataSource() {
        super.setupDataSource()
        
        setupDiffableDataSource()
    }
    
    override func setupSubscription() {
        super.setupSubscription()
        
        addNotificationObserver()
        subscribeToRetrospectsPublisher()
        subscribeToRetrospects()
        subscribeToErrorPublisher()
        subscribeToError()
        subscribeToDebounce()
    }
    
    // MARK: OnBoarding handling
    
    private func onBoarding() {
        if isFirstLaunch {
            let onboarding = UIHostingController(rootView: OnBoardingView())
            present(onboarding, animated: true)
        }
    }
    
    // MARK: Regarding iCloud
    
    private func addNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refetchRetrospects),
            name: .coreDataImportedNotification,
            object: nil
        )
    }
    
    @objc private func refetchRetrospects() {
        fetchInitialRetrospect()
    }
    
    // MARK: Subscription method

    private func subscribeToRetrospectsPublisher() {
        Task {
            await retrospectManager.retrospectsPublisher
                .receive(on: RunLoop.main)
                .subscribe(retrospectsSubject)
                .store(in: &subscriptionSet)
        }
    }
    
    private func subscribeToRetrospects() {
        retrospectsSubject
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.updateSnapshot()
                self.updateTotalRetrospectCount()
            }
            .store(in: &subscriptionSet)
    }
    
    private func subscribeToErrorPublisher() {
        Task {
            await retrospectManager.errorPublisher
                .receive(on: RunLoop.main)
                .subscribe(errorSubject)
                .store(in: &subscriptionSet)
        }
    }
    
    private func subscribeToError() {
        errorSubject
            .sink { [weak self] error in
                guard let self, let error else { return }
                
                self.presentAlert(for: Situation.error(error), actions: [UIAlertAction.confirm()])
            }
            .store(in: &subscriptionSet)
    }
    
    private func subscribeToDebounce() {
        fetchingDebounceSubject
            .debounce(for: .seconds(Numerics.fetchingDebounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] in
                self?.fetchPreviousRetrospects()
            }
            .store(in: &subscriptionSet)
    }
    
    // MARK: Retrospect handling
    
    private func updateTotalRetrospectCount() {
        Task {
            guard let fetchedCount = await retrospectManager.fetchRetrospectsCount() else { return }
            
            retrospectListView.updateHeaderContent(
                totalCount: fetchedCount.totalCount,
                monthlyCount: fetchedCount.monthlyCount
            )
        }
    }

    private func fetchInitialRetrospect() {
        Task {
            await retrospectManager.fetchRetrospects(of: [.pinned, .inProgress, .finished])
            isRetrospectAppendable = true
        }
    }
    
    private func fetchPreviousRetrospects() {
        Task {
            let appendedCount = await retrospectManager.fetchPreviousRetrospects()
            isRetrospectFetching = false
            guard appendedCount != 0
            else {
                isRetrospectAppendable = false
                return
            }
        }
    }
    
    private func deleteRetrospect(_ retrospect: Retrospect) {
        presentAlert(
            for: .delete,
            actions: [
                UIAlertAction(title: Texts.cancelAlertTitle, style: .cancel),
                UIAlertAction(title: Texts.deleteAlertTitle, style: .destructive) { [weak self] _ in
                    guard let self else { return }

                    Task {
                        await self.retrospectManager.deleteRetrospect(retrospect)
                    }
                },
            ]
        )
    }
    
    private func togglepPinRetrospect(_ retrospect: Retrospect) {
        Task {
            await self.retrospectManager.togglePinRetrospect(retrospect)
        }
    }
    
    // MARK: Action controls
    
    @objc private func didTapSettings() {
        let userSettingViewController = UserSettingViewController(userSettingManager: userSettingManager)
        navigationController?.pushViewController(userSettingViewController, animated: true)
    }
    
    private func addCreateButtondidTapAction() {
        retrospectListView.addCreateButtonAction(
            UIAction { [weak self] _ in
                guard let self = self else { return }
                
                Task {
                    guard let retrospectChatManager = await retrospectManager.createRetrospect() else { return }
                    
                    let retrospectChatViewController = await RetrospectChatViewController(
                        retrospect: retrospectChatManager.retrospect,
                        retrospectChatManager: retrospectChatManager
                    )
                    navigationController?.pushViewController(retrospectChatViewController, animated: true)
                }
            }
        )
    }
    
    private func addCalendarButtonDidTapAction() {
        retrospectListView.addCalendarButtonAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                Task {
                    let retrospectCalendarManager = await retrospectManager.retrospectCalendarManager()
                    let retrospectCalendarViewController = RetrospectCalendarViewController(
                        retrospectCalendarManager: retrospectCalendarManager
                    )
                    navigationController?.pushViewController(retrospectCalendarViewController, animated: true)
                }
            }
        )
        
    }
}

// MARK: - UITableViewDiffableDataSource method

private extension RetrospectListViewController {
    func setupDiffableDataSource() {
        dataSource = RetrospectDataSource(
            tableView: retrospectListView.retrospectListTableView
        ) { tableView, indexPath, retrospect in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.Texts.retrospectCellIdentifier,
                for: indexPath
            )
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentConfiguration = UIHostingConfiguration {
                RetrospectCell(
                    summary: retrospect.summary ?? Texts.defaultSummaryText,
                    createdAt: retrospect.createdAt,
                    isPinned: retrospect.isPinned
                )
            }
            .margins(.vertical, Metrics.cellVerticalMargin)
            return cell
        }
    }
    
    func updateSnapshot() {
        var snapshot = Snapshot()
        let sortedRetrospects = retrospectsSubject.value
        for (index, sectionTitle) in RetrospectSection.allCases.enumerated() {
            let retrospects = sortedRetrospects[index]
            if !retrospects.isEmpty {
                snapshot.appendSections([sectionTitle])
                snapshot.appendItems(retrospects, toSection: sectionTitle)
            }
        }
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UITableViewDelegate conformance

extension RetrospectListViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let isNearBottom = offsetY > contentHeight - scrollView.frame.height - Metrics.fetchingOffsetThreshold
        guard isNearBottom,
              !isRetrospectFetching,
              isRetrospectAppendable
        else { return }
        
        isRetrospectFetching = true
        fetchingDebounceSubject.send()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sections = dataSource?.snapshot().sectionIdentifiers
        let headerView = SectionHeaderView(title: sections?[section].title)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Metrics.tableViewHeaderHeight
    }
    
    // MARK: SelectRow handling
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        guard let sections = dataSource?.snapshot().sectionIdentifiers.map({ $0.rawValue }) else { return }
        
        let section = sections[indexPath.section]
        let retrospect = retrospectsSubject.value[section][indexPath.row]
        Task {
            guard let retrospectChatManager = await retrospectManager.retrospectChatManager(of: retrospect)
            else { return }
            
            let chattingViewController = RetrospectChatViewController(
                retrospect: retrospect,
                retrospectChatManager: retrospectChatManager
            )
            navigationController?.pushViewController(chattingViewController, animated: true)
        }
    }
    
    // MARK: SwipeAction handling
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let sections = dataSource?.snapshot().sectionIdentifiers.map({ $0.rawValue }) else { return nil }
        
        let section = sections[indexPath.section]
        let selectedRetrospect = retrospectsSubject.value[section][indexPath.row]
        let configuration = UISwipeActionsConfiguration(actions: retrospectSwipeAction(selectedRetrospect))
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    private func retrospectSwipeAction(_ retrospect: Retrospect) -> [UIContextualAction] {
        let deleteAction = UIContextualAction.actionWithSystemImage(
            named: Texts.deleteIconImageName,
            tintColor: .red,
            action: { [weak self] in
                self?.deleteRetrospect(retrospect)
            },
            completionHandler: { _ in }
        )
        guard retrospect.status == .finished else { return [deleteAction] }
        
        let pinAction = pinAction(by: retrospect)
        return [deleteAction, pinAction]
    }
    
    private func pinAction(by retrospect: Retrospect) -> UIContextualAction {
        let pinToggleAction = { [weak self] in
            guard let self = self else { return }
            
            self.togglepPinRetrospect(retrospect)
        }
        
        let pinAction = UIContextualAction.actionWithSystemImage(
            named: Texts.pinIconImageName,
            tintColor: .blazingOrange,
            action: pinToggleAction,
            completionHandler: { _ in }
        )
        let unpinAction = UIContextualAction.actionWithSystemImage(
            named: Texts.unpinIconImageName,
            tintColor: .blazingOrange,
            action: pinToggleAction,
            completionHandler: { _ in }
        )
        
        return retrospect.isPinned ? unpinAction : pinAction
    }
}

// MARK: - UserSettingManageableCloudDelegete conformance

extension RetrospectListViewController: UserSettingManageableCloudDelegate {
    func didCloudSyncStateChange(_ userSettingManageable: any UserSettingManageable) {
        Task {
            let userData = userSettingManager.userData
            let isCloudSyncOn = userData.isCloudSyncOn
            await retrospectManager.refreshRetrospectStorage(iCloudEnabled: isCloudSyncOn)
        }
    }
}

// MARK: - AlertPresentable conformance

extension RetrospectListViewController: AlertPresentable {
    enum RetrospectListSituation: AlertSituation {
        case delete
        case error(Error)
        
        var title: String {
            switch self {
            case .delete:
                "회고를 삭제하시겠습니까?"
            case .error(let error as LocalizedError):
                error.errorDescription ?? "오류"
            default:
                "오류"
            }
        }
        
        var message: String {
            switch self {
            case .delete:
                "삭제된 회고는 복구할 수 없습니다."
            case .error(let error as LocalizedError):
                error.failureReason ?? ""
            default:
                ""
            }
        }
    }
}

// MARK: - Constants

private extension RetrospectListViewController {
    enum RetrospectSection: Int, CaseIterable, Hashable {
        case pinned
        case inProgress
        case finished
        
        var title: String {
            switch self {
            case .pinned:
                "고정됨"
            case .inProgress:
                "진행 중인 회고"
            case .finished:
                "지난 날의 회고"
            }
        }
    }
    
    enum Metrics {
        static let cellVerticalMargin = 6.0
        static let tableViewHeaderHeight = 36.0
        static let fetchingOffsetThreshold = 150.0
    }
    
    enum Numerics {
        static let fetchingDebounceInterval = 0.5
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

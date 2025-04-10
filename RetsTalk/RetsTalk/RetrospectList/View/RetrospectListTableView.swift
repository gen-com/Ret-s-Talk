//
//  RetrospectListTableView.swift
//  RetsTalk
//
//  Created on 3/11/25.
//

import UIKit

final class RetrospectListTableView: BaseView {
    
    // MARK: Typealias
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    // MARK: Property
    
    private var lastContentSize = CGSize.zero
    
    // MARK: Subviews
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.contentInset.bottom = Metrics.tableViewBottonPadding
        tableView.register(TitleHeaderView.self, forHeaderFooterViewReuseIdentifier: TitleHeaderView.reuseIdentifier)
        tableView.register(
            RetrospectCountTableViewCell.self,
            forCellReuseIdentifier: RetrospectCountTableViewCell.reuseIdentifier
        )
        tableView.register(
            RetrospectTableViewCell.self,
            forCellReuseIdentifier: RetrospectTableViewCell.reuseIdentifier
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderTopPadding = .zero
        tableView.separatorStyle = .none
        return tableView
    }()
    
    // MARK: DataSource & Delegate
    
    private lazy var dataSource: DataSource = {
        DataSource(tableView: tableView) { [unowned self] tableView, indexPath, item in
            cellProvider(tableView, indexPath, item)
        }
    }()
    
    weak var delegate: RetrospectListTableViewDelegate?
    
    // MARK: RetsTalk lifecycle
    
    override func setupSubviews() {
        super.setupSubviews()
        
        addSubview(tableView)
    }
    
    override func setupLayouts() {
        super.setupLayouts()
        
        setupTableViewLayouts()
    }
    
    override func setupDelegation() {
        super.setupDelegation()
        
        tableView.delegate = self
    }
    
    // MARK: Update dataSource
    
    func updateDataSource(with retrospectList: RetrospectList) {
        var snapShot = Snapshot()
        snapShot.appendSections([Section.count, .pinned, .inProgress, .finished])
        snapShot.appendItems([.count(retrospectList.count)], toSection: .count)
        snapShot.appendItems(retrospectList.pinned.map({ .retrospect($0) }), toSection: .pinned)
        snapShot.appendItems(retrospectList.inProgress.map({ .retrospect($0) }), toSection: .inProgress)
        snapShot.appendItems(retrospectList.finished.map({ .retrospect($0) }), toSection: .finished)
        dataSource.apply(snapShot)
    }
    
    // MARK: Cell provider
    
    private func cellProvider(
        _ tableView: UITableView,
        _ indexPath: IndexPath,
        _ item: Item
    ) -> UITableViewCell? {
        switch item {
        case let .count(count):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: RetrospectCountTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? RetrospectCountTableViewCell
            else { return UITableViewCell() }
            
            cell.configure(with: count)
            return cell
        case let .retrospect(retrospect):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: RetrospectTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? RetrospectTableViewCell
            else { return UITableViewCell() }
            
            cell.configure(with: retrospect)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate conformance

extension RetrospectListTableView: UITableViewDelegate {
    
    // MARK: Cell action
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
        case .pinned, .inProgress, .finished:
            delegate?.retrospectListTableView(self, didSelectRetrospectAt: indexPath)
        default:
            break
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let section = Section(rawValue: indexPath.section) else { return nil }
        
        let action = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            guard let self else { return }
            
            self.delegate?.retrospectListTableView(self, didTogglePinRetrospectAt: indexPath)
            completion(true)
        }
        action.backgroundColor = .blazingOrange
        
        switch section {
        case .count, .inProgress:
            return nil
        case .pinned:
            action.image = .unpinned
        case .finished:
            action.image = .pinned
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let section = Section(rawValue: indexPath.section), section != .count else { return nil }
        
        let action = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self else { return }
            
            self.delegate?.retrospectListTableView(self, didDeleteRetrospectAt: indexPath)
            completion(true)
        }
        action.image = .trash
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    // MARK: Appending retrospect
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset
        let appendingOffsetY = scrollView.contentSize.height * Numerics.appendingRatio - scrollView.bounds.height
        
        let didReachAppendingOffsetY = appendingOffsetY <= currentOffset.y
        let isScrollingDown = scrollView.panGestureRecognizer.translation(in: scrollView).y < .zero
        let didContentSizeIncreased = lastContentSize.height < scrollView.contentSize.height
        
        if didReachAppendingOffsetY, isScrollingDown, didContentSizeIncreased {
            lastContentSize = scrollView.contentSize
            delegate?.retrospectListTableView(self, didReachAppendablePoint: currentOffset)
        }
    }
    
    // MARK: Header configuration
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let snapshot = dataSource.snapshot()
        guard let section = Section(rawValue: section),
              snapshot.sectionIdentifiers.contains(section),
              0 < dataSource.snapshot().numberOfItems(inSection: section),
              let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: TitleHeaderView.reuseIdentifier
              ) as? TitleHeaderView
        else { return nil }
        
        switch section {
        case .pinned, .inProgress, .finished:
            headerView.configure(with: section.title)
            return headerView
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let snapshot = dataSource.snapshot()
        guard let section = Section(rawValue: section),
              snapshot.sectionIdentifiers.contains(section),
              0 < snapshot.numberOfItems(inSection: section)
        else { return .zero }
        
        switch section {
        case .pinned, .inProgress, .finished:
            return Metrics.titleHeaderHeight
        default:
            return .zero
        }
    }
}

// MARK: - Subviews layouts

fileprivate extension RetrospectListTableView {
    private func setupTableViewLayouts() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}

// MARK: - Nested section and item

fileprivate extension RetrospectListTableView {
    enum Section: Int {
        case count
        case pinned
        case inProgress
        case finished
        
        var title: String {
            switch self {
            case .pinned:
                "고정됨"
            case .inProgress:
                "진행중"
            case .finished:
                "종료됨"
            default:
                ""
            }
        }
    }
    
    enum Item: Hashable {
        case count(RetrospectList.Count)
        case retrospect(Retrospect)
    }
}

// MARK: - Constants

fileprivate extension RetrospectListTableView {
    enum Metrics {
        static let titleHeaderHeight = 50.0
        static let tableViewBottonPadding = 60.0
    }
    
    enum Numerics {
        static let appendingRatio = 0.9
    }
}

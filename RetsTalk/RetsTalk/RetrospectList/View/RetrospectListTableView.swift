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
    
    // MARK: Subviews
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.contentInset.bottom = Metrics.tableViewBottonPadding
        tableView.register(
            RetrospectTableViewCell.self,
            forCellReuseIdentifier: RetrospectTableViewCell.reuseIdentifier
        )
        tableView.rowHeight = UITableView.automaticDimension
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
        case .count:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
        case .pinned, .inProgress, .finished:
            delegate?.retrospectListTableView(self, didSelectRetrospectAt: indexPath)
        default:
            break
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
    }
    
    enum Item: Hashable {
        case count(RetrospectList.Count)
        case retrospect(Retrospect)
    }
}

// MARK: - Constants

fileprivate extension RetrospectListTableView {
    enum Metrics {
        static let tableViewBottonPadding = 60.0
    }
}

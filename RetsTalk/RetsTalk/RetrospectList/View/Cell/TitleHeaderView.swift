//
//  TitleHeaderView.swift
//  RetsTalk
//
//  Created on 12/2/24.
//

import UIKit

final class TitleHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "\(TitleHeaderView.self)"
    
    // MARK: Subviews
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appFont(.title)
        return label
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        setupSubviews()
        setupLayouts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupSubviews()
        setupLayouts()
    }
    
    // MARK: RetsTalk lifecycle
    
    func setupSubviews() {
        addSubview(titleLabel)
    }
    
    func setupLayouts() {
        setupTitleLabelLayouts()
    }
    
    // MARK: Configuration
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}

// MARK: - Subviews Layouts

fileprivate extension TitleHeaderView {
    func setupTitleLabelLayouts() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalPadding),
        ])
    }
    
    enum Metrics {
        static let horizontalPadding = 16.0
    }
}

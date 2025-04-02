//
//  TitleHeaderView.swift
//  RetsTalk
//
//  Created on 12/2/24.
//

import UIKit

final class TitleHeaderView: BaseView {
    
    // MARK: Subviews
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appFont(.title)
        return label
    }()
    
    // MARK: RetsTalk lifecycle
    
    override func setupSubviews() {
        super.setupSubviews()
        
        addSubview(titleLabel)
    }
    
    override func setupLayouts() {
        super.setupLayouts()
        
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

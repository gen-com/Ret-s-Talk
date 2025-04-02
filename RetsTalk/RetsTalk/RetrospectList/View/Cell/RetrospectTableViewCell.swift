//
//  RetrospectTableViewCell.swift
//  RetsTalk
//
//  Created on 3/11/25.
//

import SwiftUI
import UIKit

final class RetrospectTableViewCell: UITableViewCell {
    static let reuseIdentifier = "\(RetrospectTableViewCell.self)"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupStyle()
    }
    
    func setupStyle() {
        selectionStyle = .none
    }
    
    func configure(with retrospect: Retrospect) {
        contentConfiguration = UIHostingConfiguration {
            RetrospectView(
                summary: retrospect.summary,
                createdAt: retrospect.createdAt,
                isPinned: retrospect.isPinned
            )
        }
        .margins(.vertical, Metrics.margin)
    }
}

// MARK: - Constants

fileprivate extension RetrospectTableViewCell {
    enum Metrics {
        static let margin = 6.0
    }
}

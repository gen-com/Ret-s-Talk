//
//  RetrospectCountTableViewCell.swift
//  RetsTalk
//
//  Created on 3/30/25.
//

import SwiftUI
import UIKit

final class RetrospectCountTableViewCell: UITableViewCell {
    static let reuseIdentifier = "\(RetrospectCountTableViewCell.self)"
    
    // MARK: Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupStyle()
    }
    
    // MARK: Configuration
    
    func setupStyle() {
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    func configure(with count: RetrospectList.Count) {
        contentConfiguration = UIHostingConfiguration {
            RetrospectCountView(count: count)
        }
    }
}

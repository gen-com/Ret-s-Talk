//
//  BaseView.swift
//  RetsTalk
//
//  Created on 12/2/24.
//

import UIKit

class BaseView: UIView {
    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupStyles()
        setupSubviews()
        setupLayouts()
        setupDelegation()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupStyles()
        setupSubviews()
        setupLayouts()
        setupDelegation()
        setupActions()
    }
    
    // MARK: RetsTalk lifecycle
    
    func setupStyles() {}
    
    func setupSubviews() {}
    
    func setupLayouts() {}
    
    func setupDelegation() {}
    
    func setupActions() {}
}

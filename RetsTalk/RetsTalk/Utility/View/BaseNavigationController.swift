//
//  BaseNavigationController.swift
//  RetsTalk
//
//  Created on 12/5/24.
//

import UIKit

class BaseNavigationController: UINavigationController {
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        setupNavigationBar()
        
        view.backgroundColor = .systemBackground
    }
    
    // MARK: RetsTalk lifecycle

    func setupNavigationBar() {
        navigationBar.tintColor = .blazingOrange
    }
}

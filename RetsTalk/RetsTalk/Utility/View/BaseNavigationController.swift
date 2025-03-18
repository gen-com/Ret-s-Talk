//
//  BaseNavigationController.swift
//  RetsTalk
//
//  Created by HanSeung on 12/5/24.
//

import UIKit

class BaseNavigationController: UINavigationController {
    
    // MARK: Initialziers
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        
        setupNavigationBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupNavigationBar()
    }
    
    // MARK: RetsTalk lifecycle

    func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.backgroundColor = .systemBackground
        navigationBar.tintColor = .blazingOrange
    }
}

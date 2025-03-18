//
//  SplashViewController.swift
//  RetsTalk
//
//  Created on 3/9/25.
//

import UIKit

final class SplashViewController: BaseViewController {
    
    // MARK: Dependency
    
    private let component = SplashComponent()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        pushToRetrospectList()
    }
    
    // MARK: Navigation
    
    private func pushToRetrospectList() {
        Task {
            let retrospectListDependency = try await component.retrospectListDepenency()
            let retrospectListViewController = RetrospectListViewController(dependency: retrospectListDependency)
            navigationController?.pushViewController(retrospectListViewController, animated: false)
        }
    }
}

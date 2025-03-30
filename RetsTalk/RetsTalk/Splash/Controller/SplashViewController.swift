//
//  SplashViewController.swift
//  RetsTalk
//
//  Created on 3/9/25.
//

import UIKit

final class SplashViewController: BaseViewController {
    
    // MARK: Dependency
    
    private let component: SplashDependency?
    private let listener: SplashListener?
    
    // MARK: View
    
    private let splashView = SplashView()
    
    // MARK: Initialization
    
    init(component: SplashDependency, listener: SplashListener) {
        self.component = component
        self.listener = listener
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        component = nil
        listener = nil
        
        super.init(coder: coder)
    }
    
    // MARK: Lifecycle
    
    override func loadView() {
        view = splashView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switchToRetrospectList()
    }
    
    // MARK: Navigation
    
    private func switchToRetrospectList() {
        Task {
            guard let component, let listener else { return }
            
            do {
                let retrospectListDependency = try await component.retrospectListDepenency()
                listener.switchToRetrospectList(dependency: retrospectListDependency)
            } catch {
                presentAlert()
            }
        }
    }
    
    // MARK: Alert
    
    private func presentAlert() {
        let comfirmAction = UIAlertAction.confirm { [weak self] _ in
            self?.switchToRetrospectList()
        }
        let finishAction = UIAlertAction(title: Texts.finish, style: .destructive) { _ in
            UIView.animate(withDuration: Numerics.fadeOutTime) { [self] in
                splashView.alpha = .zero
            } completion: { _ in
                exit(.zero)
            }
        }
        presentAlert(for: .storeLoadingFailed, actions: [finishAction, comfirmAction])
    }
}

// MARK: - Constants

extension SplashViewController {
    enum Numerics {
        static let fadeOutTime = 0.5
    }
    
    enum Texts {
        static let finish = "종료하기"
    }
}

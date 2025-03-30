//
//  SceneDelegate.swift
//  RetsTalk
//
//  Created on 11/4/24.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = SplashViewController(component: SplashComponent(), listener: self)
        window?.makeKeyAndVisible()
    }
}

// MARK: - SplashListener conformance

extension SceneDelegate: SplashListener {
    func switchToRetrospectList(dependency: RetrospectListDependency) {
        guard let window else { return }
        
        let retrospectListViewController = RetrospectListViewController(dependency: dependency)
        UIView.transition(with: window, duration: Numerics.transitionTime, options: .transitionCrossDissolve) {
            window.rootViewController = BaseNavigationController(rootViewController: retrospectListViewController)
        }
    }
}

// MARK: - Constants

fileprivate extension SceneDelegate {
    enum Numerics {
        static let transitionTime = 0.5
    }
}

//
//  SplashView.swift
//  RetsTalk
//
//  Created on 3/30/25.
//

import UIKit

final class SplashView: BaseView {
    
    // MARK: Subview
    
    private let appIconView: UIImageView = {
        let imageView = UIImageView(image: .appIcon)
        return imageView
    }()
    
    // MARK: RetsTalk lifecycle
    
    override func setupStyles() {
        super.setupStyles()
        
        backgroundColor = .systemBackground
    }
    
    override func setupSubviews() {
        super.setupSubviews()
        
        addSubview(appIconView)
    }
    
    override func setupLayouts() {
        super.setupLayouts()
        
        setupSplashViewLayouts()
    }
}

// MARK: - Subviews layouts

fileprivate extension SplashView {
    func setupSplashViewLayouts() {
        appIconView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            appIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            appIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            appIconView.widthAnchor.constraint(equalToConstant: Metrics.appIconWidth),
            appIconView.heightAnchor.constraint(equalTo: appIconView.widthAnchor),
        ])
    }
    
    enum Metrics {
        static let appIconWidth = 300.0
    }
}

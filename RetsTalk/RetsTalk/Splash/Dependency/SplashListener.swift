//
//  SplashListener.swift
//  RetsTalk
//
//  Created on 3/30/25.
//

@MainActor
protocol SplashListener {
    func switchToRetrospectList(dependency: RetrospectListDependency)
}

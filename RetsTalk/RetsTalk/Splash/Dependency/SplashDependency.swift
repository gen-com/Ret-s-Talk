//
//  SplashDependency.swift
//  RetsTalk
//
//  Created on 3/16/25.
//

@MainActor
protocol SplashDependency {
    func retrospectListDepenency() async throws -> RetrospectListDependency
}

final class SplashComponent: SplashDependency {
    func retrospectListDepenency() async throws -> RetrospectListDependency {
        RetrospectListComponent(
            storage: try await CoreDataManager(name: Constants.Texts.coreDataContainerName),
            summaryProvider: CLOVAStudioManager(urlSession: .shared)
        )
    }
}

//
//  UserSettingManager.swift
//  RetsTalk
//
//  Created by HanSeung on 11/25/24.
//

import Combine
import Foundation

final class UserSettingManager: UserSettingManageable, @unchecked Sendable, ObservableObject {
    @Published var userData: UserData = .init(dictionary: [:])
    private let userDataStorage: Persistable
    
    // MARK: Init method
    
    init(userDataStorage: Persistable) {
        self.userDataStorage = userDataStorage
    }
    
    // MARK: UserSettingManageable conformance
    
    func initialize() async -> UUID? {
        do {
            let request = PersistFetchRequest<UserData>(fetchLimit: 1)
            let fetchedData = try await userDataStorage.fetch(by: request)
            guard let storedUserData = fetchedData.first
            else { return initializeUserData() }

            await MainActor.run {
                userData = storedUserData
            }
            return UUID(uuidString: userData.userID)
        } catch {
            return nil
        }
    }
    
    func fetch() {
        let request = PersistFetchRequest<UserData>(fetchLimit: 1)
        Task {
            let fetchedData = try await userDataStorage.fetch(by: request)
            guard let storedUserData = fetchedData.first else { return }
            
            await MainActor.run {
                userData = storedUserData
            }
        }
    }
    
    func update(to updatingData: UserData) {
        Task {
            let updatedData = try await userDataStorage.update(from: updatingData, to: updatingData)
            await MainActor.run {
                userData = updatedData
            }
        }
    }
    
    // MARK: UserData Handling Method

    private func initializeUserData() -> UUID {
        let newUserID = UUID()
        let newNickname = randomNickname()
        let newUserData = UserData(dictionary: ["userID": newUserID.uuidString, "nickname": newNickname])
      
    func updateCloudSyncState(state isOn: Bool) {
        userData.isCloudSyncOn = isOn
        update(to: userData)
    }

    func updateNickname(_ nickname: String) {
        userData.nickname = nickname
        update(to: userData)
    }

    private func initiateUserData() {
        Task {
            let addedData = try await userDataStorage.add(contentsOf: [newUserData])
            guard let addedData = addedData.first else { return }
            
            await MainActor.run {
                userData = addedData
            }
        }
        return newUserID
    }
    
    private func randomNickname() -> String {
        let adjective = Texts.nicknameComposingAdjectives.randomElement() ?? ""
        let noun = Texts.nicknameComposingNoun
        return adjective + " " + noun
    }
}

// MARK: - Constants

private extension UserSettingManager {
    enum Texts {
        static let nicknameComposingAdjectives = [
            "게임하는", "산책하는", "야근하는", "공상하는",
            "폭식하는", "달리는", "춤추는", "헤엄치는", "노래하는",
        ]
        static let nicknameComposingNoun = "부덕이"
    }
}

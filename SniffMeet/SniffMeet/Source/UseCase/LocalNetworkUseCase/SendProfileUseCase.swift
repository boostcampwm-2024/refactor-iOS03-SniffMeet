//
//  SendProfileUseCase.swift
//  SniffMeet
//
//  Created by Kelly Chui on 1/14/25.
//

import Foundation

protocol SendProfileUseCase {
    func execute()
}

struct SendProfileUseCaseImpl: SendProfileUseCase {
    let dataManager: DataLoadable
    let niManager: NIManager
    let encoder: JSONEncoder
    
    init(
        dataManager: DataLoadable,
        niManager: NIManager
    ) {
        self.dataManager = dataManager
        self.niManager = niManager
        self.encoder = JSONEncoder()
    }
    
    func execute() {
        do {
            let dog = try dataManager.loadData(forKey: "dogInfo", type: UserInfo.self)
            guard let userID = SessionManager.shared.session?.user?.userID else { return }
            let dogProfileDTO = DogProfileDTO(
                id: userID,
                name: dog.name,
                keywords: dog.keywords,
                profileImage: dog.profileImage
            )
            let dataToSend = MPCProfileDropDTO(token: nil, profile: dogProfileDTO, transitionMessage: nil)
            let encodedData = try encoder.encode(dataToSend)
            niManager.mpcManager.sendData(data: encodedData)
            
            
        } catch {
            SNMLogger.error("loadData error : \(error)")
        }
    }
}

//
//  FindMateUseCase.swift
//  SniffMeet
//
//  Created by Kelly Chui on 1/14/25.
//

import Foundation

protocol FindMateUseCase {
    func execute()
}

struct FindMateUseCaseImpl: FindMateUseCase {
    let niManager: NIManager
    
    init(niManager: NIManager) {
        self.niManager = niManager
    }
    
    func execute() {
        // MPC Advertising, browsing 시작
        niManager.mpcManager.isAvailableToBeConnected = true
    }
}

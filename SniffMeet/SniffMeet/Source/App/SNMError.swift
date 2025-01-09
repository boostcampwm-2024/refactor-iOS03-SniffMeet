//
//  SNMError.swift
//  SniffMeet
//
//  Created by Kelly Chui on 1/9/25.
//

import Foundation

enum SNMError: LocalizedError {
    case user(error: any Error)
    case developer(error: any Error)
    case fatal(error: any Error)
    
    var errorDescription: String? {
        switch self {
        case .user(let error): "유저 레벨 에러 \(error.localizedDescription) 발생"
        case .developer(let error): "개발자 레벨 에러 \(error.localizedDescription) 발생"
        case .fatal(let error): "치명적인 에러 \(error.localizedDescription) 발생"
        }
    }
}

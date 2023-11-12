//
//  ErrorType.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 9/26/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

@objc public enum ServiceErrorType: Int {
    case optionaWrappingError
    case unAuthorizedUAEPassResolved
    case unknown
    case unAuthorizedUAEPass        
    case unableToFetchUserData
    case userNotVerifiedUAEPass
    case signingFailed
    
    public func value() -> String {
        switch self {
        case .optionaWrappingError: return "optionaWrappingError"
        case .unAuthorizedUAEPassResolved: return "unAuthorizedUAEPassResolved"
        case .unknown: return "unknown"
        case .unAuthorizedUAEPass: return "unAuthorizedUAEPass"
        case .unableToFetchUserData: return "unableToFetchUserData"
        case .userNotVerifiedUAEPass: return "userNotVerifiedUAEPass"
        case .signingFailed: return "signingFailed"
      }
    }
}

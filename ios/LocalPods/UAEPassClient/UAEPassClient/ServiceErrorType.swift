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
    case noError
    case unAuthorizedUAEPassResolved
    case unknown
    case unAuthorizedUAEPass
    case userNotVerifiedUAEPass
    case unAuthorizedDubaiId
    case unAuthorizedClientAuthentication
    case unAuthorizedGSB
    case backIssue                       
    case emptyResponse
    case jsonfileNotFound
    case errorInParsingResponse
    case serverErrorResponse
    case offlineFilesNotFound
    case refreshJWTToken
    case unableToFetchUserData
    case signingFailed
    case noReponseData
    
    public func value() -> String {
        switch self {
        case .optionaWrappingError: return "optionaWrappingError"
        case .noError: return "noError"
        case .unAuthorizedUAEPassResolved: return "unAuthorizedUAEPassResolved"
        case .unknown: return "unknown"
        case .unAuthorizedUAEPass: return "unAuthorizedUAEPass"
        case .userNotVerifiedUAEPass: return "userNotVerifiedUAEPass"
        case .unAuthorizedDubaiId: return "unAuthorizedDubaiId"
        case .unAuthorizedClientAuthentication: return "unAuthorizedClientAuthentication"
        case .unAuthorizedGSB: return "unAuthorizedGSB"
        case .backIssue: return "backIssue"
        case .emptyResponse: return "emptyResponse"
        case .jsonfileNotFound: return "jsonfileNotFound"
        case .errorInParsingResponse: return "errorInParsingResponse"
        case .serverErrorResponse: return "serverErrorResponse"
        case .offlineFilesNotFound: return "offlineFilesNotFound"
        case .refreshJWTToken: return "refreshJWTToken"
        case .unableToFetchUserData: return "unableToFetchUserData"
        case .signingFailed: return "signingFailed"
        case .noReponseData: return "noReponseData"
      }
    }
}

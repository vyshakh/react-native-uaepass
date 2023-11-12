//
//  AuthenticationChallengeHandler.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 5/8/19.
//  Copyright © 2019 Mohammed Gomaa. All rights reserved.
//

import Foundation

class AuthenticationChallengeHandler {
    class func handle(
        _ challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?
        ) -> Void) {
        let targetName = "TargetName"
        let securityTarget = "UAE Pass Security"
        if let targetName = Bundle.main.infoDictionary?[targetName] as? String {
            if targetName == securityTarget {
                completionHandler(.useCredential, nil)
                return
            }
        }
        challenge.sender?.cancel(challenge)
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}


//
//  UAEPassConfigQA.swift
//
//  Created by Mohammed Gomaa on 11/19/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import UIKit


@objc public class SPConfig: NSObject {
    var redirectUriLogin: String
    var loginScope: String
    var signScope: String?
    var state: String
    var successSchemeURL: String
    var failSchemeURL: String
    @objc public required init(redirectUriLogin: String,scope: String,state: String, successSchemeURL: String, failSchemeURL: String,signingScope: String? = nil) {
        self.redirectUriLogin = redirectUriLogin
        self.loginScope = scope
        self.signScope = signingScope
        self.state = state
        self.successSchemeURL = successSchemeURL
        self.failSchemeURL = failSchemeURL
    }
}

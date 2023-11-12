//
//  UAEPassToken.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 1/2/19.
//  Copyright © 2019 Mohammed Gomaa. All rights reserved.
//

import Foundation

@objc public class UAEPassToken:NSObject, Codable {
    @objc public var refresh_token: String?
    @objc public let scope: String?
    @objc public let tokenType: String?
    @objc public let accessToken: String?
    public let expiresIn: Double?
    @objc public let idToken: String?
    @objc public let error: String?
    @objc public let errorDescription: String?
    @objc public var expiryTime: Double = Date().timeIntervalSince1970

    enum CodingKeys: String, CodingKey {
        case scope
        case refresh_token
        case tokenType = "token_type"
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case idToken = "id_token"
        case error
        case errorDescription = "error_description"
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        scope = try values.decodeIfPresent(String.self, forKey: .scope)
        refresh_token = try values.decodeIfPresent(String.self, forKey: .refresh_token)
        tokenType = try values.decodeIfPresent(String.self, forKey: .tokenType)
        accessToken = try values.decodeIfPresent(String.self, forKey: .accessToken)
        expiresIn = try values.decodeIfPresent(Double.self, forKey: .expiresIn)
        expiryTime += expiresIn ?? 0.0
        idToken = try values.decodeIfPresent(String.self, forKey: .idToken)
        error = try values.decodeIfPresent(String.self, forKey: .error)
        errorDescription = try values.decodeIfPresent(String.self, forKey: .errorDescription)
    }
    func isTokenValid() -> Bool {
        return Date().timeIntervalSince1970 < (expiryTime - 60)
    }

}

struct UAEPASSConfig: Codable {
    let authURL: String?
    let tokenURL: String?
    let profileURL: String?
    
    enum CodingKeys: String, CodingKey {
        case authURL = "authorization_endpoint"
        case tokenURL = "token_endpoint"
        case profileURL = "userinfo_endpoint"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        authURL = try values.decodeIfPresent(String.self, forKey: .authURL)
        tokenURL = try values.decodeIfPresent(String.self, forKey: .tokenURL)
        profileURL = try values.decodeIfPresent(String.self, forKey: .profileURL)
    }
}

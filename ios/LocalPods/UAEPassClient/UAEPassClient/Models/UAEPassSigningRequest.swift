//
//  UAEPassSigningRequest.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 12/30/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

public struct UAEPassSigningRequest: Codable {
    
    public let isPostRequest: Bool?
    public var serviceType: UAEPassServiceType?
    public var tokenParams: TokenParams?
    
    // for uploading file
    public var pdfData: Data?
    public var baseURL: String?
    
    // prcess params
    public var processParams: UAEPAssSigningParameters?
    public var signingData: Data?
    public var documentURL: URL?

    public enum CodingKeys: String, CodingKey {
        case isPostRequest
    }
    
    public init(isPostRequest: Bool? = nil,
         serviceType: UAEPassServiceType? = nil) {
        self.isPostRequest = isPostRequest
        self.serviceType = serviceType
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isPostRequest = try values.decodeIfPresent(Bool.self, forKey: .isPostRequest)
        serviceType = nil
    }
}

public struct TokenParams: Codable {
    public var grantType: String?
    public var scope: String?
    
    public static func getInitialisedObject() -> TokenParams {
        return TokenParams(scope: UAEPASSRouter.shared.spConfig.signScope, grantType: "client_credentials")
    }
    
    public enum CodingKeys: String, CodingKey {
        case scope = "scope"
        case grantType = "grant_type"
    }
    
    public init(scope: String? = nil, grantType: String? = nil) {
        self.scope = scope
        self.grantType = grantType
        
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        grantType = try values.decodeIfPresent(String.self, forKey: .grantType)
        scope = try values.decodeIfPresent(String.self, forKey: .scope)
    }
}

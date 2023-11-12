//
//  UAEPAssSigningParameters.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 10/18/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

@objc public class UAEPAssSigningParameters:NSObject, Codable {
    let processType: String?
    let labels: [[String]]?
    let signer: Signer?
    let uiLocales: [String]?
    var finishCallbackUrl: String?
    let views: UAEPASSViews?
    var timeStamp: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case processType = "process_type"
        case labels
        case signer
        case uiLocales = "ui_locales"
        case finishCallbackUrl = "finish_callback_url"
        case views
        case timeStamp = "timestamp"
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        processType = try values.decodeIfPresent(String.self, forKey: .processType)
        labels = try values.decodeIfPresent([[String]].self, forKey: .labels)
        signer = try values.decodeIfPresent(Signer.self, forKey: .signer)
        uiLocales = try values.decodeIfPresent([String].self, forKey: .uiLocales)
        finishCallbackUrl = try values.decodeIfPresent(String.self, forKey: .finishCallbackUrl)
        views = try values.decodeIfPresent(UAEPASSViews.self, forKey: .views)
        timeStamp = try values.decodeIfPresent(Timestamp.self, forKey: .timeStamp)
    }
    
}

struct Signer: Codable {
    let signaturePolicyId: String?
    let parameters: UAEPAssParameters?
    
    enum CodingKeys: String, CodingKey {
        
        case signaturePolicyId = "signature_policy_id"
        case parameters = "parameters"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        signaturePolicyId = try values.decodeIfPresent(String.self, forKey: .signaturePolicyId)
        parameters = try values.decodeIfPresent(UAEPAssParameters.self, forKey: .parameters)
    }
    
}

struct DocumentAgreement: Codable {
    let skipServerId: String?
    enum CodingKeys: String, CodingKey {
        
        case skipServerId = "skip_server_id"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        skipServerId = try values.decodeIfPresent(String.self, forKey: .skipServerId)
    }
}

struct UAEPASSViews: Codable {
    let documentAgreement: DocumentAgreement?
    enum CodingKeys: String, CodingKey {
        case documentAgreement = "document_agreement"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        documentAgreement = try values.decodeIfPresent(DocumentAgreement.self, forKey: .documentAgreement)
    }
}

struct Timestamp: Codable {
    var providerId: String?
    enum CodingKeys: String, CodingKey {
        case providerId = "provider_id"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        providerId = try values.decodeIfPresent(String.self, forKey: .providerId)
    }
}

struct UAEPAssParameters: Codable {
    let type: String?
    let signatureField: SignatureField?

    enum CodingKeys: String, CodingKey {
        case type
        case signatureField = "signature_field"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        signatureField = try values.decodeIfPresent(SignatureField.self, forKey: .signatureField)
    }
}

//
//  Appearance.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 10/18/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

struct Appearance: Codable {
    let signatureDetails: SignatureDetails?
    
    enum CodingKeys: String, CodingKey {
        case signatureDetails = "signature_details"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        signatureDetails = try values.decodeIfPresent(SignatureDetails.self, forKey: .signatureDetails)
    }
    
}

//
//  SignatureDetails.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 10/18/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

struct SignatureDetails: Codable {
    let details: [SDetails]?
    
    enum CodingKeys: String, CodingKey {
        case details
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        details = try values.decodeIfPresent([SDetails].self, forKey: .details)
    }
    
}

 struct SDetails: Codable {
    let type: String?
    let title: String?
    
    enum CodingKeys: String, CodingKey {
        
        case type
        case title
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        title = try values.decodeIfPresent(String.self, forKey: .title)
    }
    
}

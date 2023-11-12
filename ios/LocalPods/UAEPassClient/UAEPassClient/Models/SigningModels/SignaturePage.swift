//
//  SignaturePage.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 10/18/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

struct SignaturePage: Codable {
    
    let number: String?
    
    enum CodingKeys: String, CodingKey {
        case number
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        number = try values.decodeIfPresent(String.self, forKey: .number)
    }
    
}

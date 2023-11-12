//
//  SignatureField.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 10/18/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

struct SignatureField: Codable {
    let name: String?
    let location: SignatureLocation?
    let appearance: Appearance?
    
    enum CodingKeys: String, CodingKey {
        case name
        case location
        case appearance
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        location = try values.decodeIfPresent(SignatureLocation.self, forKey: .location)
        appearance = try values.decodeIfPresent(Appearance.self, forKey: .appearance)
    }
}

//
//  SignatureRectangle.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 10/18/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

struct SignatureRectangle: Codable {
    
    let signatureX: Int?
    let signatureY: Int?
    let height: Int?
    let width: Int?
    
    enum CodingKeys: String, CodingKey {
        case signatureX = "x"
        case signatureY = "y"
        case height
        case width
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        signatureX = try values.decodeIfPresent(Int.self, forKey: .signatureX)
        signatureY = try values.decodeIfPresent(Int.self, forKey: .signatureY)
        height = try values.decodeIfPresent(Int.self, forKey: .height)
        width = try values.decodeIfPresent(Int.self, forKey: .width)
    }
    
}

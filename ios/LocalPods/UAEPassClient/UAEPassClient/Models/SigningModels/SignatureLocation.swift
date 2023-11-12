//
//  SignatureLocation.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 10/18/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

struct SignatureLocation: Codable {
    let page: SignaturePage?
    let rectangle: SignatureRectangle?
    
    enum CodingKeys: String, CodingKey {
        
        case page
        case rectangle
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        page = try values.decodeIfPresent(SignaturePage.self, forKey: .page)
        rectangle = try values.decodeIfPresent(SignatureRectangle.self, forKey: .rectangle)
    }
}

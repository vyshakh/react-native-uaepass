//
//  ConfigrationInstanceProtocol.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 17/02/2021.
//  Copyright © 2021 Mohammed Gomaa. All rights reserved.
//

import Foundation

protocol ConfigrationInstanceProtocol {

    static func instantiate() -> NSObject
    static func instantiate(for type: String) -> NSObject
}

extension ConfigrationInstanceProtocol {
    static func instantiate(for type: String) -> NSObject {
        assertionFailure("Method must be override in the class method")
        return NSObject()
    }
}

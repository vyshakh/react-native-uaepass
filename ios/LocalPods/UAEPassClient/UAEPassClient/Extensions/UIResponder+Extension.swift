//
//  UIResponder+Extension.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 17/02/2021.
//  Copyright © 2021 Mohammed Gomaa. All rights reserved.
//

import UIKit

extension  UIResponder {
    static var Identifier: String {
        return String(describing: self)
    }
}

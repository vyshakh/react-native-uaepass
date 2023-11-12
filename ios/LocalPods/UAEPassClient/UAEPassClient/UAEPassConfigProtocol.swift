//
//  UAEPassConfigProtocol.swift
//
//  Created by Syed Absar Karim on 11/4/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

enum BaseUrls: String {
    case devTX = "https://dev-id.uaepass.ae/"
    case devIDS = "https://dev-ids.uaepass.ae/"
    case qaTX = "https://qa-id.uaepass.ae/"
    case qaIDS = "https://qa-ids.uaepass.ae/"
    case prodTX = "https://id.uaepass.ae/"
    case prodIDS = "https://ids.uaepass.ae/"
    case stgTX = "https://stg-id.uaepass.ae/"
    case stgIDS = "https://stg-ids.uaepass.ae/"

    public func get() -> String {
        return rawValue
    }
}

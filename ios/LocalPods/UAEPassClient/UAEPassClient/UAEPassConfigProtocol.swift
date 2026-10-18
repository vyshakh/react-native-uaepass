//
//  UAEPassConfigProtocol.swift
//
//  Created by Syed Absar Karim on 11/4/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

enum BaseUrls: String {
    case devTX = "https://dev-id.uaepass.ae/"
    case qaTX = "https://qa-id.uaepass.ae/"
    case prodTX = "https://id.uaepass.ae/"
    case stgTX = "https://stg-id.uaepass.ae/"
    case eSignDev = "https://dev-esign.uaepass.ae/v2/signature/"
    case eSignQA = "https://qa-esign.uaepass.ae/v2/signature/"
    case eSignProd = "https://esign.uaepass.ae/v2/signature/"
    case eSignSTG = "https://stg-esign.uaepass.ae/v2/signature/"

    public func get() -> String {
        return rawValue
    }
}

//
//  HandleURLScheme.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 12/31/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import UIKit

@objc public class HandleURLScheme: NSObject {
    @objc public class func openCustomApp(fullUrl: String) {
        // app will opened successfully
        let customURL = URL(string: fullUrl)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(customURL)
        } else {
            UIApplication.shared.openURL(customURL)
        }
    }
    @objc class func openCustomURLScheme(customURLScheme: String) -> Bool {
        let customURL = URL(string: customURLScheme)!
        if UIApplication.shared.canOpenURL(customURL) {
            return true
        }
        return false
    }
    
    @objc public static func externalURLSchemeSuccess() -> String {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [AnyObject],
            let urlTypeDictionary = urlTypes.first as? [String: AnyObject],
            let urlSchemes = urlTypeDictionary["CFBundleURLSchemes"] as? [AnyObject],
            //TODO: VERIFY if we will return nil or empty string.
            let externalURLScheme = urlSchemes.first as? String else { return "" }
        return "\(externalURLScheme)://uaePassSuccess"
    }
    
    @objc public static func externalURLSchemeFail() -> String {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [AnyObject],
            let urlTypeDictionary = urlTypes.first as? [String: AnyObject],
            let urlSchemes = urlTypeDictionary["CFBundleURLSchemes"] as? [AnyObject],
            //TODO: VERIFY if we will return nil or empty string.
            let externalURLScheme = urlSchemes.first as? String else { return "" }
        return "\(externalURLScheme)://uaePassFail"
    }
    
}

//
//  URL+Extension.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 1/2/19.
//  Copyright © 2019 Mohammed Gomaa. All rights reserved.
//

import UIKit
public protocol URLOpener {
    static func open(_ url: URL)
}

extension URL: URLOpener {
    public static func open(_ url: URL) {
        guard UIApplication.shared.canOpenURL(url) else {
            debugPrint("can't url : ", url.absoluteString)
            return
        }
        if #available(iOS 10, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    func open() {
        let url = self
        guard UIApplication.shared.canOpenURL(url) else {
            debugPrint("can't url : ", url.absoluteString)
            return
        }
        if #available(iOS 10, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    ///  Construct  URL by appending the parametrs "strings"
    ///
    /// - Parameter parameters: it take vardic paramter as String to build the url string
    /// - Returns: url string value
    static func buildURL(parameters: String...) -> URL? {
        // construct a URL by appending the parametrs string
        var urlStringBuilder: String = ""
        for componentPath in parameters {
            urlStringBuilder += componentPath
        }
        // before passing the user's search string as a parameter to the query URL, you call addingPercentEncoding on the string to ensure that it's properly escaped
        let expectedCharSet = NSCharacterSet.urlQueryAllowed
        guard let allowedURL = urlStringBuilder.addingPercentEncoding(withAllowedCharacters: expectedCharSet) else {
            return nil
        }
        guard let url = URL(string: allowedURL) else {
            return nil
        }
        return url
    }
    
    public func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
    
}

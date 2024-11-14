//
//  Router.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 12/30/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import UIKit
import WebKit

extension WKProcessPool {
    static let shared = WKProcessPool()
}

extension WKWebViewConfiguration {
    static var shared: WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool.shared
        return configuration
    }
}

@objc public enum SDKLang: Int {
    case arabic
    case english

    func value() -> String {
        switch self {
        case .arabic: return "ar"
        case .english: return "en"
        }
    }
}

@objc public class UAEPASSRouter: NSObject {
    
    @objc public static let shared = UAEPASSRouter()
    @objc public var uaePassFullToken: UAEPassToken!
    @objc public var uaePassToken: String!
    @objc public var webView: WKWebView!
    @objc public var uaePassWebViewController: UAEPassWebViewController?
    @objc public var sdkLang: SDKLang = .english

    /// private constructor
    public override init() {
        uploadSignDocumentResponse = nil
        environmentConfig = UAEPassConfig(clientID: "", clientSecret: "", env: .qa)
        spConfig = SPConfig(redirectUriLogin: "", scope: "", state: "", successSchemeURL: "", failSchemeURL: "")
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration.shared)
        uaePassToken = ""
        uaePassFullToken = UAEPassToken()
    }
    @objc public var environmentConfig: UAEPassConfig
    @objc public var spConfig: SPConfig
    public var uploadSignDocumentResponse: UploadSignDocumentResponse?
}

extension String {
    public func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

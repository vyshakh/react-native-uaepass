//
//  UAEPASSWVConteroller.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 17/02/2021.
//  Copyright © 2021 Mohammed Gomaa. All rights reserved.
//

import UIKit
import WebKit

@available(iOS 13.0, *)
@objc public class UAEPassWebViewController: UIViewController, WKNavigationDelegate {
    
    @objc public var urlString: String!
    @objc public var onUAEPassSigningCodeRecieved:(() -> Void)? = nil
    @objc public var onUAEPassSuccessBlock: ((String) -> Void)? = nil
    @objc public var onUAEPassFailureBlock: ((String) -> Void)? = nil
    @objc public var onSigningCompleted: (() -> Void)? = nil
    @objc public var onDismiss: (() -> Void)? = nil
    @objc var webView: WKWebView?
    var successURLR: String?
    var failureURLR: String?
    public var isSigning: Bool? = false
    public var skipDismiss = false
    public var alreadyCanceled = false
    public override func viewDidLoad() {
        self.title = "UAE PASS"
        contentMode.preferredContentMode = .mobile
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    let contentMode = WKWebpagePreferences.init()

    public func reloadwithURL(url: String) {
        webView = UAEPASSRouter.shared.webView
        webView?.navigationDelegate = self
        webView?.frame = self.view.frame
        if let webView = webView {
            _ = view.addSubviewStretched(subview: webView)
        }
        self.urlString = url
        if let url = URL(string: url) {
            var urlRequest = URLRequest(url: url)
            urlRequest.timeoutInterval = 30
            webView?.load(urlRequest)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed && !skipDismiss {
            onDismiss?() 
        }
    }

    @objc public func forceReload() {
        print("<<<<<<<<<<<<<<< foreceReload From AppDelegate >>>>>>>>>>>>>>>>>>")
        if let successurl = successURLR {
            webView?.load(URLRequest(url: URL(string: successurl)!))
        } else {
            webView?.reload()
        }
    }
    
    @objc public func foreceStop() {
        print("<<<<<<<<<<<<<<< foreceStop From AppDelegate >>>>>>>>>>>>>>>>>>")
        webView?.stopLoading()
        if alreadyCanceled == false {
            skipDismiss = true
            alreadyCanceled = true
            onUAEPassFailureBlock?("cancel")
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        let url = navigationAction.request.url
        guard let urlString = navigationAction.request.mainDocumentURL?.absoluteString else { return }
        print("### URL ### : \(urlString)")
        if urlString.contains("error=access_denied") || urlString.contains("error=cancelled") {
            if alreadyCanceled == false {
                skipDismiss = true
                alreadyCanceled = true
                onUAEPassFailureBlock?("cancel")
            }
            decisionHandler(.cancel, contentMode)
        } else if urlString.contains(UAEPASSRouter.shared.spConfig.redirectUriLogin) && urlString.contains("code=") {
            if let url = url, let token = url.valueOf("code") {
                print(token)
                print("### code Recieved : \(urlString)")
                if onUAEPassSuccessBlock != nil && !token.isEmpty {
                    skipDismiss = true
                    onUAEPassSuccessBlock?(token)
                }
            }
            decisionHandler(.cancel, contentMode)
        } else if urlString.contains("uaepass://")  {
            // isUAEPassOpened = true
            let newURLString = urlString.replacingOccurrences(of: "uaepass://", with: UAEPASSRouter.shared.environmentConfig.uaePassSchemeURL)
            successURLR = navigationAction.request.mainDocumentURL?.valueOf("successurl")
            failureURLR = navigationAction.request.mainDocumentURL?.valueOf("failureurl")
            let listItems = newURLString.components(separatedBy: "successurl")
            if listItems.count > 0 {
                if let customScheme = listItems.first {
                    let successScheme = HandleURLScheme.externalURLSchemeSuccess()
                    let failureScheme = HandleURLScheme.externalURLSchemeFail()
                    let urlScheme = "\(customScheme)successurl=\(successScheme)&failureurl=\(failureScheme)&closeondone=true"
                    print("urlScheme: \(urlScheme)")
                    if let url = URL(string: urlScheme),  UIApplication.shared.canOpenURL(url) {
                        HandleURLScheme.openCustomApp(fullUrl: urlScheme)
                    }
                }
            }
            decisionHandler(.cancel, contentMode)
        } else if urlString.contains("status=finished") {
            onSigningCompleted?()
            decisionHandler(.cancel, contentMode)
        } else if urlString.contains("status=") {
            if urlString.contains("status=success") {
                decisionHandler(.allow, contentMode)
            } else {
                onUAEPassFailureBlock?("Signing Failed")
                decisionHandler(.cancel, contentMode)
            }
        } else if navigationAction.navigationType == .linkActivated && (urlString.contains("signup") || urlString.contains("account-recovery")) {
            if let url = navigationAction.request.mainDocumentURL {
                decisionHandler(.allow, contentMode)
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel, contentMode)
            } else {
                decisionHandler(.allow, contentMode)
            }
        } else {
            decisionHandler(.allow, contentMode)
        }
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if error._code == -1001 || error._code == -1003 || error._code == -1100 {
            if error._code == -1001 { // TIMED OUT:
                // CODE to handle TIMEOUT
                print("CODE to handle TIMEOUT")
            } else if error._code == -1003 { // SERVER CANNOT BE FOUND
                // CODE to handle SERVER not found
                print("CODE to handle SERVER not found")
            } else if error._code == -1100 { // URL NOT FOUND ON SERVER
                // CODE to handle URL not found
                print("CODE to handle URL not found")
            }
            skipDismiss = true
            alreadyCanceled = true
            onUAEPassFailureBlock?("cancel")
        }
    }
}

// MARK: - ConfigrationInstanceProtocol
@available(iOS 13.0, *)
extension UAEPassWebViewController: ConfigrationInstanceProtocol {
    @objc public static func instantiate() -> NSObject {
        let bundle = Bundle.init(for: UAEPassWebViewController.self)
        let object = UAEPassWebViewController(nibName: Identifier, bundle: bundle)
        return object
    }
}


public extension UIView {
    typealias ConstraintsTupleStretched = (top:NSLayoutConstraint, bottom:NSLayoutConstraint, leading:NSLayoutConstraint, trailing:NSLayoutConstraint)
    func addSubviewStretched(subview:UIView?, insets: UIEdgeInsets = UIEdgeInsets() ) -> ConstraintsTupleStretched? {
        guard let subview = subview else {
            return nil
        }

        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)

        let constraintLeading = NSLayoutConstraint(item: subview,
                                                   attribute: .left,
                                                   relatedBy: .equal,
                                                   toItem: self,
                                                   attribute: .left,
                                                   multiplier: 1,
                                                   constant: insets.left)
        addConstraint(constraintLeading)

        let constraintTrailing = NSLayoutConstraint(item: self,
                                                    attribute: .right,
                                                    relatedBy: .equal,
                                                    toItem: subview,
                                                    attribute: .right,
                                                    multiplier: 1,
                                                    constant: insets.right)
        addConstraint(constraintTrailing)

        let constraintTop = NSLayoutConstraint(item: subview,
                                               attribute: .top,
                                               relatedBy: .equal,
                                               toItem: self,
                                               attribute: .top,
                                               multiplier: 1,
                                               constant: insets.top)
        addConstraint(constraintTop)

        let constraintBottom = NSLayoutConstraint(item: self,
                                                  attribute: .bottom,
                                                  relatedBy: .equal,
                                                  toItem: subview,
                                                  attribute: .bottom,
                                                  multiplier: 1,
                                                  constant: insets.bottom)
        addConstraint(constraintBottom)
        return (constraintTop, constraintBottom, constraintLeading, constraintTrailing)
    }

}

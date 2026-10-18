//
//  UAEPassNavigationProxy.swift
//
//  Sits between the SDK's web view and UAEPassWebViewController (its
//  navigation delegate) so the wrapper can see what the SDK throws away:
//  the `error` / `error_description` UAE PASS returns on the redirect, and the
//  `failureurl` it hands to the UAE PASS app. Everything is forwarded to the
//  SDK unchanged unless the wrapper finishes the flow itself.
//

import UIKit
import WebKit
import UAEPassClient

final class UAEPassNavigationProxy: NSObject, WKNavigationDelegate {
  private weak var sdkController: UAEPassWebViewController?
  private let redirectURL: String

  /// The redirect URI came back with `?error=…`: the flow is over.
  var onRedirectError: ((_ error: String, _ description: String?) -> Void)?
  /// Any other page carried an `error` parameter (the SDK then reports a bare
  /// "cancel"); remembered so the failure can still carry the real value.
  var onErrorSeen: ((_ error: String, _ description: String?) -> Void)?
  /// The login page handed off to the UAE PASS app.
  var onAppHandoff: ((_ failureURL: URL?) -> Void)?
  /// The page could not load (offline, DNS, timeout…).
  var onLoadFailure: ((_ error: NSError) -> Void)?

  init(sdkController: UAEPassWebViewController, redirectURL: String) {
    self.sdkController = sdkController
    self.redirectURL = redirectURL
  }

  // Forward the delegate methods we don't implement to the SDK.
  override func responds(to aSelector: Selector!) -> Bool {
    return super.responds(to: aSelector) || (sdkController?.responds(to: aSelector) ?? false)
  }

  override func forwardingTarget(for aSelector: Selector!) -> Any? {
    if let sdkController = sdkController, sdkController.responds(to: aSelector) {
      return sdkController
    }
    return super.forwardingTarget(for: aSelector)
  }

  func webView(_ webView: WKWebView,
               decidePolicyFor navigationAction: WKNavigationAction,
               preferences: WKWebpagePreferences,
               decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
    if let url = navigationAction.request.url {
      if let error = url.valueOf("error"), !error.isEmpty {
        let description = url.valueOf("error_description")
        if url.absoluteString.hasPrefix(redirectURL) {
          // The SDK only recognises access_denied / cancelled here; anything
          // else (invalid_request, login_required…) would just sit on the
          // redirect page.
          decisionHandler(.cancel, preferences)
          onRedirectError?(error, description)
          return
        }
        onErrorSeen?(error, description)
      }
      if url.scheme?.lowercased().hasPrefix("uaepass") == true {
        onAppHandoff?(url.valueOf("failureurl").flatMap(URL.init(string:)))
      }
    }

    guard let sdkController = sdkController else {
      decisionHandler(.cancel, preferences)
      return
    }
    sdkController.webView(webView, decidePolicyFor: navigationAction, preferences: preferences, decisionHandler: decisionHandler)
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    let nsError = error as NSError
    // The SDK reports these as "cancel"; they are connectivity failures.
    if nsError.domain == NSURLErrorDomain && nsError.code != NSURLErrorCancelled {
      onLoadFailure?(nsError)
    }
    sdkController?.webView(webView, didFailProvisionalNavigation: navigation, withError: error)
  }
}

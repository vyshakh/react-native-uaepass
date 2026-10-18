//
//  UAEPassViewController.swift
//
//  Created by Vyshakh on 18/10/2023.
//  parakkatvyshakh@gmail.com

import UIKit
import UAEPassClient

class UAEPassViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
  // Set once the promise has been settled so dismissal doesn't settle it twice.
  private var didCompleteFlow = false
  private var didStartLogin = false
  weak var embeddedWebVC: UAEPassWebViewController?
  // The web view holds its navigation delegate weakly.
  private var navigationProxy: UAEPassNavigationProxy?
  /// Last `error` UAE PASS put on a page, for when the SDK only says "cancel".
  private var lastUAEPassError: (error: String, description: String?)?
  /// UAE PASS's own failure URL from the hand-off to the UAE PASS app.
  private var appFailureURL: URL?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UAE PASS"
    view.backgroundColor = .systemBackground
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .cancel,
      target: self,
      action: #selector(cancelTapped)
    )
    UAEPass.activeController = self
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !didStartLogin else { return }
    didStartLogin = true

    // The SDK concatenates scope into the authorize URL without encoding it,
    // so a multi-value scope ("a b") would otherwise produce an invalid URL.
    let scope = UAEPass.scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? UAEPass.scope!

    UAEPASSRouter.shared.spConfig = SPConfig(redirectUriLogin: UAEPass.redirectURL,
                                             scope: scope,
                                             state: UAEPass.state ?? UAEPass.randomState(length: 24),
                                             successSchemeURL: UAEPass.scheme + "://" + UAEPass.successHost,
                                             failSchemeURL: UAEPass.scheme + "://" + UAEPass.failureHost)

    UAEPASSRouter.shared.sdkLang = UAEPass.locale == "ar" ? .arabic : .english

    // The client secret must never ship in the app; the code is exchanged for
    // a token on the SP backend.
    let env: UAEPASSEnvirnonment = UAEPass.env == "production" ? .production : .staging
    UAEPASSRouter.shared.environmentConfig = UAEPassConfig(clientID: UAEPass.clientId, clientSecret: "", env: env)

    login()
  }

  @objc private func cancelTapped() {
    finish(code: UAEPass.errorCancelled, message: "canceled")
  }

  // Swipe-down dismissal of the sheet.
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    settle(code: UAEPass.errorCancelled, message: "canceled")
  }

  func login() {
    guard let webVC = UAEPassWebViewController.instantiate() as? UAEPassWebViewController else {
      finish(code: UAEPass.errorLoginFailed, message: "Unable to load the UAE PASS login screen")
      return
    }

    webVC.urlString = UAEPassConfiguration.getServiceUrlForType(serviceType: .loginURL)
    embeddedWebVC = webVC

    webVC.onUAEPassSuccessBlock = { [weak self] (response: String?) -> Void in
      // SDK 2.x passes the bare code when the redirect matches redirect_uri,
      // but the whole URL when it only finds "code=" somewhere in it.
      guard let response = response, !response.isEmpty else {
        self?.finish(code: UAEPass.errorLoginFailed, message: "Failed to get access code")
        return
      }
      var code = response
      var returnedState: String?
      if let url = URL(string: response), url.scheme != nil, let codeParam = url.valueOf("code") {
        code = codeParam
        returnedState = url.valueOf("state")
      }
      self?.finish { UAEPass.complete(code: code, returnedState: returnedState) }
    }
    webVC.onUAEPassFailureBlock = { [weak self] (response: String?) -> Void in
      guard let self = self else { return }
      if let seen = self.lastUAEPassError {
        self.finish { UAEPass.reject(uaePassError: seen.error, description: seen.description) }
      } else if response == nil || response == "cancel" {
        self.finish(code: UAEPass.errorCancelled, message: "canceled")
      } else {
        self.finish(code: UAEPass.errorLoginFailed, message: response ?? "UAE PASS login failed")
      }
    }

    addChild(webVC)
    _ = view.addSubviewStretched(subview: webVC.view)
    webVC.didMove(toParent: self)
    webVC.reloadwithURL(url: webVC.urlString)

    // reloadwithURL makes the SDK controller the navigation delegate; put the
    // proxy in front of it before the first navigation decision arrives.
    if let webView = webVC.webView {
      let proxy = UAEPassNavigationProxy(sdkController: webVC, redirectURL: UAEPass.redirectURL)
      proxy.onRedirectError = { [weak self] error, description in
        self?.finish { UAEPass.reject(uaePassError: error, description: description) }
      }
      proxy.onErrorSeen = { [weak self] error, description in
        self?.lastUAEPassError = (error, description)
      }
      proxy.onAppHandoff = { [weak self] failureURL in
        self?.appFailureURL = failureURL
      }
      proxy.onLoadFailure = { [weak self] error in
        self?.finish(code: UAEPass.errorLoginFailed, message: error.localizedDescription)
      }
      navigationProxy = proxy
      webView.navigationDelegate = proxy
    }
  }

  /// The UAE PASS app reported a failure through the failure callback URL.
  func handleAppFailure(callbackURL: URL) {
    if let error = callbackURL.valueOf("error"), !error.isEmpty {
      finish { UAEPass.reject(uaePassError: error, description: callbackURL.valueOf("error_description")) }
      return
    }
    guard let failureURL = appFailureURL, let webView = embeddedWebVC?.webView else {
      finish(code: UAEPass.errorCancelled, message: "canceled")
      return
    }
    // Like the Android SDK: load UAE PASS's failure URL so its server
    // redirects to redirect_uri?error=… (e.g. cancelledOnApp), which the proxy
    // turns into a rejection carrying the real error. Fall back to a plain
    // cancel if that redirect never comes.
    webView.load(URLRequest(url: failureURL))
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
      self?.finish(code: UAEPass.errorCancelled, message: "canceled")
    }
  }

  /// Dismisses the login screen without touching the pending promise.
  func dismissFlow(completion: (() -> Void)? = nil) {
    didCompleteFlow = true
    (navigationController ?? self).dismiss(animated: true, completion: completion)
  }

  private func finish(code: String, message: String) {
    finish { UAEPass.reject(withCode: code, message: message, error: nil) }
  }

  private func finish(_ settlePromise: () -> Void) {
    guard !didCompleteFlow else { return }
    settlePromise()
    dismissFlow()
  }

  private func settle(code: String, message: String) {
    guard !didCompleteFlow else { return }
    didCompleteFlow = true
    UAEPass.reject(withCode: code, message: message, error: nil)
  }
}

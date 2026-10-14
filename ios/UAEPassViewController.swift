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
      if response == nil || response == "cancel" {
        self?.finish(code: UAEPass.errorCancelled, message: "canceled")
      } else {
        self?.finish(code: UAEPass.errorLoginFailed, message: response ?? "UAE PASS login failed")
      }
    }

    addChild(webVC)
    _ = view.addSubviewStretched(subview: webVC.view)
    webVC.didMove(toParent: self)
    webVC.reloadwithURL(url: webVC.urlString)
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

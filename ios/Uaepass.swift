//
//  UAEPass.swift
//
//  Created by Vyshakh on 07/11/2023.
//  parakkatvyshakh@gmail.com
//

import UIKit
import UAEPassClient
import WebKit

@objc(UAEPass)
class UAEPass: NSObject {

  // Error codes shared with Android (UaepassModule.java) and src/index.tsx.
  static let errorMissingParameters = "MISSING_PARAMETERS"
  static let errorCancelled = "CANCELLED"
  static let errorLoginFailed = "LOGIN_FAILED"
  static let errorStateMismatch = "STATE_MISMATCH"
  static let errorSuperseded = "SUPERSEDED"

  @objc public static var resolveResponse: RCTPromiseResolveBlock?
  @objc public static var rejectResponse: RCTPromiseRejectBlock?

  public static var env: String!
  public static var clientId: String!
  public static var redirectURL: String!
  public static var scope: String!
  public static var scheme: String!
  public static var locale: String!
  public static var successHost: String!
  public static var failureHost: String!
  /// OAuth `state` sent with the current login request.
  public static var state: String?

  /// The login screen currently on screen, if any. Used by the redirect
  /// handler instead of guessing from the view hierarchy.
  weak static var activeController: UAEPassViewController?

  @objc
  func getSuccessHost() -> String? {
    return UAEPass.successHost
  }

  @objc
  func getFailureHost() -> String? {
    return UAEPass.failureHost
  }

  @objc
  func handleLoginSuccess() {
    DispatchQueue.main.async {
      UAEPass.activeController?.embeddedWebVC?.forceReload()
    }
  }

  @objc
  func handleLoginFailure() {
    DispatchQueue.main.async {
      UAEPass.activeController?.embeddedWebVC?.foreceStop()
    }
  }

  @objc
  func login(_ params: NSDictionary,
             resolve: @escaping RCTPromiseResolveBlock,
             rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {

    func string(_ key: String) -> String? {
      guard let value = params[key] as? String, !value.isEmpty else { return nil }
      return value
    }

    guard
      let env = string("env"),
      let clientId = string("clientId"),
      let redirectURL = string("redirectURL"),
      let successHost = string("successHost"),
      let failureHost = string("failureHost"),
      let scheme = string("scheme"),
      let scope = string("scope")
    else {
      reject(UAEPass.errorMissingParameters, "One or more required parameters are missing", nil)
      return
    }

    DispatchQueue.main.async {
      // A second login() while one is pending would otherwise orphan the
      // first promise forever.
      UAEPass.reject(withCode: UAEPass.errorSuperseded,
                     message: "A newer UAE PASS login replaced this one",
                     error: nil)

      UAEPass.resolveResponse = resolve
      UAEPass.rejectResponse = reject

      UAEPass.env = env
      UAEPass.clientId = clientId
      UAEPass.redirectURL = redirectURL
      UAEPass.successHost = successHost
      UAEPass.failureHost = failureHost
      UAEPass.scheme = scheme
      UAEPass.scope = scope
      UAEPass.locale = string("locale") ?? "en"
      UAEPass.state = string("state") ?? UAEPass.randomState(length: 24)

      if let previous = UAEPass.activeController, previous.presentingViewController != nil {
        previous.dismissFlow(completion: UAEPass.presentLoginScreen)
      } else {
        UAEPass.presentLoginScreen()
      }
    }
  }

  @objc
  func logout(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
      WKWebsiteDataStore.default().removeData(
        ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
        modifiedSince: Date.distantPast
      ) {
        resolve("success")
      }
    }
  }

  // =========================================================
  // Redirect URL handler (ObjC + Swift compatible), called from the host
  // app's AppDelegate when the UAE PASS app hands control back.
  // - Returns @YES when handled (success/failure)
  // - Returns nil when not a UAE PASS URL, or no login is in progress
  // Selector matches header: -handleRedirectUrl:(NSURL *)url
  // =========================================================

  @objc(handleRedirectUrl:)
  func handleRedirectUrl(_ url: URL) -> NSNumber? {
    guard UAEPass.resolveResponse != nil else { return nil }

    let host = (url.host ?? "").lowercased()
    let successHost = (getSuccessHost() ?? "").lowercased()
    let failureHost = (getFailureHost() ?? "").lowercased()

    // The SDK always tells the UAE PASS app to call back on
    // `<CFBundleURLTypes[0]>://uaePassSuccess` / `://uaePassFail`
    // (HandleURLScheme), so match those hosts as well as the configured ones.
    if host == "uaepasssuccess" || (!successHost.isEmpty && host == successHost) {
      if completeUAEPassSuccess(from: url) {
        dismissPresentedUAEPassFlow()
      } else {
        // Usual case: no code on the callback URL. Reload the stored success
        // URL in the web view, which then redirects to redirect_uri?code=…
        handleLoginSuccess()
      }
      return NSNumber(value: true)
    }

    if host == "uaepassfail" || (!failureHost.isEmpty && host == failureHost) {
      completeUAEPassFailure(from: url)
      dismissPresentedUAEPassFlow()
      return NSNumber(value: true)
    }

    return nil
  }

  // MARK: - Helpers (Swift-only)

  private func completeUAEPassSuccess(from url: URL) -> Bool {
    guard let code = url.valueOf("code"), !code.isEmpty else {
      return false
    }
    UAEPass.complete(code: code, returnedState: url.valueOf("state"))
    return true
  }

  private func completeUAEPassFailure(from url: URL) {
    let message =
      url.valueOf("error_description") ??
      url.valueOf("error") ??
      "UAE PASS login was cancelled"

    UAEPass.reject(withCode: UAEPass.errorCancelled, message: message, error: nil)
  }

  private func dismissPresentedUAEPassFlow() {
    DispatchQueue.main.async {
      UAEPass.activeController?.dismissFlow()
    }
  }

  private static func presentLoginScreen() {
    guard let presenter = UserInterfaceInfo.topViewController() else {
      reject(withCode: errorLoginFailed,
             message: "No view controller available to present UAE PASS login",
             error: nil)
      return
    }

    // Always present modally in our own navigation controller. Pushing onto
    // the host app's navigation controller (e.g. react-native-screens) and
    // later popping it to root corrupts the app's navigation stack.
    let viewController = UAEPassViewController()
    let navController = UINavigationController(rootViewController: viewController)
    navController.presentationController?.delegate = viewController
    presenter.present(navController, animated: true, completion: nil)
  }

  static func randomState(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in letters.randomElement()! })
  }
}

extension UAEPass {
  @objc(clearPromiseHandlers)
  public static func clearPromiseHandlers() {
    resolveResponse = nil
    rejectResponse = nil
  }

  /// Resolves the pending login, rejecting instead if the authorization
  /// server echoed back a different `state` than the one we sent.
  static func complete(code: String, returnedState: String?) {
    if let returnedState = returnedState, !returnedState.isEmpty,
       let sentState = state, returnedState != sentState {
      reject(withCode: errorStateMismatch,
             message: "UAE PASS returned an unexpected state parameter",
             error: nil)
      return
    }
    resolve(withAccessCode: code)
  }

  @objc(resolveWithAccessCode:)
  public static func resolve(withAccessCode accessCode: String) {
    guard let resolve = resolveResponse else { return }

    var payload: [String: String] = ["accessCode": accessCode]
    if let state = state {
      payload["state"] = state
    }
    clearPromiseHandlers()
    resolve(payload)
  }

  @objc(rejectWithCode:message:error:)
  public static func reject(
    withCode code: String,
    message: String,
    error: NSError?
  ) {
    guard let reject = rejectResponse else { return }

    let nsError = error ?? NSError(
      domain: "UAEPass",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: message]
    )

    clearPromiseHandlers()
    reject(code, message, nsError)
  }
}

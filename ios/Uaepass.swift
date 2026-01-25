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

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }

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
      if let topViewController = UserInterfaceInfo.topViewController() {
        if let webViewController = topViewController as? UAEPassWebViewController {
          print("UAEPASS_DEBUG forceReload (top VC is web)")
          webViewController.forceReload()
          return
        }
        if let container = topViewController as? UAEPassViewController,
           let embeddedWebVC = container.embeddedWebVC {
          print("UAEPASS_DEBUG forceReload (embedded web)")
          embeddedWebVC.forceReload()
          return
        }
      }
    }
  }

  @objc
  func handleLoginFailure() {
    guard let webViewController = UserInterfaceInfo.topViewController() as? UAEPassWebViewController else {
      return
    }
    webViewController.foreceStop()
  }

  @objc
  func login(_ params: [String: String],
             resolve:  @escaping RCTPromiseResolveBlock,
             rejecter reject:  @escaping RCTPromiseRejectBlock) -> Void {

    UAEPass.resolveResponse = resolve
    UAEPass.rejectResponse = reject

    if( params["env"]?.isEmpty == false &&
        params["clientId"]?.isEmpty == false &&
        params["redirectURL"]?.isEmpty == false &&
        params["successHost"]?.isEmpty == false &&
        params["failureHost"]?.isEmpty == false &&
        params["scheme"]?.isEmpty == false &&
        params["scope"]?.isEmpty == false
    ){
      UAEPass.env = params["env"]
      UAEPass.clientId = params["clientId"]
      UAEPass.redirectURL = params["redirectURL"]
      UAEPass.successHost = params["successHost"]
      UAEPass.failureHost = params["failureHost"]
      UAEPass.scheme = params["scheme"]
      UAEPass.scope = params["scope"]

      UAEPass.locale = "en"
      if(params["locale"]?.isEmpty == false){
        UAEPass.locale = params["locale"]
      }

      DispatchQueue.main.async {
        let viewController = UAEPassViewController()
        let topViewController = UserInterfaceInfo.topViewController()
        let navController = topViewController as? UINavigationController ?? topViewController?.navigationController

        if let navController = navController {
          navController.pushViewController(viewController, animated: true)
        } else {
          topViewController?.present(viewController, animated: true, completion: nil)
        }
      }

    } else {
      UAEPass.reject(
        withCode: "ERROR",
        message: "One or more required parameters are missing",
        error: NSError(domain: "UAEPass", code: 400)
      )
    }
  }

  @objc
  func logout(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    DispatchQueue.main.async {
      HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
      WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
        records.forEach { record in
          WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
        }
      }
    }
    resolve("success")
  }

  // =========================================================
  // ✅ Redirect URL handler (ObjC + Swift compatible)
  // - Returns @YES when handled (success/failure)
  // - Returns nil when not a UAEPASS URL
  // Selector matches header: -handleRedirectUrl:(NSURL *)url
  // =========================================================

  @objc(handleRedirectUrl:)
  func handleRedirectUrl(_ url: URL) -> NSNumber? {

    let successHost = (getSuccessHost() ?? "").lowercased()
    let failureHost = (getFailureHost() ?? "").lowercased()
    let urlString = url.absoluteString.lowercased()
    let host = (url.host ?? "").lowercased()

    let isSuccess =
      (!successHost.isEmpty && urlString.contains(successHost)) ||
      host == "uaepasssuccess"

    if isSuccess {
      let didResolve = completeUAEPassSuccess(from: url)
      handleLoginSuccess()
      if didResolve { dismissPresentedUAEPassFlow() }
      return NSNumber(value: true)
    }

    let isFailure =
      (!failureHost.isEmpty && urlString.contains(failureHost)) ||
      host == "uaepassfail"

    if isFailure {
      print("UAEPASS_DEBUG Handling UAEPass failure")
      completeUAEPassFailure(from: url)
      handleLoginFailure() // ✅ correct
      dismissPresentedUAEPassFlow()
      return NSNumber(value: true)
    }

    return nil
  }

  // MARK: - Helpers (Swift-only)

  private func completeUAEPassSuccess(from url: URL) -> Bool {
    guard
      let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
      let code = queryItems.first(where: { $0.name == "code" })?.value,
      !code.isEmpty
    else {
      return false
    }

    UAEPass.resolve(withAccessCode: code)
    return true
  }

  private func completeUAEPassFailure(from url: URL) {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let message =
      components?.queryItems?.first(where: { $0.name == "error_description" })?.value ??
      components?.queryItems?.first(where: { $0.name == "error" })?.value ??
      "UAE PASS login failed"

    UAEPass.reject(withCode: "ERROR", message: message, error: nil)
  }

  private func dismissPresentedUAEPassFlow() {
    DispatchQueue.main.async {
      guard let top = UserInterfaceInfo.topViewController() else { return }

      // If UAEPASS is presented modally
      let topName = NSStringFromClass(type(of: top))
      if topName.contains("UAEPass") {
        top.dismiss(animated: true)
        return
      }

      // If UAEPASS is in navigation stack
      if let nav = top.navigationController {
        if nav.viewControllers.contains(where: { NSStringFromClass(type(of: $0)).contains("UAEPass") }) {
          nav.popToRootViewController(animated: true)
        }
      }
    }
  }
}

extension UAEPass {
  @objc(clearPromiseHandlers)
  public static func clearPromiseHandlers() {
    resolveResponse = nil
    rejectResponse = nil
  }

  @objc(resolveWithAccessCode:)
  public static func resolve(withAccessCode accessCode: String) {
    guard let resolve = resolveResponse else { return }

    var payload: [String: String] = [:]
    payload["accessCode"] = accessCode
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

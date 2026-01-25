//
//  UAEPass.swift
//
//  Created by Vyshakh on 07/11/2023.
//  parakkatvyshakh@gmail.com
//

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
  func handleLoginSuccess(){
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
  func handleLoginFailure(){
    guard let webViewController = UserInterfaceInfo.topViewController() as? UAEPassWebViewController  else {
      return
    }
    webViewController.foreceStop()
  }

  
  
  @objc
  func login(_ params: [String: String], resolve:  @escaping RCTPromiseResolveBlock, rejecter reject:  @escaping RCTPromiseRejectBlock) -> Void {
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

    }else{
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
    // this line is crashing, need to check this logic
    // UAEPASSRouter.shared.uaePassToken = nil
    resolve("success")
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
    guard let resolve = resolveResponse else {
      return
    }

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
    guard let reject = rejectResponse else {
      return
    }

    let nsError = error ?? NSError(
      domain: "UAEPass",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: message]
    )

    clearPromiseHandlers()
    reject(code, message, nsError)
  }
}

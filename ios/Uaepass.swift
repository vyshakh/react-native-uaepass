//
//  UAEPass.swift
//
//  Created by Vyshakh on 07/11/2023.
//  parakkatvyshakh@gmail.com
//

import UAEPassClient

@objc(UAEPass)
class UAEPass: NSObject {
  
  @objc public static var resolveResponse: RCTPromiseResolveBlock!
  @objc public static var rejectResponse: RCTPromiseRejectBlock!
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
  func getSuccessHost() -> String{
    return UAEPass.successHost!
  }

  @objc
  func getFailureHost() -> String{
    return UAEPass.failureHost!
  }

  
  @objc
  func handleLoginSuccess(){
    if let topViewController = UserInterfaceInfo.topViewController() {
        if let webViewController = topViewController as? UAEPassWebViewController {
            webViewController.forceReload()
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

      DispatchQueue.main.async {
        let viewController = UAEPassViewController()
        let topViewController = UIApplication.shared.windows.last { $0.isKeyWindow }?.rootViewController
          topViewController?.present(viewController, animated: true, completion: nil)
      }

    }else{
      let error = NSError(domain: "", code: 400)
      UAEPass.rejectResponse("ERROR", "One or more required parameters are missing", error)
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
    UAEPASSRouter.shared.uaePassToken = nil
    resolve("success")
  }
  
}



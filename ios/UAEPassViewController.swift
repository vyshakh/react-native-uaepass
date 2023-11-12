//
//  UAEPassViewController.swift
//
//  Created by Vyshakh on 18/10/2023.
//  parakkatvyshakh@gmail.com

import UAEPassClient


class UAEPassViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    UAEPASSRouter.shared.spConfig = SPConfig(redirectUriLogin: UAEPass.redirectURL!,
                                             scope: "urn:uae:digitalid:profile",
                                             state: randomString(length: 24),  //Randomly Generated Code 24 alpha numeric.
                                             successSchemeURL: UAEPass.scheme + "://" + UAEPass.successHost!, //client success url scheme.
                                             failSchemeURL: UAEPass.scheme + "://" + UAEPass.failureHost!, //client failure url scheme.
                                             signingScope: UAEPass.scope!) // client signing scope.
    UAEPASSRouter.shared.environmentConfig = UAEPassConfig(clientID: UAEPass.clientId!, clientSecret: "", env: .staging)

    login()

  }
    
  func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return  String((0..<length).map{ _ in letters.randomElement()! })
  }
   

  func login() {
    
    if let webVC = UAEPassWebViewController.instantiate() as? UAEPassWebViewController {
      
      webVC.urlString = UAEPassConfiguration.getServiceUrlForType(serviceType: .loginURL)
      //print(webVC.urlString)
      let topViewController = UIApplication.shared.windows.last { $0.isKeyWindow }?.rootViewController
//      if let topViewController = UserInterfaceInfo.topViewController() {
        webVC.onUAEPassSuccessBlock = {(code: String?) -> Void in
          topViewController?.dismiss(animated: true)
          if let code = code {
            var returnData = [String: String]()
            returnData["accessCode"] = code
            UAEPass.resolveResponse(returnData)
          }else{
            let error = NSError(domain: "", code: 400)
            UAEPass.rejectResponse("ERROR", "Failed to get access code", error)
          }
        }
        webVC.onUAEPassFailureBlock = {(response: String?) -> Void in
          topViewController?.dismiss(animated: true)
          let error = NSError(domain: "", code: 400)
          UAEPass.rejectResponse("ERROR", response, error)
        }
        webVC.reloadwithURL(url: webVC.urlString)
        self.present(webVC, animated: true)
//      }
    }
  }
  
  
  
  
  
  
}

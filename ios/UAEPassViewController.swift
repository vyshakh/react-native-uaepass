//
//  UAEPassViewController.swift
//
//  Created by Vyshakh on 18/10/2023.
//  parakkatvyshakh@gmail.com

import UAEPassClient


class UAEPassViewController: UIViewController {
  // Track whether the flow already finished to avoid double-callbacks on dismissal
  private var didCompleteFlow = false
  weak var embeddedWebVC: UAEPassWebViewController?
  private var didStartLogin = false
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !didStartLogin else { return }
    didStartLogin = true
    
    UAEPASSRouter.shared.spConfig = SPConfig(redirectUriLogin: UAEPass.redirectURL!,
                                             scope: "urn:uae:digitalid:profile",
                                             state: randomString(length: 24),  //Randomly Generated Code 24 alpha numeric.
                                             successSchemeURL: UAEPass.scheme + "://" + UAEPass.successHost!, //client success url scheme.
                                             failSchemeURL: UAEPass.scheme + "://" + UAEPass.failureHost!, //client failure url scheme.
                                             signingScope: UAEPass.scope!) // client signing scope.

      UAEPASSRouter.shared.sdkLang = .english
      if(UAEPass.locale == "ar"){
            UAEPASSRouter.shared.sdkLang = .arabic
      }

      if(UAEPass.env == "production"){
          UAEPASSRouter.shared.environmentConfig = UAEPassConfig(clientID: UAEPass.clientId!, clientSecret: "", env: .production)
      }
      else{
          UAEPASSRouter.shared.environmentConfig = UAEPassConfig(clientID: UAEPass.clientId!, clientSecret: "", env: .staging)
      }

    login()

  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
 
    let topViewController = UserInterfaceInfo.topViewController()
    let navController = self.navigationController ?? (topViewController as? UINavigationController ?? topViewController?.navigationController)


    if self.isBeingDismissed || self.navigationController?.isBeingDismissed == true {
      self.didCompleteFlow = false

      if let navController = navController {
        navController.popToRootViewController(animated: true)
      } else {
        topViewController?.dismiss(animated: true)
      }

      UAEPass.reject(
        withCode: "ERROR",
        message: "canceled",
        error: NSError(domain: "UAEPass", code: 400)
      )
    }
  }
    
  func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return  String((0..<length).map{ _ in letters.randomElement()! })
  }
  
  
  func login() {
    
    if let webVC = UAEPassWebViewController.instantiate() as? UAEPassWebViewController {
      
      webVC.urlString = UAEPassConfiguration.getServiceUrlForType(serviceType: .loginURL)
      embeddedWebVC = webVC
      //print(webVC.urlString)
      let topViewController = UserInterfaceInfo.topViewController()
      let navController = self.navigationController ?? (topViewController as? UINavigationController ?? topViewController?.navigationController)
//      if let topViewController = UserInterfaceInfo.topViewController() {
      webVC.onUAEPassSuccessBlock = {(code: String?) -> Void in
        self.didCompleteFlow = true
        if let navController = navController {
          navController.popToRootViewController(animated: true)
        } else {
          topViewController?.dismiss(animated: true)
        }
        if let code = code, !code.isEmpty {
          UAEPass.resolve(withAccessCode: code)
        } else {
          UAEPass.reject(
            withCode: "ERROR",
            message: "Failed to get access code",
            error: NSError(domain: "UAEPass", code: 400)
          )
        }
      }
      webVC.onUAEPassFailureBlock = {(response: String?) -> Void in
        self.didCompleteFlow = true
        if let navController = navController {
          navController.popToRootViewController(animated: true)
        } else {
          topViewController?.dismiss(animated: true)
        }
        UAEPass.reject(
          withCode: "ERROR",
          message: response ?? "UAE PASS login failed",
          error: NSError(domain: "UAEPass", code: 400)
        )
      }
      webVC.onDismiss = {
          guard self.didCompleteFlow == true else { return }
          self.didCompleteFlow = false
          if let navController = navController {
            navController.popToRootViewController(animated: true)
          } else {
            topViewController?.dismiss(animated: true)
          }
          UAEPass.reject(
            withCode: "ERROR",
            message: "canceled",
            error: NSError(domain: "UAEPass", code: 400)
          )
      }

      self.addChild(webVC)
      _ = self.view.addSubviewStretched(subview: webVC.view)
      webVC.didMove(toParent: self)
      webVC.reloadwithURL(url: webVC.urlString)
    }
  }
}

//
//  UserInterfaceInfo.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 5/8/19.
//  Copyright © 2019 Mohammed Gomaa. All rights reserved.
//

import UIKit

@objc public class UserInterfaceInfo: NSObject {
    @objc public class func topViewController() -> UIViewController? {
        guard let windowRootViewController = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController else {
            return nil
        }
        return findTopViewController(candidateViewController: windowRootViewController)
    }
    
    private class func findTopViewController(candidateViewController: UIViewController) -> UIViewController {
        if let presentedVC = candidateViewController.presentedViewController {
            return findTopViewController(candidateViewController: presentedVC)
        } else if let tabBarVC = candidateViewController as? UITabBarController,
            let selectedVC = tabBarVC.selectedViewController {
            return findTopViewController(candidateViewController: selectedVC)
            
        } else if let navigationVC = candidateViewController as? UINavigationController,
            let visibleVC = navigationVC.visibleViewController {
            return findTopViewController(candidateViewController: visibleVC)
        } else {
            return candidateViewController
        }
    }
}

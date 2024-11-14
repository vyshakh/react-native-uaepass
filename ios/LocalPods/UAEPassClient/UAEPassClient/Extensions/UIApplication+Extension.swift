//
//  UIApplication.swift
//
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 8/27/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//
import UIKit
import SafariServices

@objc public extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }

    static func showPDFFile(fileURL: URL) {
        let documentController = UIDocumentInteractionController(url: fileURL)
        documentController.delegate = topViewController() as? UIDocumentInteractionControllerDelegate
        documentController.presentPreview(animated: true)
    }

    static func showWebview(fileURL: URL) {
         DispatchQueue.main.async {
         let safariVC = SFSafariViewController(url: fileURL)
            topViewController()?.present(safariVC, animated: true, completion: nil)
        }
    }
}

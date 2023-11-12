//
//  Configuration+UAEPassSigning.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 10/22/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation
import UIKit
//1 - Generate the token
// trustedx-authserver/oauth/main-as/token
// for ids: oauth2/authorize/token
//2 - Upload the file with it's properties to be signed
// trustedx-resources/esignsp/v2/signer_processes
//3 Open it in the browser (form tasks.pending.url which received from previous step)  :
// trustedx-resources/esignsp/v2/ui?signerProcessId=4cbhkk9afnceq0ebevs0s7be1el33rbn
//4 Download signed dowcument.
// trustedx-resources/esignsp/v2/documents/dngo2mlsng3h6qn48jv2msuc7264aovl/content
//5 - Delete signed document.
// trustedx-resources/esignsp/v2/signer_processes/unab297j63dl44umiu3n6d42h0vr88m1
// User Profile
//trustedx-resources/openid/v1/users/me
//

public enum UAEPAssParams: String {
    
    case responseType = "code"
    case acrValuesAppToApp = "urn:digitalid:authentication:flow:mobileondevice"
    case acrValuesWebView = "urn:safelayer:tws:policies:authentication:level:low"
    
    public func get() -> String {
        return rawValue
    }
}
@objc public enum UAEPASSEnvirnonment: Int {
    case production
    case staging
    case qa
    case dev
}

@objc public enum UAEPassServiceType: Int {
    case loginURL
    case userProfileURL
    case token
    case tokenTX
    case uploadFile
    case downloadFile
    case deleteFile
    
    public func getRequestType() -> String? {
        switch self {
        case .token : return "POST"
        case .tokenTX : return "POST"
        case .userProfileURL: return "GET"
        case .uploadFile : return "POST"
        case .downloadFile: return "GET"
        case .deleteFile: return "DELETE"
        case .loginURL: return nil
        }
    }
    
    public func getContentType() -> String? {
        switch self {
        case .token : return "application/x-www-form-urlencoded"
        case .tokenTX : return "application/x-www-form-urlencoded"
        case .userProfileURL : return "application/x-www-form-urlencoded"
        case .uploadFile : return "multipart/form-data"
        case .downloadFile: return nil
        case .deleteFile: return nil
        case .loginURL: return nil
        }
    }
    
}
@objc public class UAEPassConfiguration: NSObject {
    @objc public static func getServiceUrlForType(serviceType: UAEPassServiceType) -> String {
        let txBaseURL = UAEPASSRouter.shared.environmentConfig.txBaseURL
        switch serviceType {
        case .loginURL:
            var serviceUrl = UAEPASSRouter.shared.environmentConfig.authURL
            let spConfig = UAEPASSRouter.shared.spConfig
            serviceUrl += "?redirect_uri=" + spConfig.redirectUriLogin
            serviceUrl += "&client_id=" + UAEPASSRouter.shared.environmentConfig.clientID
            serviceUrl += "&response_type=" + UAEPAssParams.responseType.get()
            serviceUrl += "&state=" + spConfig.state
            serviceUrl += "&scope=" + spConfig.loginScope
            
            //Check If UAE Pass App is installed to redirect, otherwise open AppStore Link.
            let schemeString = UAEPASSRouter.shared.environmentConfig.uaePassSchemeURL
            if UIApplication.shared.canOpenURL(URL(string: schemeString)!) {
                serviceUrl += "&acr_values=" + UAEPAssParams.acrValuesAppToApp.get()
            } else {
                serviceUrl += "&acr_values=" + UAEPAssParams.acrValuesWebView.get()
            }
            return serviceUrl
        case .token:
            return UAEPASSRouter.shared.environmentConfig.tokenURL
        case .tokenTX:
            return UAEPASSRouter.shared.environmentConfig.txTokenURL
        case .userProfileURL:
            return UAEPASSRouter.shared.environmentConfig.profileURL
        case .uploadFile, .deleteFile:
            return txBaseURL + "trustedx-resources/esignsp/v2/signer_processes"
        case .downloadFile:
            return txBaseURL + "trustedx-resources/esignsp/v2/documents/"
        }
    }
}

//
//  UAEPassConfigQA.swift
//
//  Created by Mohammed Gomaa on 11/19/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import UIKit

@objc public class UAEPassConfig: NSObject {
    // MARK: **** UAE Pass Configuration ****
    var txBaseURL: String
    var authURL: String
    var tokenURL: String
    var txTokenURL: String
    var profileURL: String
    var clientID: String
    var clientSecret: String
    var eSignStart: String
    var eSignRequest: String
    var eSignSign: String

    public var env: UAEPASSEnvirnonment
    public var uaePassSchemeURL: String
    /*
    Logout
    https://id.uaepass.ae/idshub/logout?redirect_uri= { url where to return after logout from UAE PASS}
     */

    @objc public required init(clientID: String, clientSecret: String, env: UAEPASSEnvirnonment) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.env = env
        var baseURL = BaseUrls.prodTX.get()
        var eSignBaseURL = BaseUrls.eSignProd.get()
        switch env {
        case .production:
            uaePassSchemeURL = "uaepass://"
            txBaseURL = BaseUrls.prodTX.get()
            authURL = "\(baseURL)idshub/authorize"
            tokenURL = "\(baseURL)idshub/token"
            txTokenURL = "\(baseURL)trustedx-authserver/oauth/main-as/token"
            profileURL = "\(baseURL)idshub/userinfo"
            eSignStart = "\(eSignBaseURL)start?certType="
            eSignRequest = "\(eSignBaseURL)request?certType="
            eSignSign = "\(eSignBaseURL)sign?certType="
        case .staging:
            uaePassSchemeURL = "uaepassstg://"
            txBaseURL = BaseUrls.stgTX.get()
            baseURL = BaseUrls.stgTX.get()
            eSignBaseURL = BaseUrls.eSignSTG.get()
            authURL = "\(baseURL)idshub/authorize"
            tokenURL = "\(baseURL)idshub/token"
            txTokenURL = "\(baseURL)trustedx-authserver/oauth/main-as/token"
            profileURL = "\(baseURL)idshub/userinfo"
            eSignStart = "\(eSignBaseURL)start?certType="
            eSignRequest = "\(eSignBaseURL)request?certType="
            eSignSign = "\(eSignBaseURL)sign?certType="
        case .qa:
            uaePassSchemeURL = "uaepassqa://"
            txBaseURL = BaseUrls.qaTX.get()
            baseURL = BaseUrls.qaTX.get()
            eSignBaseURL = BaseUrls.eSignQA.get()
            authURL = "\(baseURL)idshub/authorize"
            tokenURL = "\(baseURL)idshub/token"
            txTokenURL = "\(baseURL)trustedx-authserver/oauth/main-as/token"
            profileURL = "\(baseURL)idshub/userinfo"
            eSignStart = "\(eSignBaseURL)start?certType="
            eSignRequest = "\(eSignBaseURL)request?certType="
            eSignSign = "\(eSignBaseURL)sign?certType="
        case .dev:
            //https://dev-ids.uaepass.ae/oauth2/authorize
            uaePassSchemeURL = "uaepassdev://"
            txBaseURL = BaseUrls.devTX.get()
            baseURL = BaseUrls.devTX.get()
            eSignBaseURL = BaseUrls.eSignDev.get()
            authURL = "https://dev-ids.uaepass.ae/oauth2/authorize"
            tokenURL = "https://dev-ids.uaepass.ae/oauth2/token"
            txTokenURL = "https://dev-ids.uaepass.ae/oauth2/trustedx-authserver/oauth/main-as/token"
            profileURL = "https://dev-ids.uaepass.ae/oauth2/userinfo"
            eSignStart = "\(eSignBaseURL)start?certType="
            eSignRequest = "\(eSignBaseURL)request?certType="
            eSignSign = "\(eSignBaseURL)sign?certType="
        }
    }
    
    func getESignStart(type: ESignType) -> String {
        return eSignStart + type.rawValue
    }
    
    func getESRequest(type: ESignType) -> String {
        return eSignRequest + type.rawValue
    }
    
    func getESignSign(type: ESignType) -> String {
        return eSignSign + type.rawValue
    }
}


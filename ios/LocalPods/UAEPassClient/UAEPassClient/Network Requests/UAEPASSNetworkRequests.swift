//
//  Service.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 12/27/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

@objc public class UAEPASSNetworkRequests: NSObject {
    
    @objc public static let shared = UAEPASSNetworkRequests()

    private override init() {}
    
    // MARK: - Get UAE Pass Token
    @objc public func getUAEPassToken(code: String, completion: @escaping (UAEPassToken?) -> Void, onError: @escaping (ServiceErrorType) -> Void) {
        let path: String = UAEPassConfiguration.getServiceUrlForType(serviceType: .token)
        guard let serviceUrl = URL(string: path) else { return }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        let authUser = UAEPASSRouter.shared.environmentConfig.clientID
        let authPass = UAEPASSRouter.shared.environmentConfig.clientSecret
        let authStr = "\(authUser):\(authPass)"
        let authData = authStr.data(using: .ascii)!
        let authValue = "Basic \(authData.base64EncodedString(options: []))"
        request.setValue(authValue, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        guard let data : Data = "grant_type=authorization_code&redirect_uri=\(UAEPASSRouter.shared.spConfig.redirectUriLogin)&code=\(code)".data(using: .utf8) else {
            return
        }
        request.httpBody = data
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if error != nil {
                DispatchQueue.main.async {
                    onError(.unAuthorizedUAEPass)
                }
            }
            if let data = data {
                do {
                    let jsonDecoder = JSONDecoder()
                    let responseModel = try jsonDecoder.decode(UAEPassToken.self, from: data)
                    
                    if responseModel.error != nil {
                        if responseModel.error == "invalid_request" {
                            DispatchQueue.main.async {
                                onError(.unAuthorizedUAEPass)
                            }
                        } else {
                            DispatchQueue.main.async {
                                onError(.unknown)
                            }
                        }
                    } else {
                        UAEPASSRouter.shared.uaePassToken = responseModel.accessToken ?? nil
                        DispatchQueue.main.async {
                            completion(responseModel)
                        }
                        print("### UAE Pass Token : \(responseModel.accessToken ?? "")")
                    }
                } catch {
                    debugPrint(error)
                    DispatchQueue.main.async {
                        onError(.unAuthorizedUAEPass)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // MARK: - Get UAE Pass User Profile
    public func getUAEPassUserProfile(token: String, completion: @escaping (UAEPassUserProfile?) -> Void, onError: @escaping (ServiceErrorType) -> Void) {
        let path: String = UAEPassConfiguration.getServiceUrlForType(serviceType: .userProfileURL)
        guard let url = URL(string: path) else { return }
        var request : URLRequest = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let dataTask = URLSession.shared.dataTask(with: request) {
            data,response,error in
            if error != nil {
                DispatchQueue.main.async {
                    onError(.unAuthorizedUAEPass)
                }
            }
            if let data = data {
                do {
                    let jsonDecoder = JSONDecoder()
                    let responseModel = try jsonDecoder.decode(UAEPassUserProfile.self, from: data)
                    DispatchQueue.main.async {
                        completion(responseModel)
                    }
                    print("### UAE Pass User email : \(responseModel.email ?? "")")
                } catch {
                    debugPrint(error)
                    DispatchQueue.main.async {
                        onError(.unableToFetchUserData)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        dataTask.resume()
    }
    
    // MARK: - Downloading the document -
    
    public func downloadPdf(pdfName: String, documentURL: String, completion: @escaping (String, Bool) -> Void, onError: @escaping (ServiceErrorType) -> Void) {
            DispatchQueue.main.async {
                if let url = URL(string: documentURL), let resourceDocPath = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last {
                    let pdfData = try? Data.init(contentsOf: url)
                    let actualPath = resourceDocPath.appendingPathComponent(pdfName)
                    do {
                        try pdfData?.write(to: actualPath, options: .atomic)
                        print("pdf successfully saved!")
                        completion(actualPath.absoluteString, true)
                    } catch {
                        completion("", false)
                    }
                }
            }
        }
        
    public func generateSigningToken(requestData: UAEPassSigningRequest,
                                                 completion: @escaping (String?) -> Void,
                                                 onError: @escaping (ServiceErrorType) -> Void) {
        
        guard let urlRequest = self.buildUAEPASSSigningRequest(requestData: requestData) else {
            onError(.unknown)
            return
        }
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest, completionHandler: { data, response, error in
            if let error = error {
                debugPrint(error)
                return
            }
            // Serialize the data into an object
            if let data = data {
                do {
                    guard let serviceType = requestData.serviceType else {
                        return
                    }
                    let jsonDecoder = JSONDecoder()
                    switch serviceType {
                    case .token, .tokenTX:
                        let responseModel = try jsonDecoder.decode(UAEPassToken.self, from: data)
                        UserDefaults.standard.set(responseModel.accessToken ?? "", forKey: "UAEPassSigningBearer")
                        completion("DONE")
                    case .deleteFile:
                        completion("DONE")
                    default:
                        break
                    }
                    
                } catch {
                    print("Error during JSON serialization: \(error.localizedDescription)")
                    onError(.optionaWrappingError)
                }
            }
        })
        task.resume()
    }
    
    
    // MARK: - Uploading the document to UAE Pass -
    
    
    func buildUAEPASSSigningRequest(requestData: UAEPassSigningRequest) -> URLRequest? {
        do {
            guard let serviceType = requestData.serviceType else {
                return nil
            }
            let path: String = UAEPassConfiguration.getServiceUrlForType(serviceType: serviceType)
            guard let url = URL(string: path) else {
                return nil
            }
            print(url)
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = serviceType.getRequestType()
            if let contentType = serviceType.getContentType() {
                urlRequest.setValue(contentType, forHTTPHeaderField: "Content-type")
            }
            
            let authUser = UAEPASSRouter.shared.environmentConfig.clientID
            let authPass = UAEPASSRouter.shared.environmentConfig.clientSecret
            let authStr = "\(authUser):\(authPass)"
            let authData = authStr.data(using: .ascii)!
            let authValue = "Basic \(authData.base64EncodedString(options: []))"
            
            urlRequest.setValue(authValue, forHTTPHeaderField: "Authorization")
            let postData = NSMutableData(data: "grant_type=client_credentials".data(using: String.Encoding.utf8)!)
            if let signScope = UAEPASSRouter.shared.spConfig.signScope {
                postData.append("&scope=\(signScope)".data(using: String.Encoding.utf8)!)
            }
            urlRequest.httpBody = postData as Data
            
            debugPrint(urlRequest)
            return urlRequest
        }
    }
}

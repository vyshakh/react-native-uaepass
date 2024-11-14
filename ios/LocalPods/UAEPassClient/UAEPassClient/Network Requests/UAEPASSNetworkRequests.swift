//
//  Service.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 12/27/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation
import Alamofire

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
                        UAEPASSRouter.shared.uaePassFullToken = responseModel
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
    @objc public func getUAEPassUserProfile(token: String, completion: @escaping (UAEPassUserProfile?) -> Void, onError: @escaping (ServiceErrorType) -> Void) {
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
    
    public func downloadSignedPdf(pdfID: String, pdfName: String, completion: @escaping (String, Bool) -> Void, onError: @escaping (ServiceErrorType) -> Void) {
        let downloadUrl: String = "\(UAEPASSRouter.shared.environmentConfig.txBaseURL)trustedx-resources/esignsp/v2/documents/\(pdfID)/content"
        let documentDirectory = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("DSPDFs")
        let fileUrl = documentDirectory.appendingPathComponent("\(pdfName).pdf")
        let destination: DownloadRequest.Destination = { _, response in
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let uaePassSigningToken = UserDefaults.standard.string(forKey: "UAEPassSigningBearer") ?? ""
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(uaePassSigningToken)",
        ]
        print(downloadUrl)
        AF.download(downloadUrl, method: .get, headers: headers, to: destination)
            .downloadProgress { progress in
                print("Download progress : \(progress)")
            }
            .responseData { response in
                print("response: \(response)")
                if response.response?.statusCode == 401 {
                    onError(.unAuthorizedUAEPass)
                    return
                }
                switch response.result {
                case .success:
                    if response.fileURL != nil, let filePath = response.fileURL?.absoluteString {
                        completion(filePath, true)
                    }
                case .failure:
                    completion("", false)
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
    
//    func uploadImage(requestData: UAEPassSigningRequest, pdfName: String, completionHandler: @escaping(UploadSignDocumentResponse?, Bool) -> Void) {
//
//        let url = URL(string:UAEPassConfiguration.getServiceUrlForType(serviceType: .uploadFile))
//        let token = UserDefaults.standard.string(forKey: "UAEPassSigningBearer") ?? ""
//
//
//        let headers: HTTPHeaders = [
//            "Authorization": "Bearer \(token)",  /*in case you need authorization header */
//            "Content-type": requestData.serviceType?.getContentType() ?? ""
//        ]
//
//        // generate boundary string using a unique per-app string
//        let boundary = UUID().uuidString
//
//        let session = URLSession.shared
//
//        // Set the URLRequest to POST and to the specified URL
//        var urlRequest = URLRequest(url: url!)
//        urlRequest.httpMethod = "POST"
//
//        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
//        // And the boundary is also set here
//        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        var data = Data()
//
//        if let singingData = requestData.signingData, let documentURL = requestData.documentURL {
//            let jsonString = String(data: singingData, encoding: .utf8)!
//            data.append(jsonString.data(using: String.Encoding.utf8)!, withName: "process" as String)
//            data.append(documentURL, withName: "document")
//        }
//
//        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
//        data.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(pdfName)\"\r\n".data(using: .utf8)!)
//        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
//        data.append(image.pngData()!)
//
//        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
//
//        // Send a POST request to the URL, with the data we created earlier
//        session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
//            if error == nil {
//                let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
//                if let json = jsonData as? [String: Any] {
//                    print(json)
//                }
//            }
//        }).resume()
//    }

    
    public func uploadDocument(requestData: UAEPassSigningRequest, pdfName: String, completionHandler: @escaping(UploadSignDocumentResponse?, Bool) -> Void) {
        
        let url = UAEPassConfiguration.getServiceUrlForType(serviceType: .uploadFile)
        let token = UserDefaults.standard.string(forKey: "UAEPassSigningBearer") ?? ""
        
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",  /*in case you need authorization header */
            "Content-type": requestData.serviceType?.getContentType() ?? ""
        ]
        // swiftlint:disable next multiple_closures_with_trailing_closure
        AF.upload(multipartFormData: { (multipartFormData) in
            
            do {
                if let singingData = requestData.signingData, let documentURL = requestData.documentURL {
                    let jsonString = String(data: singingData, encoding: .utf8)!
                    multipartFormData.append(jsonString.data(using: String.Encoding.utf8)!, withName: "process" as String)
                    multipartFormData.append(documentURL, withName: "document")
                } else {
                    let paramsProcess = requestData.processParams
                    paramsProcess?.finishCallbackUrl = HandleURLScheme.externalURLSchemeSuccess()
                    let paramsJsonStrong = try JSONEncoder().encode(paramsProcess)
                    let jsonString = String(data: paramsJsonStrong, encoding: .utf8)!
                    multipartFormData.append(jsonString.data(using: String.Encoding.utf8)!, withName: "process" as String)
                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let fileURL = URL(fileURLWithPath: documentsPath, isDirectory: true).appendingPathComponent(pdfName)
                    multipartFormData.append(fileURL, withName: "document")
                }
            } catch {
                print(error)
            }
            
        }, to: url, usingThreshold: UInt64.init(), method: .post,
                  headers: headers).responseJSON(completionHandler: { result in
            if let error = result.error {
                print(error)
                completionHandler(nil, false)
            } else if let data = result.data {
                do {
                    let jsonDecoder = JSONDecoder()
                    let responseModel = try jsonDecoder.decode(UploadSignDocumentResponse.self, from: data)
                    let str = String(data: data, encoding: .utf8) ?? ""
                    print(str)
                    print("Succesfully uploaded")
                    completionHandler(responseModel, true)
                    return
                } catch {
                    completionHandler(nil, false)
                }
            }
        })
    }
    
    public func buildUAEPASSSigningRequest(requestData: UAEPassSigningRequest) -> URLRequest? {
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

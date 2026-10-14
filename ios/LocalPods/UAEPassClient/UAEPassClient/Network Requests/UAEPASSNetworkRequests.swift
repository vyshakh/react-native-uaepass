//
//  Service.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 12/27/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ZIPFoundation


public enum ESignType: String {
    case advanced = "advanced"
    case qualified = "qualified"
}

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
        
        let authStr = "\(authUser):sandbox_stage"
        let authData = authStr.data(using: .ascii)!
        let authValue = "Basic \(authData.base64EncodedString(options: []))"
        request.setValue(authValue, forHTTPHeaderField: "Authorization")
        guard let data : Data = "grant_type=authorization_code&redirect_uri=\(UAEPASSRouter.shared.spConfig.redirectUriLogin)&code=\(code)".data(using: .utf8) else {
            return
        }
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
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
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                    print("JSON Response: \(json)")
                } catch {
                    print("Failed to parse JSON: \(error.localizedDescription)")
                }
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
    
    //    public func downloadSignedPdf(signingToken: String, pdfID: String, pdfName: String, completion: @escaping (String, Bool) -> Void, onError: @escaping (ServiceErrorType) -> Void) {
    //        let downloadUrl: String = "\(UAEPASSRouter.shared.environmentConfig.txBaseURL)trustedx-resources/esignsp/v2/documents/\(pdfID)/content"
    //        let documentDirectory = try! FileManager.default
    //            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    //            .appendingPathComponent("DSPDFs")
    //        let fileUrl = documentDirectory.appendingPathComponent("\(pdfName).pdf")
    //        let destination: DownloadRequest.Destination = { _, response in
    //            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
    //        }
    //
    //        let headers: HTTPHeaders = [
    //            "Authorization": "Bearer \(signingToken)",
    //        ]
    //        print(downloadUrl)
    //        AF.download(downloadUrl, method: .get, headers: headers, to: destination)
    //            .downloadProgress { progress in
    //                print("Download progress : \(progress)")
    //            }
    //            .responseData { response in
    //                print("response: \(response)")
    //                if response.response?.statusCode == 401 {
    //                    onError(.unAuthorizedUAEPass)
    //                    return
    //                }
    //                switch response.result {
    //                case .success:
    //                    if response.fileURL != nil, let filePath = response.fileURL?.absoluteString {
    //                        completion(filePath, true)
    //                    }
    //                case .failure:
    //                    completion("", false)
    //                }
    //            }
    //    }
    
    public func downloadSignedPdf(
        signingToken: String,
        pdfID: String,
        pdfName: String,
        completion: @escaping (String, Bool) -> Void,
        onError: @escaping (ServiceErrorType) -> Void
    ) {
        Task {
            do {
                let filePath = try await downloadSignedPdfAsync(
                    signingToken: signingToken,
                    pdfID: pdfID,
                    pdfName: pdfName
                )
                
                await MainActor.run {
                    completion(filePath, true)
                }
            } catch let error as ServiceErrorType {
                await MainActor.run {
                    onError(error)
                }
            } catch {
                print("downloadSignedPdf error: \(error)")
                await MainActor.run {
                    completion("", false)
                }
            }
        }
    }
    
    private func downloadSignedPdfAsync(
        signingToken: String,
        pdfID: String,
        pdfName: String
    ) async throws -> String {
        let downloadUrlString = "\(UAEPASSRouter.shared.environmentConfig.txBaseURL)trustedx-resources/esignsp/v2/documents/\(pdfID)/content"
        
        guard let url = URL(string: downloadUrlString) else {
            throw URLError(.badURL)
        }
        
        let documentDirectory = try FileManager.default
            .url(for: .documentDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true)
            .appendingPathComponent("DSPDFs", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: documentDirectory.path) {
            try FileManager.default.createDirectory(
                at: documentDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        let fileURL = documentDirectory.appendingPathComponent("\(pdfName).pdf")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(signingToken)", forHTTPHeaderField: "Authorization")
        
        print(downloadUrlString)
        
        let (tempURL, response) = try await URLSession.shared.download(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("statusCode: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
//            throw ServiceErrorType.unAuthorizedUAEPass
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: fileURL)
        
        return fileURL.absoluteString
    }
    
    public func eSignStart(signType: ESignType,
                           completion: @escaping (String) -> Void,
                           onError: @escaping (String) -> Void) {
        
        guard let url = URL(string: UAEPASSRouter.shared.environmentConfig.getESignStart(type: signType)) else {
            return onError("failed")
        }
        print(url)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest, completionHandler: { data, response, error in
            if let error = error {
                debugPrint(error)
                return
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8)?.removingPercentEncoding {
                print(responseString)
                completion(responseString)
            } else {
                onError("failed")
            }
        })
        task.resume()
    }
    
    public func eSignStart(url: String, signType: ESignType,
                           completion: @escaping (UAEPassESignRequest) -> Void,
                           onError: @escaping (String) -> Void) {
        guard let url = URL(string: url) else {
            return onError("failed")
        }
        print(url)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest, completionHandler: { data, response, error in
            if let data = data {
                do {
                    let jsonDecoder = JSONDecoder()
                    let responseModel = try jsonDecoder.decode(UAEPassESignRequest.self, from: data)
                    responseModel.signType = signType
                    completion(responseModel)
                } catch {
                    print("Error during JSON serialization: \(error.localizedDescription)")
                    onError("failed")
                }
            }
        })
        task.resume()
    }
    
    
    public func eSignRequest(eSignRequest: UAEPassESignRequest,
                             completion: @escaping (String) -> Void,
                             onError: @escaping (String) -> Void) {
        // Define the URL
        let urlString = UAEPASSRouter.shared.environmentConfig.getESRequest(type: eSignRequest.signType)
        guard let url = URL(string: urlString) else { return }
        
        // Boundary for multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Construct the HTTP body
        var body = Data()
        
        // Form fields
        let parameters: [String: String] = [
            "digestAlgorithm": "SHA256",
            "signIdentityId": eSignRequest.signingIdentity ?? "",
            "txId": eSignRequest.txId ?? "",
            "certType": eSignRequest.signType.rawValue
        ]
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // File data
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileURL = URL(fileURLWithPath: documentsPath, isDirectory: true).appendingPathComponent("sample.pdf")
        let fileName = fileURL.lastPathComponent
        let mimeType = "application/pdf" // Assuming PDF file type
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            print("Error reading file: \(error)")
            return
        }
        
        // Close the body
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Attach the HTTP body
        request.httpBody = body
        
        // Perform the request
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                onError("failed")
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Response status code: \(response.statusCode)")
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8)?.removingPercentEncoding {
                print("Response: \(responseString)")
                completion(responseString)
            }
        }
        task.resume()
    }
    
    public func eSignRequestLoad(eSignRequest: UAEPassESignRequest,
                                 completion: @escaping (UAEPassESignRequest) -> Void,
                                 onError: @escaping (String) -> Void) {
        guard let url = URL(string: eSignRequest.finalSignRequestURL) else {
            return onError("failed")
        }
        print(url)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest, completionHandler: { data, response, error in
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("JSON Response: \(json)")
                        // Access a specific value
                        if let accessToken = json["access_token"] as? String {
                            print("AccessToken: \(accessToken)")
                            let signRequest = eSignRequest
                            signRequest.accessToken = accessToken
                            completion(signRequest)
                        }
                    }
                } catch {
                    onError("failed")
                }
            }
        })
        task.resume()
    }
    
    
    
    public func signESign(eSignRequest: UAEPassESignRequest,
                          completion: @escaping (URL?) -> Void,
                          onError: @escaping (String) -> Void) {
        // Define the URL
        let urlString = UAEPASSRouter.shared.environmentConfig.getESignSign(type: eSignRequest.signType)
        guard let url = URL(string: urlString) else { return }
        
        // Boundary for multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(eSignRequest.accessToken, forHTTPHeaderField: "X-SIGN-ACCESSTOKEN")
        
        // Construct the HTTP body
        var body = Data()
        
        // Form fields
        let parameters: [String: String] = [
            "digestAlgorithm": "SHA256",
            "signIdentityId": eSignRequest.signingIdentity ?? "",
            "txId": eSignRequest.txId ?? ""]
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // File data
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileURL = URL(fileURLWithPath: documentsPath, isDirectory: true).appendingPathComponent("sample.pdf")
        let fileName = fileURL.lastPathComponent
        let mimeType = "application/pdf" // Assuming PDF file type
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            print("Error reading file: \(error)")
            return
        }
        
        // Close the body
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Attach the HTTP body
        request.httpBody = body
        
        // Perform the request
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                onError("failed")
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Response status code: \(response.statusCode)")
            }
            
            if let data = data {
                do {
                    // Save ZIP file to temporary directory
                    let tempDir = FileManager.default.temporaryDirectory
                    let zipFileURL = tempDir.appendingPathComponent("archive.zip")
                    try data.write(to: zipFileURL)
                    // Unzip the archive
                    let destinationURL = tempDir.appendingPathComponent("unzipped\(eSignRequest.txId ?? "123")")
                    try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                    try FileManager.default.unzipItem(at: zipFileURL, to: destinationURL)
                    // Find the first PDF file
                    if let pdfURL = try? self.findFirstPDF(in: destinationURL) {
                        print("First PDF file found at: \(pdfURL)")
                        completion(pdfURL)
                        // Do something with the PDF content
                        let pdfData = try Data(contentsOf: pdfURL)
                        print("PDF file size: \(pdfData.count) bytes")
                    } else {
                        print("No PDF files found in the ZIP archive")
                    }
                } catch {
                    print("Error during extraction: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
    
    func findFirstPDF(in directory: URL) throws -> URL? {
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for fileURL in files {
            if fileURL.pathExtension.lowercased() == "pdf" {
                return fileURL
            }
        }
        return nil
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
    
    
    public func uploadDocument(
        signingToknken: String,
        requestData: UAEPassSigningRequest,
        pdfName: String,
        completionHandler: @escaping (UploadSignDocumentResponse?, Bool) -> Void
    ) {
        Task {
            do {
                let responseModel = try await uploadDocumentAsync(
                    signingToknken: signingToknken,
                    requestData: requestData,
                    pdfName: pdfName
                )
                
                await MainActor.run {
                    completionHandler(responseModel, true)
                }
            } catch {
                print("uploadDocument error: \(error)")
                await MainActor.run {
                    completionHandler(nil, false)
                }
            }
        }
    }
    
    private func uploadDocumentAsync(
        signingToknken: String,
        requestData: UAEPassSigningRequest,
        pdfName: String
    ) async throws -> UploadSignDocumentResponse {
        let urlString = UAEPassConfiguration.getServiceUrlForType(serviceType: .uploadFile)
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(signingToknken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let processData: Data
        let documentURL: URL
        
        if let signingData = requestData.signingData,
           let providedDocumentURL = requestData.documentURL {
            processData = signingData
            documentURL = providedDocumentURL
        } else {
            let paramsProcess = requestData.processParams
            paramsProcess?.finishCallbackUrl = HandleURLScheme.externalURLSchemeSuccess()
            processData = try JSONEncoder().encode(paramsProcess)
            
            let documentsDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            documentURL = documentsDirectory.appendingPathComponent(pdfName)
        }
        
        let documentData = try Data(contentsOf: documentURL)
        let documentFileName = documentURL.lastPathComponent
        
        var body = Data()
        
        // process
        body.appendMultipartBoundary(boundary)
        body.appendMultipartDisposition(name: "process")
        body.append("Content-Type: application/json\r\n\r\n")
        body.append(processData)
        body.append("\r\n")
        
        // document
        body.appendMultipartBoundary(boundary)
        body.appendMultipartDisposition(name: "document", fileName: documentFileName)
        body.append("Content-Type: application/pdf\r\n\r\n")
        body.append(documentData)
        body.append("\r\n")
        
        // end
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("statusCode: \(httpResponse.statusCode)")
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        print(responseString)
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let responseModel = try JSONDecoder().decode(UploadSignDocumentResponse.self, from: data)
        print("Successfully uploaded")
        
        return responseModel
    }
}

private extension Data {
    mutating func append(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
    
    mutating func appendMultipartBoundary(_ boundary: String) {
        append("--\(boundary)\r\n")
    }
    
    mutating func appendMultipartDisposition(name: String, fileName: String? = nil) {
        if let fileName = fileName {
            append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        } else {
            append("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        }
    }
}

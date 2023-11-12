//
//  ReadJSONHelper.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 12/31/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation

@objc public class ReadJSONHelper: NSObject {
    @objc public func getUAEPAssSigningParametersFrom(fileName: String, _ bundle: Bundle?) -> UAEPAssSigningParameters? {
        let testBundle = bundle ?? Bundle(for: type(of: self))
        let path = testBundle.path(forResource: fileName, ofType: "json")
        let data = try? Data(contentsOf: URL(fileURLWithPath: path!), options: .alwaysMapped)
        do {
            let jsonDecoder = JSONDecoder()
            let object = try jsonDecoder.decode(UAEPAssSigningParameters.self, from: data!)
            return object
        } catch let error {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
}

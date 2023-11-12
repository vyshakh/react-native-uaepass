//
//  UAEPassUserProfile.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 1/2/19.
//  Copyright © 2019 Mohammed Gomaa. All rights reserved.
//

import Foundation

@objc public class UAEPassUserProfile: NSObject, Codable {
    
    @objc public let uuid: String?
    @objc public let acr: String?
    @objc public let idCardExpiryDate: String?
    @objc public let mobile: String?
    @objc public let nationalityEN: String?
    @objc public let dob: String?
    @objc public let domain: String?
    @objc public let userType: String?
    @objc public let firstnameEN: String?
    @objc public let sub: String?
    @objc public let lastnameEN: String?
    @objc public let email: String?
    @objc public let gender: String?
    @objc public let homeAddressEmirateCode: String?
    @objc public let amr: [String]?
    @objc public let idn: String?
    @objc public let cardHolderSignatureImage: String?
    @objc public let photo: String?
    @objc public var avatarImage: UIImage? {
        guard let imageBase64String = photo,
            let imageData = Data(base64Encoded: imageBase64String)
            else {
                return nil
        }
        return UIImage(data: imageData)
    }

    enum CodingKeys: String, CodingKey {
        case uuid
        case acr
        case idCardExpiryDate
        case mobile
        case nationalityEN
        case dob
        case domain
        case userType
        case firstnameEN//firstnameEN//, first_name
        case sub
        case lastnameEN//lastnameEN//, last_name
        case email
        case gender
        case homeAddressEmirateCode
        case amr
        case idn
        case cardHolderSignatureImage
        case photo
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try values.decodeIfPresent(String.self, forKey: .uuid)
        acr = try values.decodeIfPresent(String.self, forKey: .acr)
        idCardExpiryDate = try values.decodeIfPresent(String.self, forKey: .idCardExpiryDate)
        mobile = try values.decodeIfPresent(String.self, forKey: .mobile)
        nationalityEN = try values.decodeIfPresent(String.self, forKey: .nationalityEN)
        dob = try values.decodeIfPresent(String.self, forKey: .dob)
        domain = try values.decodeIfPresent(String.self, forKey: .domain)
        userType = try values.decodeIfPresent(String.self, forKey: .userType)
        firstnameEN = try values.decodeIfPresent(String.self, forKey: .firstnameEN)
        sub = try values.decodeIfPresent(String.self, forKey: .sub)
        lastnameEN = try values.decodeIfPresent(String.self, forKey: .lastnameEN)
        email = try values.decodeIfPresent(String.self, forKey: .email)
        gender = try values.decodeIfPresent(String.self, forKey: .gender)
        homeAddressEmirateCode = try values.decodeIfPresent(String.self, forKey: .homeAddressEmirateCode)
        amr = try values.decodeIfPresent([String].self, forKey: .amr)
        idn = try values.decodeIfPresent(String.self, forKey: .idn)
        cardHolderSignatureImage = try values.decodeIfPresent(String.self, forKey: .cardHolderSignatureImage)
        photo = try values.decodeIfPresent(String.self, forKey: .photo)
    }
    
}

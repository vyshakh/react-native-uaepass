//
//  UploadSignDocumentResponse.swift
//  UaePassDemo
//
//  Created by Mohammed Gomaa on 10/22/18.
//  Copyright © 2018 Mohammed Gomaa. All rights reserved.
//

import Foundation
public struct UploadSignDocumentResponse: Codable {
    public let processType: String?
    public let processID: String?
    public let selfURL: String?
    public let tasks: Tasks?
    public let documents: [Documents]?

    enum CodingKeys: String, CodingKey {
        case processType = "process_type"
        case processID = "id"
        case selfURL = "self"
        case tasks
        case documents
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        processType = try values.decodeIfPresent(String.self, forKey: .processType)
        processID = try values.decodeIfPresent(String.self, forKey: .processID)
        selfURL = try values.decodeIfPresent(String.self, forKey: .selfURL)
        tasks = try values.decodeIfPresent(Tasks.self, forKey: .tasks)
        documents = try values.decodeIfPresent([Documents].self, forKey: .documents)
    }
}

public struct Tasks: Codable {
    public let pending: [Pending]?
    
    enum CodingKeys: String, CodingKey {
        case pending
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pending = try values.decodeIfPresent([Pending].self, forKey: .pending)
    }
    
}

public struct Documents: Codable {
    public let docID: String?
    public let url: String?
    public let content: String?
    
    enum CodingKeys: String, CodingKey {
        case docID = "id"
        case url
        case content
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        docID = try values.decodeIfPresent(String.self, forKey: .docID)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        content = try values.decodeIfPresent(String.self, forKey: .content)
    }
    
}

public struct Pending: Codable {
    public let type: String?
    public let pendingID: String?
    public let url: String?
    
    public enum CodingKeys: String, CodingKey {
        case type
        case pendingID = "id"
        case url
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        pendingID = try values.decodeIfPresent(String.self, forKey: .pendingID)
        url = try values.decodeIfPresent(String.self, forKey: .url)
    }
}

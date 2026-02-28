//
//  Item.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 2/27/26.
//

import Foundation
import SwiftData
import UIKit

@Model
final class Message: Decodable {
    var content: String
    var sender: String
    var timestamp: Date
    
    @Transient var isFromMe: Bool {
        let localID = UIDevice.current.identifierForVendor?.uuidString ?? ""
            return sender == localID.shortHash()
        }
    
    init(content: String, sender: String, timestamp: Date = Date()) {
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case content
        case sender
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try container.decode(String.self, forKey: .content)
        self.sender = try container.decode(String.self, forKey: .sender)
        self.timestamp = Date()
    }
}

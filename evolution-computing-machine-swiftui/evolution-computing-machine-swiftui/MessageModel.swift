import Foundation
import SwiftData
import UIKit

@Model
final class Message: Decodable {
    var content: String
    var sender: String   // Maps to Go "sender" (e.g., "M4Pro")
    var senderID: String     // Maps to Go "sender_id" (the shortHash)
    var timestamp: Date
    
    @Transient var isFromMe: Bool {
        let localID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        // Compare against the ID/Hash, not the display name
        return senderID == localID.shortHash()
    }
    
    init(content: String, sender: String, senderID: String, timestamp: Date = Date()) {
        self.content = content
        self.sender = sender
        self.senderID = senderID
        self.timestamp = timestamp
    }

    // These MUST match the JSON tags in your Go struct
    enum CodingKeys: String, CodingKey {
        case content
        case sender = "sender"      // Go: json:"sender"
        case senderID = "sender_id"    // Go: json:"sender_id"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.content = try container.decode(String.self, forKey: .content)
        self.sender = try container.decode(String.self, forKey: .sender)
        self.senderID = try container.decode(String.self, forKey: .senderID)
        
        // Defaulting to current time on receipt
        self.timestamp = Date()
    }
}

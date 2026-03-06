//
//  ChannelModel.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 3/6/26.
//

import Foundation

struct Channel: Identifiable, Codable {
    // MongoDB's _id comes back as a hex string in JSON
    var id: String?
    var name: String
    var description: String
    var userIds: [String]?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
            case id
            case name
            case description
            case userIds = "user_ids"   // Ensure this matches your Go bson/json tag
            case createdAt = "created_at"
        }
}



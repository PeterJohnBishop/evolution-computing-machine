//
//  Item.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 2/27/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

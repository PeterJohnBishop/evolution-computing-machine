//
//  Untitled.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 2/27/26.
//

import Foundation
import CryptoKit

extension String {
    func shortHash() -> String {
        // 1. Convert string to data
        let inputData = Data(self.utf8)
        
        // 2. Create a SHA256 Hash
        let hashed = SHA256.hash(data: inputData)
        
        // 3. Map the hash bytes to a Hex string and take the first 6-8 chars
        return hashed.compactMap { String(format: "%02x", $0) }.joined().prefix(8).uppercased()
    }
}

//
//  EncryptionManager.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 2/28/26.
//

import Foundation
import CryptoKit

struct EncryptionManager {
    
    static let sharedKey = SymmetricKey(size: .bits256)
    
    func generateNewKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    static func encrypt(_ text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: sharedKey)
            return sealedBox.combined?.base64EncodedString()
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }

    static func decrypt(_ base64EncodedString: String) -> String? {
        guard let combinedData = Data(base64Encoded: base64EncodedString) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: sharedKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
}

//
//  WebsocketManager.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 2/27/26.
//

import SwiftUI
import Foundation
import Observation
import UIKit
import SwiftData
internal import Combine

class WebSocketManager: ObservableObject {
    var modelContext: ModelContext?
    @Published var messages: [String] = []
    @Published var isConnected = false
    
    private var webSocketTask: URLSessionWebSocketTask?
        
    // Get the unique ID for this device
//    private var deviceID: String {
//        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
//    }
    
    lazy var shortDeviceID: String = {
            let rawID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            return rawID.shortHash()
        }()
    
    
    func connect() {
            let url = URL(string: "ws://localhost:8080/ws")!
            
            var request = URLRequest(url: url)
            
            request.addValue(shortDeviceID, forHTTPHeaderField: "X-Device-ID")
            
            // request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let session = URLSession(configuration: .default)
            
            webSocketTask = session.webSocketTask(with: request)
            
            webSocketTask?.resume()
            self.isConnected = true
            receiveMessage()
        }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        self.isConnected = false
    }
    
    func sendMessage(_ text: String) {
        let messageObject: [String: Any] = [
            "type": "broadcast",
            "target": "",
            "content": text,
            "sender": shortDeviceID  
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: messageObject),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
            webSocketTask?.receive { [weak self] result in
                switch result {
                case .success(let message):
                    if case .string(let text) = message {
                        self?.handleIncomingJSON(text)
                    }
                    self?.receiveMessage()
                case .failure:
                    DispatchQueue.main.async { self?.isConnected = false }
                }
            }
        }
    
    private func handleIncomingJSON(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let context = modelContext else {
            print("Missing Model Context in Manager")
            return
        }

        do {
            let newMessage = try JSONDecoder().decode(Message.self, from: data)
            
            Task { @MainActor in
                context.insert(newMessage)
                
                try? context.save()
                
                print("Inserted: \(newMessage.content). Total in context: \((try? context.fetchCount(FetchDescriptor<Message>())) ?? 0)")
            }
        } catch {
            print("Decoding Error: \(error)")
        }
    }
}

extension WebSocketManager {
    func clearAllMessages() {
        guard let context = modelContext else { return }
        
        Task { @MainActor in
            do {
                // This deletes every instance of 'Message' from the database
                try context.delete(model: Message.self)
                try context.save()
                print("Successfully cleared all messages.")
            } catch {
                print("Failed to clear messages: \(error)")
            }
        }
    }
}

extension WebSocketManager {
    func deleteMessage(_ message: Message) {
        guard let context = modelContext else { return }
        
        Task { @MainActor in
            context.delete(message)
            try? context.save()
            print("Deleted message: \(message.content)")
        }
    }
}

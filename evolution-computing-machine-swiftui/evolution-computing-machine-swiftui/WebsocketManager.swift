import SwiftUI
import Foundation
import Observation
import UIKit
import SwiftData
internal import Combine

class WebSocketManager: ObservableObject {
    var modelContext: ModelContext?
    @Published var isConnected = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    lazy var shortDeviceID: String = {
        let rawID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        return rawID.shortHash()
    }()
    
    func connect(name: String) {
        let url = URL(string: "ws://localhost:8080/ws")!
        var request = URLRequest(url: url)
        
        request.addValue(shortDeviceID, forHTTPHeaderField: "X-Device-ID")
        request.addValue(name, forHTTPHeaderField: "X-Client-Name")
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        
        webSocketTask?.resume()
        DispatchQueue.main.async { self.isConnected = true }
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        DispatchQueue.main.async { self.isConnected = false }
    }
    
    func sendMessage(_ text: String, name: String) {
        let messageObject: [String: Any] = [
            "type": "broadcast",
            "target_id": "",
            "content": text,
            "sender": name,
            "sender_id": shortDeviceID,
            "channel": ""
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
            case .failure(let error):
                print("WebSocket connection lost: \(error)")
                DispatchQueue.main.async { self?.isConnected = false }
            }
        }
    }
    
    private func handleIncomingJSON(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let context = modelContext else { return }

        do {
            let decoder = JSONDecoder()
            let newMessage = try decoder.decode(Message.self, from: data)
            
            Task { @MainActor in
                updateNameForSender(id: newMessage.senderID, newName: newMessage.sender)
                context.insert(newMessage)
                try? context.save()
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
                try context.delete(model: Message.self)
                try context.save()
            } catch {
                print("Failed to clear messages: \(error)")
            }
        }
    }
    
    func deleteMessage(_ message: Message) {
        guard let context = modelContext else { return }
        Task { @MainActor in
            context.delete(message)
            try? context.save()
        }
    }
    
    @MainActor
    private func updateNameForSender(id: String, newName: String) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.sender == id }
        )
        
        do {
            let existingMessages = try context.fetch(descriptor)
            
            for message in existingMessages where message.senderID != newName {
                message.sender = newName
            }
        } catch {
            print("Failed to sync names: \(error)")
        }
    }
}

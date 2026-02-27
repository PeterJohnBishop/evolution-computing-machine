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
internal import Combine

class WebSocketManager: ObservableObject {
    @Published var messages: [String] = []
    @Published var isConnected = false
    
    private var webSocketTask: URLSessionWebSocketTask?
        
        // Get the unique ID for this device/app combo
        private var deviceID: String {
            return UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
        }
    
    
    func connect() {
            let url = URL(string: "ws://localhost:8080/ws")!
            
            // 1. Create a URLRequest
            var request = URLRequest(url: url)
            
            // 2. Add your unique ID as a custom header
            request.addValue(deviceID, forHTTPHeaderField: "X-Device-ID")
            
            // You can add other headers here too (e.g., Auth tokens)
            // request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let session = URLSession(configuration: .default)
            
            // 3. Initialize the task with the REQUEST instead of the URL
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
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Receive error: \(error)")
                DispatchQueue.main.async { self?.isConnected = false }
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.messages.append(text)
                    }
                default:
                    break
                }
                // Important: Re-call receiveMessage to keep listening!
                self?.receiveMessage()
            }
        }
    }
}

//
//  ChannelViewModel.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 3/6/26.
//

import Foundation
import Observation
internal import Combine

@MainActor
class ChannelManager: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let baseURL = "http://localhost:8080/v1/channel"
    
    func createChannel(name: String, description: String, userId: String) async {
        guard let url = URL(string: baseURL) else { return }
        
        let payload: [String: Any] = [
            "name": name,
            "description": description,
            "user_ids": [userId]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else { return }

            if (200...299).contains(httpResponse.statusCode) {
                print("Channel created successfully!")
                await fetchChannels()
            } else {
                if let errorMsg = String(data: data, encoding: .utf8) {
                    print("Server Error: \(errorMsg)")
                }
                await MainActor.run {
                    self.errorMessage = "Server returned status: \(httpResponse.statusCode)"
                }
            }
        } catch {
            print("Request failed: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to connect to server"
            }
        }
    }
    
    func fetchChannelByName(name: String) async {
            guard !name.isEmpty else { return }
            isLoading = true
            
            guard let url = URL(string: "\(baseURL)/\(name)") else { return }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(ChannelResponse.self, from: data)
                self.channels = response.channels
            } catch {
                self.errorMessage = "Channel '\(name)' not found."
            }
            isLoading = false
        }

    func fetchChannels() async {
        guard let url = URL(string: "\(baseURL)/all") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 1. Create the decoder
            let decoder = JSONDecoder()
            
            // 2. TELL THE DECODER TO HANDLE ISO8601 STRINGS
            decoder.dateDecodingStrategy = .iso8601
            
            // 3. Decode
            let decodedResponse = try decoder.decode(ChannelResponse.self, from: data)
            
            await MainActor.run {
                self.channels = decodedResponse.channels
            }
        } catch {
            print("Decoding error: \(error)") // This should stop happening now!
        }
    }
    
    func updateChannel(id: String, newName: String?, newDescription: String?) async {
            guard let url = URL(string: "\(baseURL)/\(id)") else { return }
            
            var updateBody: [String: Any] = [:]
            if let name = newName { updateBody["name"] = name }
            if let desc = newDescription { updateBody["description"] = desc }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: updateBody)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    await fetchChannels()
                } else {
                    self.errorMessage = "Server returned error during update"
                }
            } catch {
                self.errorMessage = "Update failed: \(error.localizedDescription)"
            }
        }

    func deleteChannel(id: String) async {
        guard let url = URL(string: "\(baseURL)/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            let (_, _) = try await URLSession.shared.data(for: request)
            self.channels.removeAll { $0.id == id }
        } catch {
            self.errorMessage = "Failed to delete"
        }
    }
}

struct ChannelResponse: Codable {
    let success: Bool
    let channels: [Channel]
}

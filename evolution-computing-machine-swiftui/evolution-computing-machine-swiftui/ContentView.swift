//
//  ContentView.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 2/27/26.
//

import SwiftUI
struct ContentView: View {
    @StateObject var socket = WebSocketManager()
    @State private var messageText = ""

    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(socket.isConnected ? .green : .red)
                    .frame(width: 10, height: 10)
                Text(socket.isConnected ? "Connected" : "Disconnected")
            }
            
            List(socket.messages, id: \.self) { msg in
                Text(msg)
            }
            
            HStack {
                TextField("Send a message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send") {
                    socket.sendMessage(messageText)
                    messageText = ""
                }
            }
            .padding()
            
            Button(socket.isConnected ? "Disconnect" : "Connect") {
                socket.isConnected ? socket.disconnect() : socket.connect()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            socket.connect()
        }
    }
}

#Preview {
    ContentView()
}

//
//  ChannelView.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 3/5/26.
//

import SwiftUI

struct ChannelView: View {
    @EnvironmentObject var socket: WebSocketManager
    @State private var channelName = ""


    var body: some View {
        VStack{
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            channelInputRow
        }
    }
    
    private var channelInputRow: some View {
        HStack(spacing: 12) {
            TextField("New Channel Name...", text: $channelName)
                .padding(10).background(Color(.systemGray6)).cornerRadius(20)
            
            Button(action: sendMessage) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(socket.isConnected ? .blue : .gray)
            }
            .disabled(channelName.isEmpty || !socket.isConnected)
        }
        .padding()
    }
    
    private func sendMessage() {
      // call send message 
    }
}

#Preview {
    let mockSocket = WebSocketManager()

    ChannelView().environmentObject(mockSocket)
}

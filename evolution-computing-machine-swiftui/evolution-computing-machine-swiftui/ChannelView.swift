//
//  ChannelView.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 3/5/26.
//

import SwiftUI

struct ChannelView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var socket: WebSocketManager
    @ObservedObject var manager: ChannelManager
    @State private var channelName: String
    @State private var channelDescription: String
    @AppStorage("senderName") private var senderName = "Guest"

    var channel: Channel

    init(manager: ChannelManager, channel: Channel) {
            self.manager = manager
            self.channel = channel
        _channelName = State(initialValue: channel.name)
        _channelDescription = State(initialValue: channel.description)
        }
    
    var body: some View {
            NavigationStack {
                VStack {
                    
                    channelInputRow
                    
                    Divider()
                    Text("Channels: \(manager.channels.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    if manager.channels.isEmpty {
                        ContentUnavailableView("No Channels",
                                             systemImage: "bubble.left.and.exclamationmark.bubble.right",
                                             description: Text("Create the first channel above to get started."))
                    } else {
                        List(manager.channels) { ch in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ch.name)
                                    .font(.headline)
                                if !ch.description.isEmpty {
                                    Text(ch.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    // Add delete logic here if needed
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Channels")
                .onAppear {
                    socket.modelContext = modelContext
                    if !socket.isConnected {
                        socket.connect(name: senderName)
                    }
                    
                    Task {
                        await manager.fetchChannels()
                    }
                }
            }
        }
    
    private var channelInputRow: some View {
        VStack{
            HStack(spacing: 12) {
                TextField("New Channel Name...", text: $channelName)
                    .padding(10).background(Color(.systemGray6)).cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(socket.isConnected ? .blue : .gray)
                }
                .disabled(channelName.isEmpty)
            }
            TextField("Channel Description (optional)...", text: $channelDescription)
                .padding(10).background(Color(.systemGray6)).cornerRadius(20)
        }.padding()

    }
    
    private func sendMessage() {
        let id = socket.shortDeviceID
        Task {
            await manager.createChannel(name: channelName, description: channelDescription, userId: id)
            channelName = ""
            channelDescription = ""
        }
        
    }
}

#Preview {
    let mockSocket = WebSocketManager()
    let mockChannelManager = ChannelManager()
    let mockChannel = Channel(
        id: "123",
        name: "",
        description: "",
        userIds: [],
        createdAt: Date()
    )

    ChannelView(manager: mockChannelManager, channel: mockChannel)
        .environmentObject(mockSocket)
}


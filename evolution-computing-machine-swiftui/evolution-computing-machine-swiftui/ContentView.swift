//
//  ContentView.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 2/27/26.
//

import SwiftUI
import _SwiftData_SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var socket = WebSocketManager()
    @State private var messageText = ""
    @Query(sort: \Message.timestamp, order: .forward) private var savedMessages: [Message]

    var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Msgr")
                                .font(.headline)
                            HStack{
                                Circle()
                                                .fill(socket.isConnected ? .green : .red)
                                                .frame(width: 8, height: 8)
                                Text(socket.isConnected ? "Connected" : "Offline")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        ConnectionSwitch(socket: socket)
                    }
                    .padding()
                    .background(.ultraThinMaterial)

                    // --- Chat History ---
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(savedMessages) { msg in
                                    ChatBubble(message: msg)
                                        .id(msg.persistentModelID)
                                        .contextMenu {
                                                    Button(role: .destructive) {
                                                        socket.deleteMessage(msg)
                                                    } label: {
                                                        Label("Delete Message", systemImage: "trash")
                                                    }
                                                    
                                                    Button {
                                                        UIPasteboard.general.string = msg.content
                                                    } label: {
                                                        Label("Copy Text", systemImage: "doc.on.doc")
                                                    }
                                                }
                                }
                            }
                            .padding()
                        }
                        .onChange(of: savedMessages.count) {
                            withAnimation {
                                proxy.scrollTo(savedMessages.last?.persistentModelID, anchor: .bottom)
                            }
                        }
                    }

                    // --- Input Field ---
                    inputField
                }
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    socket.modelContext = modelContext
                    socket.connect()
                }
                
            }
        }
    
    private var statusHeader: some View {
        HStack {
            Circle()
                .fill(socket.isConnected ? .green : .red)
                .frame(width: 8, height: 8)
            Text(socket.isConnected ? "Online" : "Connecting...")
                .font(.caption)
        }
        .padding(.bottom, 8)
    }

    private var inputField: some View {
        HStack {
            TextField("Msg", text: $messageText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            
            Button(action: {
                socket.sendMessage(messageText)
                messageText = ""
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
            }
            .disabled(messageText.isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct ConnectionSwitch: View {
    @ObservedObject var socket: WebSocketManager
    
    var body: some View {
        // We create a custom binding to intercept the toggle action
        Toggle(isOn: Binding(
            get: { socket.isConnected },
            set: { newValue in
                if newValue {
                    socket.connect()
                } else {
                    socket.disconnect()
                }
            }
        )) {
//            HStack {
//                Image(systemName: socket.isConnected ? "wifi" : "wifi.slash")
//                Text(socket.isConnected ? "Online" : "Offline")
//            }
//            .font(.subheadline)
//            .fontWeight(.medium)
//            .foregroundColor(socket.isConnected ? .green : .secondary)
        }
        .toggleStyle(SwitchToggleStyle(tint: .green)) // Makes the "On" state green
        .fixedSize() // Prevents the toggle from taking up the whole row width
        .animation(.spring(), value: socket.isConnected)
    }
}

struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromMe { Spacer() }
            
            VStack(alignment: message.isFromMe ? .trailing : .leading) {
                Text(message.content)
                Text(message.sender)
                    .font(.footnote)
                    .foregroundColor(message.isFromMe ? .white.opacity(0.5) : .primary)
                    .padding(.top, 2)
                Text(message.timestamp, format: .dateTime.hour().minute())
                    .font(.footnote)
                    .foregroundColor(message.isFromMe ? .white.opacity(0.7) : .secondary)
            }.padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(message.isFromMe ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isFromMe ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            if !message.isFromMe { Spacer() }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Message.self, configurations: config)
    
    return ContentView()
        .modelContainer(container)
}

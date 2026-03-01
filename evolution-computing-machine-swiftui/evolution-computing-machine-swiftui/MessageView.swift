//
//  ContentView.swift
//  evolution-computing-machine-swiftui
//
//  Created by M4Pro on 2/27/26.
//

import SwiftUI
import SwiftData

struct MessageView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var socket = WebSocketManager()
    
    @AppStorage("senderName") private var senderName = "Guest"
    @State private var messageText = ""
    @State private var isEncrypted = false
    
    @Query(sort: \Message.timestamp, order: .forward) private var savedMessages: [Message]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
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
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            UIPasteboard.general.string = msg.content
                                        } label: {
                                            Label("Copy", systemImage: "doc.on.doc")
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
                VStack(spacing: 0) {
                    Divider()
                    senderIdentityRow
                    messageInputRow
                }
                .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                socket.modelContext = modelContext
                socket.connect(name: senderName)
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Msgr").font(.headline)
                HStack(spacing: 4) {
                    Circle()
                        .fill(socket.isConnected ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(socket.isConnected ? "Connected" : "Offline")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            ConnectionSwitch(socket: socket, currentName: senderName)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var senderIdentityRow: some View {
        HStack {
            Text("Send as:").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            TextField("Your name", text: $senderName)
                .font(.caption)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color(.systemGray5)).cornerRadius(6)
            Spacer()
        }
        .padding(.horizontal).padding(.top, 8)
    }

    private var messageInputRow: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageText)
                .padding(10).background(Color(.systemGray6)).cornerRadius(20)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(socket.isConnected ? .blue : .gray)
            }
            .disabled(messageText.isEmpty || !socket.isConnected)
            .contextMenu {
                       Button() {
                           // send as keyImage(systemName: "person.2.shield.fill")
                       } label: {
                           Label("Secure DM", systemImage: "person.2.badge.key.fill")
                       }
                       
                       Button {
                           if isEncrypted {
                               messageText = EncryptionManager.decrypt(messageText) ?? messageText
                           } else {
                               messageText = EncryptionManager.encrypt(messageText) ?? messageText
                           }
                       } label: {
                           Label("Encrypt", systemImage: "firewall.fill")
                       }
                   }
        }
        .padding()
    }

    private func sendMessage() {
        socket.sendMessage(messageText, name: senderName)
        messageText = ""
    }
}

struct ConnectionSwitch: View {
    @ObservedObject var socket: WebSocketManager
    let currentName: String
    
    var body: some View {
        Toggle("", isOn: Binding(
            get: { socket.isConnected },
            set: { newValue in
                if newValue {
                    socket.connect(name: currentName)
                } else {
                    socket.disconnect()
                }
            }
        ))
        .toggleStyle(SwitchToggleStyle(tint: .green))
        .fixedSize()
    }
}

struct ChatBubble: View {
    let message: Message
    var body: some View {
        HStack {
            if message.isFromMe { Spacer() }
            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                HStack(spacing: 4) {
                    Text(message.sender).fontWeight(.bold)
                    Text("•")
                    Text(message.timestamp, format: .dateTime.hour().minute())
                }
                .font(.system(size: 10)).opacity(0.8)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(message.isFromMe ? Color.blue : Color(.systemGray5))
            .foregroundColor(message.isFromMe ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            if !message.isFromMe { Spacer() }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Message.self, configurations: config)
    return MessageView().modelContainer(container)
}

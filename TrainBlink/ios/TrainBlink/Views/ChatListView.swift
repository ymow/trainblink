//
//  ChatListView.swift
//  TrainBlink
//
//  Feature 5: 1-on-1 Chat Rooms
//  UI for displaying list of active chat rooms
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var chatManager = ChatManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header stats
                headerStatsView

                Divider()

                // Chat rooms list
                if chatManager.activeChatRooms.isEmpty {
                    emptyStateView
                } else {
                    chatRoomsList
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header Stats

    private var headerStatsView: some View {
        HStack(spacing: 20) {
            // Total chats
            VStack(spacing: 4) {
                Text("\(chatManager.activeChatRooms.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 30)

            // Unread count
            VStack(spacing: 4) {
                Text("\(chatManager.totalUnreadCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(chatManager.totalUnreadCount > 0 ? .blue : .primary)
                Text("Unread")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Chat Rooms List

    private var chatRoomsList: some View {
        List {
            ForEach(chatManager.activeChatRooms) { room in
                NavigationLink(destination: ChatRoomView(
                    peerId: room.peerId,
                    peerDisplayName: room.peerDisplayName
                )) {
                    ChatRoomRowView(chatRoom: room)
                }
            }
            .onDelete(perform: deleteChatRooms)
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Chats Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text("Connect with nearby peers\nto start chatting")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            if !appState.isInStation {
                Text("Enter a train station to get started")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            } else if appState.discoveredPeers.isEmpty {
                Text("Waiting for peers to appear...")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions

    private func deleteChatRooms(at offsets: IndexSet) {
        for index in offsets {
            let room = chatManager.activeChatRooms[index]
            chatManager.deleteChatRoom(peerId: room.peerId)
        }
    }
}

// MARK: - Chat Room Row View

struct ChatRoomRowView: View {
    @StateObject private var chatManager = ChatManager.shared

    let chatRoom: ChatRoom

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)

                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 22))

                // Unread badge
                if chatRoom.hasUnreadMessages {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(chatRoom.unreadCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .offset(x: 18, y: -18)
                }
            }

            // Chat info
            VStack(alignment: .leading, spacing: 4) {
                // Peer name with encounter count
                HStack(spacing: 6) {
                    Text(chatRoom.peerDisplayName)
                        .font(.headline)
                        .fontWeight(chatRoom.hasUnreadMessages ? .bold : .regular)

                    if chatRoom.encounterCount > 1 {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption2)
                            Text("\(chatRoom.encounterCount)")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }

                // Last message preview
                HStack(spacing: 0) {
                    if let lastMsg = chatRoom.lastMessage {
                        if lastMsg.isEphemeral {
                            Image(systemName: "timer")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(" ")
                        }
                    }

                    Text(chatRoom.lastMessagePreview)
                        .font(.subheadline)
                        .foregroundColor(chatRoom.hasUnreadMessages ? .primary : .secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Timestamp
            VStack(alignment: .trailing, spacing: 4) {
                Text(chatRoom.lastMessageTimeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if chatRoom.hasUnreadMessages {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Previews

#Preview("Empty State") {
    ChatListView()
        .environmentObject(AppState())
}

#Preview("With Chats") {
    let appState = AppState()
    let chatManager = ChatManager.shared

    // Set my peer ID
    chatManager.setMyPeerId(appState.sessionID)

    // Create test peers
    let peer1 = Peer(id: "peer-1", displayName: "Alice")
    let peer2 = Peer(id: "peer-2", displayName: "Bob")
    let peer3 = Peer(id: "peer-3", displayName: "Charlie")

    // Create chat rooms
    var room1 = chatManager.getChatRoom(with: peer1)
    var room2 = chatManager.getChatRoom(with: peer2)
    var room3 = chatManager.getChatRoom(with: peer3)

    // Add messages
    let msg1 = ChatMessage.textMessage(
        text: "Hey! How's it going?",
        from: "peer-1",
        to: appState.sessionID
    )
    let msg2 = ChatMessage.textMessage(
        text: "Great, thanks!",
        from: appState.sessionID,
        to: "peer-1"
    )
    let msg3 = ChatMessage.textMessage(
        text: "Are you heading downtown?",
        from: "peer-2",
        to: appState.sessionID
    )
    let msg4 = ChatMessage.ephemeralMessage(
        text: "This is an ephemeral message!",
        from: "peer-3",
        to: appState.sessionID
    )

    room1.addMessage(msg1)
    room1.addMessage(msg2)
    room2.addMessage(msg3)
    room3.addMessage(msg4)

    return ChatListView()
        .environmentObject(appState)
}

#Preview("Single Chat Row") {
    let chatManager = ChatManager.shared
    let peer = Peer(id: "peer-1", displayName: "Alice")
    var room = chatManager.getChatRoom(with: peer)

    let msg = ChatMessage.textMessage(
        text: "Hey there! This is a test message.",
        from: "peer-1",
        to: "me"
    )
    room.addMessage(msg)

    return List {
        ChatRoomRowView(chatRoom: room)
    }
    .listStyle(.plain)
}

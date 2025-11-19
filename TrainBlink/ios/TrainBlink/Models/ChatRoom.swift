//
//  ChatRoom.swift
//  TrainBlink
//
//  Feature 5: 1-on-1 Chat Rooms
//  Model representing a 1-on-1 chat room between peers
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation

/// 1-on-1 chat room between two peers
struct ChatRoom: Identifiable, Codable, Hashable, Equatable {

    // MARK: - Properties

    let id: String
    let peerId: String              // The other peer's ID
    let peerDisplayName: String     // The other peer's display name
    let createdAt: Date
    var messages: [ChatMessage]
    var isActive: Bool

    // Metadata
    var lastMessageAt: Date?
    var unreadCount: Int
    var encounterCount: Int         // Number of times encountered this peer

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        peerId: String,
        peerDisplayName: String,
        createdAt: Date = Date(),
        messages: [ChatMessage] = [],
        isActive: Bool = true,
        encounterCount: Int = 1
    ) {
        self.id = id
        self.peerId = peerId
        self.peerDisplayName = peerDisplayName
        self.createdAt = createdAt
        self.messages = messages
        self.isActive = isActive
        self.lastMessageAt = messages.last?.timestamp
        self.unreadCount = 0
        self.encounterCount = encounterCount
    }

    // MARK: - Computed Properties

    /// Last message in the chat
    var lastMessage: ChatMessage? {
        return messages.last
    }

    /// Last message text preview
    var lastMessagePreview: String {
        guard let lastMsg = lastMessage else {
            return "No messages yet"
        }
        return lastMsg.preview
    }

    /// Time ago for last message
    var lastMessageTimeAgo: String {
        guard let lastMsg = lastMessage else {
            return ""
        }
        return lastMsg.timeAgoString
    }

    /// Whether this chat has unread messages
    var hasUnreadMessages: Bool {
        return unreadCount > 0
    }

    /// Total message count
    var messageCount: Int {
        return messages.count
    }

    // MARK: - Update Methods

    /// Add a new message to the chat
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        lastMessageAt = message.timestamp

        // Update unread count if received message
        if message.receiverId != message.senderId && !message.isRead {
            unreadCount += 1
        }
    }

    /// Mark all messages as read
    mutating func markAllAsRead(myId: String) {
        for index in messages.indices {
            if messages[index].isReceivedByMe(myId: myId) && !messages[index].isRead {
                messages[index].markAsRead()
            }
        }
        unreadCount = 0
    }

    /// Close the chat room
    mutating func close() {
        isActive = false
    }

    /// Increment encounter count
    mutating func incrementEncounter() {
        encounterCount += 1
    }

    // MARK: - Static Constructors

    /// Create a new chat room with a peer
    static func createWith(peer: Peer, encounterCount: Int = 1) -> ChatRoom {
        return ChatRoom(
            peerId: peer.id,
            peerDisplayName: peer.displayName,
            createdAt: Date(),
            encounterCount: encounterCount
        )
    }

    // MARK: - Equatable

    static func == (lhs: ChatRoom, rhs: ChatRoom) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

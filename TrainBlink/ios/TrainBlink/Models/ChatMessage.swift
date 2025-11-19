//
//  ChatMessage.swift
//  TrainBlink
//
//  Feature 5: 1-on-1 Chat Rooms
//  Model representing a chat message
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation

/// Chat message sent between peers
struct ChatMessage: Identifiable, Codable, Hashable, Equatable {

    // MARK: - Properties

    let id: String
    let text: String
    let senderId: String
    let receiverId: String
    let timestamp: Date
    var isEncrypted: Bool
    var isRead: Bool
    var deliveryStatus: MessageDeliveryStatus

    // Metadata
    var encryptedData: Data?          // Encrypted message data
    var encryptionKeyId: String?      // Reference to encryption key
    var deliveredAt: Date?
    var readAt: Date?

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        text: String,
        senderId: String,
        receiverId: String,
        timestamp: Date = Date(),
        isEncrypted: Bool = false,
        isRead: Bool = false,
        deliveryStatus: MessageDeliveryStatus = .pending
    ) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.receiverId = receiverId
        self.timestamp = timestamp
        self.isEncrypted = isEncrypted
        self.isRead = isRead
        self.deliveryStatus = deliveryStatus
    }

    // MARK: - Computed Properties

    /// Whether this message was sent by me
    func isSentByMe(myId: String) -> Bool {
        return senderId == myId
    }

    /// Whether this message was received by me
    func isReceivedByMe(myId: String) -> Bool {
        return receiverId == myId
    }

    /// Time ago string (e.g., "2m ago", "1h ago")
    var timeAgoString: String {
        let interval = Date().timeIntervalSince(timestamp)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    /// Formatted time string
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// Message preview (truncated)
    var preview: String {
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text
    }

    // MARK: - Update Methods

    /// Mark message as delivered
    mutating func markAsDelivered() {
        deliveryStatus = .delivered
        deliveredAt = Date()
    }

    /// Mark message as read
    mutating func markAsRead() {
        isRead = true
        readAt = Date()
        if deliveryStatus == .delivered {
            deliveryStatus = .read
        }
    }

    /// Mark message as failed
    mutating func markAsFailed() {
        deliveryStatus = .failed
    }

    // MARK: - Static Constructors

    /// Create a text message
    static func textMessage(
        text: String,
        from senderId: String,
        to receiverId: String
    ) -> ChatMessage {
        return ChatMessage(
            text: text,
            senderId: senderId,
            receiverId: receiverId,
            timestamp: Date(),
            deliveryStatus: .pending
        )
    }

    // MARK: - Equatable

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Supporting Types

/// Message delivery status
enum MessageDeliveryStatus: String, Codable {
    case pending      // Waiting to be sent
    case sending      // Currently sending
    case sent         // Sent successfully
    case delivered    // Delivered to recipient
    case read         // Read by recipient
    case failed       // Failed to send
}

/// Message status icon
extension MessageDeliveryStatus {
    var iconName: String {
        switch self {
        case .pending:
            return "clock"
        case .sending:
            return "arrow.up.circle"
        case .sent:
            return "checkmark"
        case .delivered:
            return "checkmark.circle"
        case .read:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle"
        }
    }
}

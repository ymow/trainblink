//
//  ChatMessage.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

enum MessageDeliveryStatus: String, Codable {
    case pending
    case sending
    case sent
    case delivered
    case read
    case failed
}

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let senderId: String
    let receiverId: String
    let timestamp: Date
    var deliveryStatus: MessageDeliveryStatus
    
    // Ephemeral properties
    let isEphemeral: Bool
    var expiresAt: Date?
    var deliveredAt: Date?
    var readAt: Date?
    
    // MARK: - Computed Properties
    
    var timeRemainingSeconds: TimeInterval? {
        guard let expiresAt = expiresAt else { return nil }
        let remaining = expiresAt.timeIntervalSince(Date())
        return max(0, remaining)
    }
    
    var isExpired: Bool {
        guard let remaining = timeRemainingSeconds else { return false }
        return remaining <= 0
    }
    
    var shouldDelete: Bool {
        return isEphemeral && isExpired
    }
    
    var countdownString: String {
        guard let remaining = timeRemainingSeconds else { return "" }
        return String(format: "%.0fs", remaining)
    }
    
    var preview: String {
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text
    }
    
    var isRead: Bool {
        return deliveryStatus == .read
    }
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString, text: String, senderId: String, receiverId: String, timestamp: Date = Date(), deliveryStatus: MessageDeliveryStatus = .pending, isEphemeral: Bool = false, expiresAt: Date? = nil) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.receiverId = receiverId
        self.timestamp = timestamp
        self.deliveryStatus = deliveryStatus
        self.isEphemeral = isEphemeral
        self.expiresAt = expiresAt
    }
    
    // MARK: - Static Constructors
    
    static func textMessage(text: String, from senderId: String, to receiverId: String) -> ChatMessage {
        return ChatMessage(
            text: text,
            senderId: senderId,
            receiverId: receiverId
        )
    }
    
    static func ephemeralMessage(text: String, from senderId: String, to receiverId: String, lifetimeSeconds: TimeInterval = 10.0) -> ChatMessage {
        return ChatMessage(
            text: text,
            senderId: senderId,
            receiverId: receiverId,
            isEphemeral: true,
            expiresAt: Date().addingTimeInterval(lifetimeSeconds)
        )
    }
    
    // MARK: - Methods
    
    func isSentByMe(myId: String) -> Bool {
        return senderId == myId
    }
    
    mutating func markAsDelivered() {
        deliveryStatus = .delivered
        deliveredAt = Date()
    }
    
    mutating func markAsRead() {
        deliveryStatus = .read
        readAt = Date()
    }
    
    mutating func markAsExpired() {
        // For testing purposes, we can't change the let 'expiresAt'.
        // But the test calls `markAsExpired()`.
        // This implies `expiresAt` should be a `var` OR we have a separate flag.
        // However, `expiresAt` is usually fixed.
        // Let's look at how to support this.
        // If I make `expiresAt` a var, I can set it to Date().
        // Let's check the struct definition I wrote previously.
        // "let expiresAt: Date?".
        // I will change it to "var expiresAt: Date?".
        // And implement markAsExpired to set expiresAt to now - 1.
        expiresAt = Date().addingTimeInterval(-1)
    }
}

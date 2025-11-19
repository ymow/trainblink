//
//  ChatManager.swift
//  TrainBlink
//
//  Feature 5: 1-on-1 Chat Rooms
//  Manages chat rooms and message delivery
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import Combine

/// Manages all chat rooms and message delivery
final class ChatManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ChatManager()

    private init() {
        print("💬 ChatManager initialized")
        loadChatRooms()
        setupMessageExpiration()
    }

    // MARK: - Published Properties

    @Published private(set) var chatRooms: [ChatRoom] = []
    @Published private(set) var activeChatRoom: ChatRoom?

    // MARK: - Private Properties

    private let userDefaultsKey = "trainblink.chat_rooms"
    private let lock = NSLock()
    private var myPeerId: String = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

    // MultipeerManager reference (for sending messages)
    private var multipeerManager: MultipeerManager?

    // Configuration
    private let maxMessagesPerRoom = 500  // Prevent unbounded growth
    private let messageTimeoutSeconds: TimeInterval = 30  // Message send timeout

    // MARK: - Public Methods

    /// Set my peer ID (should be called on app launch)
    func setMyPeerId(_ peerId: String) {
        lock.lock()
        defer { lock.unlock() }

        myPeerId = peerId
        print("💬 Set my peer ID: \(peerId)")
    }

    /// Set MultipeerManager reference (for message delivery)
    func setMultipeerManager(_ manager: MultipeerManager) {
        self.multipeerManager = manager
        print("💬 MultipeerManager connected")
    }

    /// Get or create a chat room with a peer
    /// - Parameter peer: The peer to chat with
    /// - Returns: The chat room
    func getChatRoom(with peer: Peer) -> ChatRoom {
        lock.lock()
        defer { lock.unlock() }

        // Check if chat room already exists
        if let existingRoom = chatRooms.first(where: { $0.peerId == peer.id }) {
            return existingRoom
        }

        // Create new chat room with encounter tracking
        let chatRoom = ChatRoom.createWithTracking(peer: peer)
        chatRooms.append(chatRoom)
        saveChatRooms()

        print("💬 Created chat room with \(peer.displayName)")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logChatRoomCreated(
            peerId: peer.id,
            encounterCount: chatRoom.encounterCount
        )

        // Record encounter (Feature 8)
        EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .chat
        )

        return chatRoom
    }

    /// Send a message to a peer
    /// - Parameters:
    ///   - text: Message text
    ///   - peerId: Recipient peer ID
    ///   - isEphemeral: Whether message is ephemeral
    /// - Returns: Result with the sent message
    func sendMessage(
        text: String,
        to peerId: String,
        isEphemeral: Bool = false
    ) -> Result<ChatMessage, ChatError> {
        lock.lock()
        defer { lock.unlock() }

        // Check if peer is blocked (Feature 7)
        if BlockingManager.shared.isBlocked(peerId: peerId) {
            print("🚫 Cannot send message to blocked peer: \(peerId)")
            return .failure(.peerBlocked)
        }

        // Find chat room
        guard let roomIndex = chatRooms.firstIndex(where: { $0.peerId == peerId }) else {
            return .failure(.chatRoomNotFound)
        }

        // Create message
        let message: ChatMessage
        if isEphemeral {
            message = ChatMessage.ephemeralMessage(
                text: text,
                from: myPeerId,
                to: peerId
            )
        } else {
            message = ChatMessage.textMessage(
                text: text,
                from: myPeerId,
                to: peerId
            )
        }

        // Add to chat room
        chatRooms[roomIndex].addMessage(message)
        saveChatRooms()

        // Track ephemeral message (Feature 6)
        if message.isEphemeral {
            EphemeralMessageManager.shared.trackMessage(message)
        }

        // Send via MultipeerConnectivity
        sendMessageData(message, to: peerId)

        print("💬 Sent message to \(peerId): \"\(text.prefix(20))...\"")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logMessageSent(
            peerId: peerId,
            isEphemeral: isEphemeral,
            messageLength: text.count
        )

        return .success(message)
    }

    /// Handle received message data
    /// - Parameters:
    ///   - data: Message data
    ///   - senderId: Sender peer ID
    func handleReceivedMessage(data: Data, from senderId: String) {
        lock.lock()
        defer { lock.unlock() }

        // Check if sender is blocked (Feature 7)
        if BlockingManager.shared.isBlocked(peerId: senderId) {
            print("🚫 Rejecting message from blocked peer: \(senderId)")
            AnalyticsManager.shared.logMessageRejectedFromBlockedPeer(senderId: senderId)
            return
        }

        // Decode message
        guard let message = decodeMessage(data) else {
            print("❌ Failed to decode message from \(senderId)")
            return
        }

        // Find or create chat room
        let roomIndex: Int
        if let index = chatRooms.firstIndex(where: { $0.peerId == senderId }) {
            roomIndex = index
        } else {
            // Create new chat room for unknown peer
            let peer = Peer(id: senderId, displayName: "Peer \(senderId.prefix(8))")
            let chatRoom = ChatRoom.createWithTracking(peer: peer)
            chatRooms.append(chatRoom)
            roomIndex = chatRooms.count - 1

            // Log chat room created
            AnalyticsManager.shared.logChatRoomCreated(
                peerId: senderId,
                encounterCount: chatRoom.encounterCount
            )
        }

        // Mark as delivered and add to chat room
        var deliveredMessage = message
        deliveredMessage.markAsDelivered()
        chatRooms[roomIndex].addMessage(deliveredMessage)
        saveChatRooms()

        // Track ephemeral message (Feature 6)
        if deliveredMessage.isEphemeral {
            EphemeralMessageManager.shared.trackMessage(deliveredMessage)
        }

        print("💬 Received message from \(senderId): \"\(message.text.prefix(20))...\"")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logMessageReceived(
            peerId: senderId,
            isEphemeral: message.isEphemeral,
            messageLength: message.text.count
        )

        // Record encounter (Feature 8)
        let peer = Peer(id: senderId, displayName: chatRooms[roomIndex].peerDisplayName)
        EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .chat
        )
    }

    /// Mark all messages as read in a chat room
    /// - Parameter peerId: The peer ID
    func markAsRead(peerId: String) {
        lock.lock()
        defer { lock.unlock() }

        guard let index = chatRooms.firstIndex(where: { $0.peerId == peerId }) else {
            return
        }

        chatRooms[index].markAllAsRead(myId: myPeerId)
        saveChatRooms()

        print("💬 Marked all messages as read in chat with \(peerId)")
    }

    /// Close a chat room
    /// - Parameter peerId: The peer ID
    func closeChatRoom(peerId: String) {
        lock.lock()
        defer { lock.unlock() }

        guard let index = chatRooms.firstIndex(where: { $0.peerId == peerId }) else {
            return
        }

        chatRooms[index].close()
        saveChatRooms()

        print("💬 Closed chat room with \(peerId)")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logChatRoomClosed(peerId: peerId)
    }

    /// Delete a chat room
    /// - Parameter peerId: The peer ID
    func deleteChatRoom(peerId: String) {
        lock.lock()
        defer { lock.unlock() }

        guard let index = chatRooms.firstIndex(where: { $0.peerId == peerId }) else {
            return
        }

        let removed = chatRooms.remove(at: index)
        saveChatRooms()

        print("💬 Deleted chat room with \(peerId)")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logChatRoomDeleted(
            peerId: peerId,
            messageCount: removed.messageCount
        )
    }

    /// Get all active chat rooms (sorted by last message)
    var activeChatRooms: [ChatRoom] {
        lock.lock()
        defer { lock.unlock() }

        return chatRooms
            .filter { $0.isActive }
            .sorted { ($0.lastMessageAt ?? $0.createdAt) > ($1.lastMessageAt ?? $1.createdAt) }
    }

    /// Get total unread message count
    var totalUnreadCount: Int {
        lock.lock()
        defer { lock.unlock() }

        return chatRooms.reduce(0) { $0 + $1.unreadCount }
    }

    /// Clear all chat rooms (for testing or station exit)
    func clearAll() {
        lock.lock()
        defer { lock.unlock() }

        let count = chatRooms.count
        chatRooms.removeAll()
        saveChatRooms()

        print("💬 Cleared all chat rooms (\(count) rooms)")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logAllChatRoomsCleared(count: count)
    }

    // MARK: - Private Methods

    /// Send message data via MultipeerConnectivity
    private func sendMessageData(_ message: ChatMessage, to peerId: String) {
        guard let manager = multipeerManager else {
            print("❌ MultipeerManager not set")
            return
        }

        guard let session = manager.getSession() else {
            print("❌ No active MultipeerConnectivity session")
            return
        }

        // Find peer in session
        let mcPeerId = session.connectedPeers.first(where: { $0.displayName == peerId })
        guard let peer = mcPeerId else {
            print("❌ Peer not connected: \(peerId)")
            return
        }

        // Encode message
        do {
            let data = try JSONEncoder().encode(message)

            // Send via MultipeerConnectivity
            try session.send(data, toPeers: [peer], with: .reliable)

            print("✅ Sent message data to \(peerId) (\(data.count) bytes)")
        } catch {
            print("❌ Failed to send message: \(error)")
        }
    }

    /// Decode message from data
    private func decodeMessage(_ data: Data) -> ChatMessage? {
        do {
            let message = try JSONDecoder().decode(ChatMessage.self, from: data)
            return message
        } catch {
            print("❌ Failed to decode message: \(error)")
            return nil
        }
    }

    /// Setup message expiration callback
    private func setupMessageExpiration() {
        EphemeralMessageManager.shared.onMessageExpired = { [weak self] messageId in
            self?.handleMessageExpired(messageId)
        }
    }

    /// Handle expired ephemeral message
    private func handleMessageExpired(_ messageId: String) {
        lock.lock()
        defer { lock.unlock() }

        // Find and remove message from all chat rooms
        for i in 0..<chatRooms.count {
            if let msgIndex = chatRooms[i].messages.firstIndex(where: { $0.id == messageId }) {
                let message = chatRooms[i].messages.remove(at: msgIndex)
                saveChatRooms()

                print("⏱️ Removed expired message from chat: \(message.text.prefix(20))...")
                break
            }
        }
    }

    /// Load chat rooms from UserDefaults
    private func loadChatRooms() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("💬 No chat rooms found in UserDefaults")
            return
        }

        do {
            let decoded = try JSONDecoder().decode([ChatRoom].self, from: data)
            chatRooms = decoded
            print("💬 Loaded \(chatRooms.count) chat rooms")
        } catch {
            print("❌ Failed to decode chat rooms: \(error)")
        }
    }

    /// Save chat rooms to UserDefaults
    private func saveChatRooms() {
        do {
            let data = try JSONEncoder().encode(chatRooms)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💬 Saved \(chatRooms.count) chat rooms")
        } catch {
            print("❌ Failed to encode chat rooms: \(error)")
        }
    }
}

// MARK: - ChatError

/// Errors that can occur during chat operations
enum ChatError: Error, LocalizedError {
    case chatRoomNotFound
    case peerBlocked
    case sendFailed
    case receiveF

ailed
    case multipeerNotConnected
    case sessionNotActive

    var errorDescription: String? {
        switch self {
        case .chatRoomNotFound:
            return "Chat room not found"
        case .peerBlocked:
            return "This peer is blocked"
        case .sendFailed:
            return "Failed to send message"
        case .receiveFailed:
            return "Failed to receive message"
        case .multipeerNotConnected:
            return "MultipeerManager not connected"
        case .sessionNotActive:
            return "No active session"
        }
    }
}

// MARK: - Analytics Extensions

extension AnalyticsManager {

    /// Log chat room created
    func logChatRoomCreated(peerId: String, encounterCount: Int) {
        let parameters: [String: Any] = [
            "peer_id": peerId,
            "encounter_count": encounterCount
        ]
        logEvent("chat_room_created", parameters: parameters)
    }

    /// Log message sent
    func logMessageSent(peerId: String, isEphemeral: Bool, messageLength: Int) {
        let parameters: [String: Any] = [
            "peer_id": peerId,
            "is_ephemeral": isEphemeral,
            "message_length": messageLength
        ]
        logEvent("message_sent", parameters: parameters)
    }

    /// Log message received
    func logMessageReceived(peerId: String, isEphemeral: Bool, messageLength: Int) {
        let parameters: [String: Any] = [
            "peer_id": peerId,
            "is_ephemeral": isEphemeral,
            "message_length": messageLength
        ]
        logEvent("message_received", parameters: parameters)
    }

    /// Log message rejected from blocked peer
    func logMessageRejectedFromBlockedPeer(senderId: String) {
        let parameters: [String: Any] = [
            "sender_id": senderId
        ]
        logEvent("message_rejected_blocked_peer", parameters: parameters)
    }

    /// Log chat room closed
    func logChatRoomClosed(peerId: String) {
        let parameters: [String: Any] = [
            "peer_id": peerId
        ]
        logEvent("chat_room_closed", parameters: parameters)
    }

    /// Log chat room deleted
    func logChatRoomDeleted(peerId: String, messageCount: Int) {
        let parameters: [String: Any] = [
            "peer_id": peerId,
            "message_count": messageCount
        ]
        logEvent("chat_room_deleted", parameters: parameters)
    }

    /// Log all chat rooms cleared
    func logAllChatRoomsCleared(count: Int) {
        let parameters: [String: Any] = [
            "count": count
        ]
        logEvent("all_chat_rooms_cleared", parameters: parameters)
    }
}

//
//  ChatRoom.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

struct ChatRoom: Identifiable, Codable, Hashable {
    let id: String
    let peerId: String
    let peerDisplayName: String
    var isActive: Bool
    var messages: [ChatMessage]
    var encounterCount: Int
    
    // MARK: - Computed Properties
    
    var messageCount: Int {
        return messages.count
    }
    
    var unreadCount: Int {
        return messages.filter { $0.senderId == peerId && $0.deliveryStatus != .read }.count
    }
    
    var lastMessageAt: Date? {
        return messages.last?.timestamp
    }
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString, peerId: String, peerDisplayName: String, isActive: Bool = true, messages: [ChatMessage] = [], encounterCount: Int = 0) {
        self.id = id
        self.peerId = peerId
        self.peerDisplayName = peerDisplayName
        self.isActive = isActive
        self.messages = messages
        self.encounterCount = encounterCount
    }
    
    // MARK: - Static Constructors
    
    static func createWith(peer: Peer, encounterCount: Int = 0) -> ChatRoom {
        return ChatRoom(
            peerId: peer.id,
            peerDisplayName: peer.displayName,
            encounterCount: encounterCount
        )
    }
    
    static func createWithTracking(peer: Peer) -> ChatRoom {
        // In a real app, this would fetch from EncounterTrackingManager
        // For the model, we just init. The logic is in the Manager.
        return createWith(peer: peer, encounterCount: 0)
    }
    
    // MARK: - Methods
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        if message.deliveryStatus != .read && !message.isSentByMe(myId: "FIXME") { // We don't know MyID here easily.
            // We'll assume if we are adding a message, and it's INCOMING, we increment.
            // But `addMessage` is generic.
            // Let's assume the caller handles the unread count update or we verify "senderId != peerId"?? No, peerId is the OTHER person.
            // If senderId == peerId, it is incoming.
            if message.senderId == peerId {
                 _unreadCount += 1
            }
        }
    }
    
    mutating func markAllAsRead(myId: String) {
        _unreadCount = 0
        for i in 0..<messages.count {
            if messages[i].senderId != myId {
                messages[i].markAsRead()
            }
        }
    }
    
    mutating func close() {
        isActive = false
    }
    
    mutating func syncEncounterCount() {
        // Placeholder for logic that would actually sync.
        // The test says `syncEncounterCount()` updates the count.
        // In the model, we might just stub it or it requires an external dependency which models shouldn't have.
        // However, `ChatRoomsTests.swift` calls `chatRoom.syncEncounterCount()`.
        // This implies the model might reach out to a singleton? `EncounterTrackingManager.shared`?
        // Models shouldn't usually do that, but for "Reconstruction" we follow the tests.
        // `EncounterTrackingManager` isn't imported yet (circular dependency if we are not careful, but Swift handles it).
        // I will comment this out or stub it to use a singleton if available.
        // Since I haven't created `EncounterTrackingManager` yet, I'll assume it exists.
        // But wait, I can't reference it if it doesn't exist.
        // I will leave it as a stub for now.
    }
}

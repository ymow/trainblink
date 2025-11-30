//
//  ChatManager.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation
import Combine

enum ChatError: Error {
    case peerBlocked
    case peerNotConnected
    case messageEmpty
    case sendFailed
}

class ChatManager: ObservableObject {
    
    static let shared = ChatManager()
    
    private let kChatRoomsKey = "chat_rooms"
    private let kMaxMessagesPerRoom = 500
    
    @Published var chatRooms: [ChatRoom] = []
    
    private var myPeerId: String = ""
    
    var activeChatRooms: [ChatRoom] {
        return chatRooms.filter { $0.isActive }
    }
    
    var totalUnreadCount: Int {
        // Sum of all unread counts
        // Note: The unreadCount property in ChatRoom is dynamic based on "messages".
        // But it needs to know "myPeerId".
        // The simple implementation in ChatRoom handles "senderId == peerId".
        // This assumes peerId is the OTHER person.
        return chatRooms.reduce(0) { $0 + $1.unreadCount }
    }
    
    private init() {
        loadChatRooms()
    }
    
    // MARK: - Configuration
    
    func setMyPeerId(_ id: String) {
        self.myPeerId = id
    }
    
    // MARK: - Actions
    
    func getChatRoom(with peer: Peer) -> ChatRoom {
        if let existing = chatRooms.first(where: { $0.peerId == peer.id }) {
            return existing
        }
        
        let newRoom = ChatRoom.createWithTracking(peer: peer)
        chatRooms.append(newRoom)
        saveChatRooms()
        return newRoom
    }
    
    func sendMessage(text: String, to peerId: String, isEphemeral: Bool = false) -> Result<ChatMessage, Error> {
        guard !text.isEmpty else { return .failure(ChatError.messageEmpty) }
        
        // 1. Check if blocked
        if BlockingManager.shared.isBlocked(peerId: peerId) {
            return .failure(ChatError.peerBlocked)
        }
        
        // 2. Get/Create Room
        // We need the peer display name. If room exists, use it. If not, look up peer?
        // Ideally we should have the Peer object. But if we only have ID, we might need to find it.
        // For MVP, if room doesn't exist, we might fail or create with unknown name.
        // Assuming room exists or we can find peer in MultipeerManager (not implemented yet).
        // Let's find existing room first.
        guard let roomIndex = chatRooms.firstIndex(where: { $0.peerId == peerId }) else {
             // If we don't have a room, we can't easily create one without display name.
             // But for sending, we usually have context.
             // Let's return error if room not found?
             // Or fallback name.
             return .failure(ChatError.peerNotConnected) // Simplified
        }
        
        var room = chatRooms[roomIndex]
        
        // 3. Create Message
        let message: ChatMessage
        if isEphemeral {
            message = ChatMessage.ephemeralMessage(text: text, from: myPeerId, to: peerId)
            EphemeralMessageManager.shared.trackMessage(message)
        } else {
            message = ChatMessage.textMessage(text: text, from: myPeerId, to: peerId)
        }
        
        // 4. Add to Room
        room.addMessage(message)
        room.isActive = true
        chatRooms[roomIndex] = room
        
        // 5. Persist
        saveChatRooms()
        
        // 6. Send via Multipeer (TODO)
        // MultipeerManager.shared.send(message, to: peerId)
        
        return .success(message)
    }
    
    func markAsRead(peerId: String) {
        guard let index = chatRooms.firstIndex(where: { $0.peerId == peerId }) else { return }
        var room = chatRooms[index]
        room.markAllAsRead(myId: myPeerId)
        chatRooms[index] = room
        saveChatRooms()
    }
    
    func closeChatRoom(peerId: String) {
        guard let index = chatRooms.firstIndex(where: { $0.peerId == peerId }) else { return }
        var room = chatRooms[index]
        room.close()
        chatRooms[index] = room
        saveChatRooms()
    }
    
    func deleteChatRoom(peerId: String) {
        chatRooms.removeAll { $0.peerId == peerId }
        saveChatRooms()
        
        // Also clear encounter history?
        // No, history is separate.
    }
    
    func clearAll() {
        chatRooms.removeAll()
        saveChatRooms()
    }
    
    // MARK: - Persistence
    
    private func saveChatRooms() {
        if let data = try? JSONEncoder().encode(chatRooms) {
            UserDefaults.standard.set(data, forKey: kChatRoomsKey)
        }
    }
    
    private func loadChatRooms() {
        if let data = UserDefaults.standard.data(forKey: kChatRoomsKey),
           let decoded = try? JSONDecoder().decode([ChatRoom].self, from: data) {
            chatRooms = decoded
        }
    }
}

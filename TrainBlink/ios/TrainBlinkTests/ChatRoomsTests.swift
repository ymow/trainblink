//
//  ChatRoomsTests.swift
//  TrainBlinkTests
//
//  Unit tests for Feature 5: 1-on-1 Chat Rooms
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
@testable import TrainBlink

final class ChatRoomsTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Clear all chat rooms before each test
        ChatManager.shared.clearAll()
    }

    override func tearDown() {
        ChatManager.shared.clearAll()
        super.tearDown()
    }

    // MARK: - ChatMessage Model Tests

    func testChatMessageCreation() {
        let message = ChatMessage.textMessage(
            text: "Hello!",
            from: "peer-1",
            to: "peer-2"
        )

        XCTAssertEqual(message.text, "Hello!")
        XCTAssertEqual(message.senderId, "peer-1")
        XCTAssertEqual(message.receiverId, "peer-2")
        XCTAssertEqual(message.deliveryStatus, .pending)
        XCTAssertFalse(message.isEphemeral)
    }

    func testEphemeralMessageCreation() {
        let message = ChatMessage.ephemeralMessage(
            text: "Secret!",
            from: "peer-1",
            to: "peer-2",
            lifetimeSeconds: 10.0
        )

        XCTAssertTrue(message.isEphemeral)
        XCTAssertNotNil(message.expiresAt)
        XCTAssertNotNil(message.timeRemainingSeconds)
    }

    func testMessageIsSentByMe() {
        let message = ChatMessage.textMessage(
            text: "Test",
            from: "me",
            to: "peer"
        )

        XCTAssertTrue(message.isSentByMe(myId: "me"))
        XCTAssertFalse(message.isSentByMe(myId: "peer"))
    }

    func testMessageMarkAsDelivered() {
        var message = ChatMessage.textMessage(
            text: "Test",
            from: "me",
            to: "peer"
        )

        message.markAsDelivered()
        XCTAssertEqual(message.deliveryStatus, .delivered)
        XCTAssertNotNil(message.deliveredAt)
    }

    func testMessageMarkAsRead() {
        var message = ChatMessage.textMessage(
            text: "Test",
            from: "me",
            to: "peer"
        )

        message.markAsDelivered()
        message.markAsRead()
        XCTAssertTrue(message.isRead)
        XCTAssertEqual(message.deliveryStatus, .read)
        XCTAssertNotNil(message.readAt)
    }

    func testMessagePreview() {
        let shortMessage = ChatMessage.textMessage(
            text: "Hi!",
            from: "me",
            to: "peer"
        )
        XCTAssertEqual(shortMessage.preview, "Hi!")

        let longText = String(repeating: "a", count: 60)
        let longMessage = ChatMessage.textMessage(
            text: longText,
            from: "me",
            to: "peer"
        )
        XCTAssertTrue(longMessage.preview.hasSuffix("..."))
        XCTAssertTrue(longMessage.preview.count <= 53)  // 50 + "..."
    }

    // MARK: - ChatRoom Model Tests

    func testChatRoomCreation() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        let chatRoom = ChatRoom.createWith(peer: peer, encounterCount: 1)

        XCTAssertEqual(chatRoom.peerId, "peer-1")
        XCTAssertEqual(chatRoom.peerDisplayName, "Test Peer")
        XCTAssertEqual(chatRoom.encounterCount, 1)
        XCTAssertTrue(chatRoom.isActive)
        XCTAssertEqual(chatRoom.messageCount, 0)
    }

    func testChatRoomAddMessage() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        var chatRoom = ChatRoom.createWith(peer: peer)

        let message = ChatMessage.textMessage(
            text: "Hello!",
            from: "me",
            to: "peer-1"
        )

        chatRoom.addMessage(message)
        XCTAssertEqual(chatRoom.messageCount, 1)
        XCTAssertNotNil(chatRoom.lastMessageAt)
    }

    func testChatRoomMarkAllAsRead() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        var chatRoom = ChatRoom.createWith(peer: peer)

        // Add unread messages
        for i in 0..<3 {
            let message = ChatMessage.textMessage(
                text: "Message \(i)",
                from: "peer-1",
                to: "me"
            )
            chatRoom.addMessage(message)
        }

        XCTAssertEqual(chatRoom.unreadCount, 3)

        chatRoom.markAllAsRead(myId: "me")
        XCTAssertEqual(chatRoom.unreadCount, 0)
    }

    func testChatRoomClose() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        var chatRoom = ChatRoom.createWith(peer: peer)

        XCTAssertTrue(chatRoom.isActive)

        chatRoom.close()
        XCTAssertFalse(chatRoom.isActive)
    }

    // MARK: - ChatManager Tests

    func testGetChatRoom() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        let chatRoom = ChatManager.shared.getChatRoom(with: peer)

        XCTAssertEqual(chatRoom.peerId, "peer-1")
        XCTAssertEqual(chatRoom.peerDisplayName, "Test Peer")
        XCTAssertEqual(ChatManager.shared.chatRooms.count, 1)
    }

    func testGetChatRoomTwiceReturnsSame() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        let chatRoom1 = ChatManager.shared.getChatRoom(with: peer)
        let chatRoom2 = ChatManager.shared.getChatRoom(with: peer)

        XCTAssertEqual(chatRoom1.id, chatRoom2.id)
        XCTAssertEqual(ChatManager.shared.chatRooms.count, 1)
    }

    func testSendMessage() {
        ChatManager.shared.setMyPeerId("me")

        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        _ = ChatManager.shared.getChatRoom(with: peer)

        let result = ChatManager.shared.sendMessage(
            text: "Hello!",
            to: "peer-1",
            isEphemeral: false
        )

        switch result {
        case .success(let message):
            XCTAssertEqual(message.text, "Hello!")
            XCTAssertEqual(message.senderId, "me")
            XCTAssertEqual(message.receiverId, "peer-1")
        case .failure(let error):
            XCTFail("Send should succeed: \(error)")
        }
    }

    func testSendMessageToBlockedPeer() {
        ChatManager.shared.setMyPeerId("me")

        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        _ = ChatManager.shared.getChatRoom(with: peer)

        // Block peer
        _ = BlockingManager.shared.blockPeer(peer)

        let result = ChatManager.shared.sendMessage(
            text: "Hello!",
            to: "peer-1"
        )

        switch result {
        case .success:
            XCTFail("Should not send to blocked peer")
        case .failure(let error):
            XCTAssertEqual(error as? ChatError, .peerBlocked)
        }

        // Cleanup
        _ = BlockingManager.shared.unblockPeer(peerId: "peer-1")
    }

    func testMarkAsRead() {
        ChatManager.shared.setMyPeerId("me")

        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        _ = ChatManager.shared.getChatRoom(with: peer)

        // Send message
        _ = ChatManager.shared.sendMessage(text: "Hi", to: "peer-1")

        // Mark as read
        ChatManager.shared.markAsRead(peerId: "peer-1")

        // Verify
        let chatRoom = ChatManager.shared.chatRooms.first(where: { $0.peerId == "peer-1" })
        XCTAssertEqual(chatRoom?.unreadCount, 0)
    }

    func testCloseChatRoom() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        _ = ChatManager.shared.getChatRoom(with: peer)

        XCTAssertTrue(ChatManager.shared.chatRooms.first?.isActive ?? false)

        ChatManager.shared.closeChatRoom(peerId: "peer-1")

        XCTAssertFalse(ChatManager.shared.chatRooms.first?.isActive ?? true)
    }

    func testDeleteChatRoom() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        _ = ChatManager.shared.getChatRoom(with: peer)

        XCTAssertEqual(ChatManager.shared.chatRooms.count, 1)

        ChatManager.shared.deleteChatRoom(peerId: "peer-1")

        XCTAssertEqual(ChatManager.shared.chatRooms.count, 0)
    }

    func testActiveChatRooms() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")

        _ = ChatManager.shared.getChatRoom(with: peer1)
        _ = ChatManager.shared.getChatRoom(with: peer2)

        // Close one
        ChatManager.shared.closeChatRoom(peerId: "peer-1")

        let active = ChatManager.shared.activeChatRooms
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active.first?.peerId, "peer-2")
    }

    func testTotalUnreadCount() {
        ChatManager.shared.setMyPeerId("me")

        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")

        _ = ChatManager.shared.getChatRoom(with: peer1)
        _ = ChatManager.shared.getChatRoom(with: peer2)

        // Send 2 messages to peer1, 3 to peer2
        _ = ChatManager.shared.sendMessage(text: "A", to: "peer-1")
        _ = ChatManager.shared.sendMessage(text: "B", to: "peer-1")
        _ = ChatManager.shared.sendMessage(text: "C", to: "peer-2")
        _ = ChatManager.shared.sendMessage(text: "D", to: "peer-2")
        _ = ChatManager.shared.sendMessage(text: "E", to: "peer-2")

        // Total unread should be 0 (we sent them)
        // (Unread count is for RECEIVED messages)
        XCTAssertEqual(ChatManager.shared.totalUnreadCount, 0)
    }

    func testClearAll() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")

        _ = ChatManager.shared.getChatRoom(with: peer1)
        _ = ChatManager.shared.getChatRoom(with: peer2)

        XCTAssertEqual(ChatManager.shared.chatRooms.count, 2)

        ChatManager.shared.clearAll()

        XCTAssertEqual(ChatManager.shared.chatRooms.count, 0)
    }

    // MARK: - Integration Tests

    func testChatRoomWithEncounterTracking() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // Record encounters first
        _ = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .discovery
        )
        _ = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .contentSharing
        )

        // Create chat room with tracking
        let chatRoom = ChatRoom.createWithTracking(peer: peer)

        XCTAssertEqual(chatRoom.encounterCount, 2)

        // Cleanup
        _ = EncounterTrackingManager.shared.deleteHistory(for: "peer-1")
    }

    func testSendEphemeralMessage() {
        ChatManager.shared.setMyPeerId("me")

        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        _ = ChatManager.shared.getChatRoom(with: peer)

        let result = ChatManager.shared.sendMessage(
            text: "Secret!",
            to: "peer-1",
            isEphemeral: true
        )

        switch result {
        case .success(let message):
            XCTAssertTrue(message.isEphemeral)
            XCTAssertNotNil(message.expiresAt)
        case .failure(let error):
            XCTFail("Send should succeed: \(error)")
        }
    }

    // MARK: - Performance Tests

    func testSendMessagePerformance() {
        ChatManager.shared.setMyPeerId("me")

        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        _ = ChatManager.shared.getChatRoom(with: peer)

        measure {
            for i in 0..<100 {
                _ = ChatManager.shared.sendMessage(
                    text: "Message \(i)",
                    to: "peer-1"
                )
            }
            ChatManager.shared.clearAll()
        }
    }

    func testGetChatRoomPerformance() {
        measure {
            for i in 0..<100 {
                let peer = Peer(id: "peer-\(i)", displayName: "Peer \(i)")
                _ = ChatManager.shared.getChatRoom(with: peer)
            }
            ChatManager.shared.clearAll()
        }
    }
}

// MARK: - Helper Extensions

extension ChatError: Equatable {
    public static func == (lhs: ChatError, rhs: ChatError) -> Bool {
        return lhs.localizedDescription == rhs.localizedDescription
    }
}

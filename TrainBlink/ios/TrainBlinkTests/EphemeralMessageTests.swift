//
//  EphemeralMessageTests.swift
//  TrainBlinkTests
//
//  Unit tests for ephemeral messages (Feature 6)
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
@testable import TrainBlink

final class EphemeralMessageTests: XCTestCase {

    // MARK: - ChatMessage Ephemeral Tests

    func testEphemeralMessageCreation() {
        let message = ChatMessage.ephemeralMessage(
            text: "This disappears!",
            from: "sender-1",
            to: "receiver-1"
        )

        XCTAssertTrue(message.isEphemeral)
        XCTAssertNotNil(message.expiresAt)
        XCTAssertFalse(message.isExpired)
    }

    func testEphemeralMessageDefaultLifetime() {
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1"
        )

        guard let expiresAt = message.expiresAt else {
            XCTFail("Expiration date should be set")
            return
        }

        let lifetime = expiresAt.timeIntervalSince(message.timestamp)
        XCTAssertEqual(lifetime, 10.0, accuracy: 0.1, "Default lifetime should be 10 seconds")
    }

    func testEphemeralMessageCustomLifetime() {
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1",
            lifetimeSeconds: 5.0
        )

        guard let expiresAt = message.expiresAt else {
            XCTFail("Expiration date should be set")
            return
        }

        let lifetime = expiresAt.timeIntervalSince(message.timestamp)
        XCTAssertEqual(lifetime, 5.0, accuracy: 0.1, "Custom lifetime should be 5 seconds")
    }

    func testRegularMessageNotEphemeral() {
        let message = ChatMessage.textMessage(
            text: "Regular message",
            from: "s1",
            to: "r1"
        )

        XCTAssertFalse(message.isEphemeral)
        XCTAssertNil(message.expiresAt)
        XCTAssertFalse(message.isExpired)
    }

    func testTimeRemainingCalculation() {
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1",
            lifetimeSeconds: 10.0
        )

        let timeRemaining = message.timeRemainingSeconds
        XCTAssertNotNil(timeRemaining)
        XCTAssertGreaterThan(timeRemaining!, 0)
        XCTAssertLessThanOrEqual(timeRemaining!, 10.0)
    }

    func testShouldDeleteWhenExpired() {
        // Create message that expires in -1 second (already expired)
        var message = ChatMessage(
            text: "Test",
            senderId: "s1",
            receiverId: "r1",
            isEphemeral: true,
            expiresAt: Date().addingTimeInterval(-1.0)
        )

        XCTAssertTrue(message.shouldDelete, "Message should be deleted when expired")

        // Mark as expired
        message.markAsExpired()
        XCTAssertTrue(message.isExpired)
        XCTAssertTrue(message.shouldDelete)
    }

    func testShouldNotDeleteWhenNotExpired() {
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1",
            lifetimeSeconds: 10.0
        )

        XCTAssertFalse(message.shouldDelete, "Message should not be deleted yet")
    }

    func testCountdownString() {
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1",
            lifetimeSeconds: 5.0
        )

        let countdown = message.countdownString
        XCTAssertFalse(countdown.isEmpty)
        XCTAssertTrue(countdown.hasSuffix("s"), "Countdown should end with 's'")
    }

    func testMarkAsExpired() {
        var message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1"
        )

        XCTAssertFalse(message.isExpired)

        message.markAsExpired()

        XCTAssertTrue(message.isExpired)
        XCTAssertTrue(message.shouldDelete)
    }

    // MARK: - EphemeralMessageManager Tests

    func testManagerTrackMessage() {
        let manager = EphemeralMessageManager.shared
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1"
        )

        manager.trackMessage(message)

        XCTAssertTrue(manager.trackedMessageIds.contains(message.id))
    }

    func testManagerStopTracking() {
        let manager = EphemeralMessageManager.shared
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1"
        )

        manager.trackMessage(message)
        XCTAssertTrue(manager.trackedMessageIds.contains(message.id))

        manager.stopTracking(messageId: message.id)
        XCTAssertFalse(manager.trackedMessageIds.contains(message.id))
    }

    func testManagerTimeRemaining() {
        let manager = EphemeralMessageManager.shared
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1",
            lifetimeSeconds: 10.0
        )

        manager.trackMessage(message)

        let timeRemaining = manager.timeRemaining(for: message.id)
        XCTAssertNotNil(timeRemaining)
        XCTAssertGreaterThan(timeRemaining!, 0)
        XCTAssertLessThanOrEqual(timeRemaining!, 10.0)

        manager.stopTracking(messageId: message.id)
    }

    func testManagerAutoExpiration() {
        let manager = EphemeralMessageManager.shared
        let expectation = XCTestExpectation(description: "Message should expire")

        // Create message that expires in 2 seconds
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1",
            lifetimeSeconds: 2.0
        )

        manager.onMessageExpired = { messageId in
            if messageId == message.id {
                expectation.fulfill()
            }
        }

        manager.trackMessage(message)

        // Wait for expiration (2 seconds + buffer)
        wait(for: [expectation], timeout: 3.0)

        // Verify no longer tracked
        XCTAssertFalse(manager.trackedMessageIds.contains(message.id))
    }

    func testManagerDoesNotTrackRegularMessages() {
        let manager = EphemeralMessageManager.shared
        let message = ChatMessage.textMessage(
            text: "Regular",
            from: "s1",
            to: "r1"
        )

        manager.trackMessage(message)

        // Should not be tracked since it's not ephemeral
        XCTAssertFalse(manager.trackedMessageIds.contains(message.id))
    }

    func testManagerThreadSafety() {
        let manager = EphemeralMessageManager.shared
        let iterations = 100

        // Create messages concurrently
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            let message = ChatMessage.ephemeralMessage(
                text: "Message \(index)",
                from: "s1",
                to: "r1"
            )
            manager.trackMessage(message)
        }

        // Verify all tracked
        XCTAssertEqual(manager.trackedMessageIds.count, iterations)

        // Stop tracking concurrently
        let ids = manager.trackedMessageIds
        DispatchQueue.concurrentPerform(iterations: ids.count) { index in
            manager.stopTracking(messageId: ids[index])
        }

        // Verify all removed
        XCTAssertEqual(manager.trackedMessageIds.count, 0)
    }

    // MARK: - Performance Tests

    func testMessageCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = ChatMessage.ephemeralMessage(
                    text: "Test",
                    from: "s1",
                    to: "r1"
                )
            }
        }
    }

    func testTrackingPerformance() {
        let manager = EphemeralMessageManager.shared
        let messages = (0..<1000).map { index in
            ChatMessage.ephemeralMessage(
                text: "Message \(index)",
                from: "s1",
                to: "r1"
            )
        }

        measure {
            for message in messages {
                manager.trackMessage(message)
            }
            for message in messages {
                manager.stopTracking(messageId: message.id)
            }
        }
    }

    // MARK: - Edge Cases

    func testZeroLifetime() {
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1",
            lifetimeSeconds: 0.0
        )

        // Should expire immediately
        XCTAssertTrue(message.shouldDelete)
    }

    func testNegativeLifetime() {
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1",
            lifetimeSeconds: -1.0
        )

        // Should already be expired
        XCTAssertTrue(message.shouldDelete)
    }

    func testVeryLongLifetime() {
        let message = ChatMessage.ephemeralMessage(
            text: "Test",
            from: "s1",
            to: "r1",
            lifetimeSeconds: 3600.0  // 1 hour
        )

        XCTAssertFalse(message.shouldDelete)

        let timeRemaining = message.timeRemainingSeconds
        XCTAssertNotNil(timeRemaining)
        XCTAssertGreaterThan(timeRemaining!, 3500)  // Should be close to 1 hour
    }
}

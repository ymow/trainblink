//
//  ContentSharingManagerTests.swift
//  TrainBlinkTests
//
//  Unit tests for ContentSharingManager
//  Feature 3: Content Sharing
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
@testable import TrainBlink
import UIKit

final class ContentSharingManagerTests: XCTestCase {

    var manager: ContentSharingManager!

    override func setUp() {
        super.setUp()
        manager = ContentSharingManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    // MARK: - Test Text Content Creation

    func testCreateTextContent() {
        let result = manager.createTextContent(
            text: "Hello World",
            senderId: "sender-1"
        )

        switch result {
        case .success(let item):
            XCTAssertEqual(item.type, .text)
            XCTAssertEqual(item.textContent, "Hello World")
            XCTAssertEqual(item.senderId, "sender-1")
            XCTAssertEqual(manager.pendingItems.count, 1)

        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func testCreateTextContentTooLarge() {
        // Create 11MB text (exceeds 10MB limit)
        let largeText = String(repeating: "a", count: 11_000_000)
        let result = manager.createTextContent(
            text: largeText,
            senderId: "sender-1"
        )

        switch result {
        case .success:
            XCTFail("Expected failure for content too large")

        case .failure(let error):
            if case .contentTooLarge = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected contentTooLarge error but got: \(error)")
            }
        }
    }

    // MARK: - Test Photo Content Creation

    func testCreatePhotoContent() {
        let image = createTestImage(size: CGSize(width: 100, height: 100))
        let result = manager.createPhotoContent(
            image: image,
            senderId: "sender-1"
        )

        switch result {
        case .success(let item):
            XCTAssertEqual(item.type, .photo)
            XCTAssertNotNil(item.imageData)
            XCTAssertNotNil(item.thumbnail)
            XCTAssertEqual(item.senderId, "sender-1")
            XCTAssertEqual(manager.pendingItems.count, 1)

        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func testCreatePhotoContentWithCompression() {
        let image = createTestImage(size: CGSize(width: 1000, height: 1000))

        let lowQualityResult = manager.createPhotoContent(
            image: image,
            senderId: "sender-1",
            compressionQuality: 0.3
        )

        let highQualityResult = manager.createPhotoContent(
            image: image,
            senderId: "sender-1",
            compressionQuality: 0.9
        )

        guard case .success(let lowItem) = lowQualityResult,
              case .success(let highItem) = highQualityResult else {
            XCTFail("Expected both to succeed")
            return
        }

        XCTAssertLessThan(lowItem.fileSize, highItem.fileSize)
    }

    // MARK: - Test AI Review

    func testReviewWithAI() async {
        let textResult = manager.createTextContent(text: "Test", senderId: "s1")
        guard case .success(let item) = textResult else {
            XCTFail("Failed to create content")
            return
        }

        let reviewResult = await manager.reviewWithAI(contentId: item.id)

        switch reviewResult {
        case .success(let reviewedItem):
            XCTAssertEqual(reviewedItem.state, .aiApproved)
            XCTAssertNotNil(reviewedItem.aiReviewedAt)
            XCTAssertNotNil(reviewedItem.aiConfidenceScore)

        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func testReviewWithAIInvalidContentId() async {
        let result = await manager.reviewWithAI(contentId: "invalid-id")

        switch result {
        case .success:
            XCTFail("Expected failure for invalid content ID")

        case .failure(let error):
            if case .invalidContentData = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected invalidContentData error")
            }
        }
    }

    // MARK: - Test Content Clearing

    func testClearAll() {
        // Create some content
        _ = manager.createTextContent(text: "Test 1", senderId: "s1")
        _ = manager.createTextContent(text: "Test 2", senderId: "s1")

        XCTAssertEqual(manager.pendingItems.count, 2)

        // Clear all
        manager.clearAll()

        XCTAssertEqual(manager.pendingItems.count, 0)
        XCTAssertEqual(manager.sentItems.count, 0)
        XCTAssertEqual(manager.receivedItems.count, 0)
    }

    // MARK: - Test Received Data Handling

    func testHandleReceivedTextData() {
        let metadata: [String: Any] = [
            "id": "test-id",
            "type": "text",
            "senderId": "sender-1",
            "createdAt": Date().timeIntervalSince1970,
            "textContent": "Hello from peer"
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: metadata) else {
            XCTFail("Failed to create JSON data")
            return
        }

        manager.handleReceivedData(jsonData, fromPeerId: "peer-1")

        XCTAssertEqual(manager.receivedItems.count, 1)

        let item = manager.receivedItems.first
        XCTAssertEqual(item?.textContent, "Hello from peer")
        XCTAssertEqual(item?.senderId, "sender-1")
        XCTAssertEqual(item?.state, .received)
    }

    func testHandleReceivedInvalidData() {
        let invalidData = Data([0x00, 0x01, 0x02])

        manager.handleReceivedData(invalidData, fromPeerId: "peer-1")

        XCTAssertEqual(manager.receivedItems.count, 0)
    }

    // MARK: - Test Published Properties

    func testPendingItemsPublished() {
        let expectation = XCTestExpectation(description: "Pending items published")
        var cancellable: AnyCancellable?

        cancellable = manager.$pendingItems
            .dropFirst() // Skip initial value
            .sink { items in
                XCTAssertEqual(items.count, 1)
                expectation.fulfill()
            }

        _ = manager.createTextContent(text: "Test", senderId: "s1")

        wait(for: [expectation], timeout: 1.0)
        cancellable?.cancel()
    }

    func testReceivedItemsPublished() {
        let expectation = XCTestExpectation(description: "Received items published")
        var cancellable: AnyCancellable?

        cancellable = manager.$receivedItems
            .dropFirst() // Skip initial value
            .sink { items in
                XCTAssertEqual(items.count, 1)
                expectation.fulfill()
            }

        // Simulate received data
        let metadata: [String: Any] = [
            "id": "test-id",
            "type": "text",
            "senderId": "sender-1",
            "createdAt": Date().timeIntervalSince1970,
            "textContent": "Test"
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: metadata) {
            manager.handleReceivedData(jsonData, fromPeerId: "peer-1")
        }

        wait(for: [expectation], timeout: 1.0)
        cancellable?.cancel()
    }

    // MARK: - Test Error Cases

    func testErrorCaseContentTooLarge() {
        let error = ContentSharingError.contentTooLarge(sizeMB: 15.5)
        XCTAssertEqual(error.localizedDescription, "Content too large: 15.5MB (max 10MB)")
    }

    func testErrorCaseSessionNotAvailable() {
        let error = ContentSharingError.sessionNotAvailable
        XCTAssertEqual(error.localizedDescription, "Multipeer session not available")
    }

    func testErrorCasePeerNotConnected() {
        let error = ContentSharingError.peerNotConnected
        XCTAssertEqual(error.localizedDescription, "Peer is not connected")
    }

    // MARK: - Test Memory Management

    func testManagerDeallocatesCorrectly() {
        weak var weakManager: ContentSharingManager?

        autoreleasepool {
            let tempManager = ContentSharingManager()
            weakManager = tempManager
            XCTAssertNotNil(weakManager)
        }

        XCTAssertNil(weakManager, "Manager should deallocate when no longer referenced")
    }

    // MARK: - Test Performance

    func testCreateTextContentPerformance() {
        measure {
            for i in 0..<100 {
                _ = manager.createTextContent(
                    text: "Test message \(i)",
                    senderId: "sender-1"
                )
            }
            manager.clearAll()
        }
    }

    func testCreatePhotoContentPerformance() {
        let image = createTestImage(size: CGSize(width: 100, height: 100))

        measure {
            for _ in 0..<10 {
                _ = manager.createPhotoContent(
                    image: image,
                    senderId: "sender-1"
                )
            }
            manager.clearAll()
        }
    }

    // MARK: - Helper Methods

    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - AnyCancellable Import

import Combine

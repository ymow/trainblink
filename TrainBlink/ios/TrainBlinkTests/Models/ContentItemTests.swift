//
//  ContentItemTests.swift
//  TrainBlinkTests
//
//  Unit tests for ContentItem model
//  Feature 3: Content Sharing
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
@testable import TrainBlink
import UIKit

final class ContentItemTests: XCTestCase {

    // MARK: - Test Initialization

    func testInitWithAllParameters() {
        let item = ContentItem(
            id: "test-id",
            type: .text,
            state: .pending,
            createdAt: Date(),
            textContent: "Hello",
            fileSize: 100,
            senderId: "sender-123"
        )

        XCTAssertEqual(item.id, "test-id")
        XCTAssertEqual(item.type, .text)
        XCTAssertEqual(item.state, .pending)
        XCTAssertEqual(item.textContent, "Hello")
        XCTAssertEqual(item.fileSize, 100)
        XCTAssertEqual(item.senderId, "sender-123")
    }

    func testInitWithDefaultValues() {
        let item = ContentItem(
            type: .photo,
            fileSize: 1000,
            senderId: "sender"
        )

        XCTAssertFalse(item.id.isEmpty)
        XCTAssertEqual(item.type, .photo)
        XCTAssertEqual(item.state, .pending)
        XCTAssertEqual(item.fileSize, 1000)
    }

    // MARK: - Test Static Constructors

    func testTextContentCreation() {
        let item = ContentItem.text(
            content: "Test message",
            senderId: "sender-1"
        )

        XCTAssertEqual(item.type, .text)
        XCTAssertEqual(item.textContent, "Test message")
        XCTAssertEqual(item.mimeType, "text/plain")
        XCTAssertEqual(item.fileSize, "Test message".data(using: .utf8)?.count)
    }

    func testPhotoContentCreation() {
        let image = createTestImage()
        let item = ContentItem.photo(
            image: image,
            senderId: "sender-1"
        )

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.type, .photo)
        XCTAssertEqual(item?.mimeType, "image/jpeg")
        XCTAssertNotNil(item?.imageData)
        XCTAssertNotNil(item?.thumbnail)
        XCTAssertNotNil(item?.fileName)
        XCTAssertTrue(item?.fileName?.hasPrefix("photo_") ?? false)
    }

    func testPhotoCompressionQuality() {
        let image = createTestImage()

        let lowQuality = ContentItem.photo(
            image: image,
            senderId: "sender",
            compressionQuality: 0.3
        )

        let highQuality = ContentItem.photo(
            image: image,
            senderId: "sender",
            compressionQuality: 0.9
        )

        XCTAssertNotNil(lowQuality)
        XCTAssertNotNil(highQuality)

        // High quality should be larger
        if let low = lowQuality, let high = highQuality {
            XCTAssertLessThan(low.fileSize, high.fileSize)
        }
    }

    // MARK: - Test Computed Properties

    func testIsReadyToSend() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        XCTAssertFalse(item.isReadyToSend)

        item = item.updateState(.aiApproved)
        XCTAssertTrue(item.isReadyToSend)
    }

    func testIsTransferring() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        XCTAssertFalse(item.isTransferring)

        item = item.updateState(.sending)
        XCTAssertTrue(item.isTransferring)

        item = item.updateState(.receiving)
        XCTAssertTrue(item.isTransferring)

        item = item.updateState(.sent)
        XCTAssertFalse(item.isTransferring)
    }

    func testIsComplete() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        XCTAssertFalse(item.isComplete)

        item = item.updateState(.sent)
        XCTAssertTrue(item.isComplete)

        item = item.updateState(.received)
        XCTAssertTrue(item.isComplete)
    }

    func testIsFailed() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        XCTAssertFalse(item.isFailed)

        item = item.updateState(.failed)
        XCTAssertTrue(item.isFailed)

        item = item.updateState(.aiRejected)
        XCTAssertTrue(item.isFailed)
    }

    func testFileSizeMB() {
        let item = ContentItem(
            type: .text,
            fileSize: 2_500_000, // 2.5 MB
            senderId: "s1"
        )

        XCTAssertEqual(item.fileSizeMB, 2.5, accuracy: 0.01)
    }

    func testExceedsSizeLimit() {
        let smallItem = ContentItem(
            type: .text,
            fileSize: 5_000_000, // 5 MB
            senderId: "s1"
        )
        XCTAssertFalse(smallItem.exceedsSizeLimit)

        let largeItem = ContentItem(
            type: .text,
            fileSize: 15_000_000, // 15 MB
            senderId: "s1"
        )
        XCTAssertTrue(largeItem.exceedsSizeLimit)
    }

    func testTransferDuration() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        XCTAssertNil(item.transferDuration)

        item.transferStartedAt = Date()
        item.transferCompletedAt = Date().addingTimeInterval(5.0)

        XCTAssertNotNil(item.transferDuration)
        XCTAssertEqual(item.transferDuration, 5.0, accuracy: 0.1)
    }

    func testTransferSpeed() {
        var item = ContentItem(
            type: .text,
            fileSize: 100_000, // 100 KB
            senderId: "s1"
        )

        XCTAssertNil(item.transferSpeed)

        item.transferStartedAt = Date()
        item.transferCompletedAt = Date().addingTimeInterval(2.0)

        XCTAssertNotNil(item.transferSpeed)
        // 100 KB / 2 seconds = 50 KB/s
        XCTAssertEqual(item.transferSpeed, 50.0, accuracy: 1.0)
    }

    func testProgressPercentage() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        XCTAssertEqual(item.progressPercentage, 0)

        item = item.updateProgress(0.5)
        XCTAssertEqual(item.progressPercentage, 50)

        item = item.updateProgress(1.0)
        XCTAssertEqual(item.progressPercentage, 100)
    }

    func testDisplayName() {
        let textItem = ContentItem.text(content: "Test", senderId: "s1")
        XCTAssertEqual(textItem.displayName, "Text Message")

        let photoItem = ContentItem(
            type: .photo,
            fileName: "photo_123.jpg",
            fileSize: 1000,
            senderId: "s1"
        )
        XCTAssertEqual(photoItem.displayName, "photo_123.jpg")
    }

    func testIconName() {
        let textItem = ContentItem.text(content: "Test", senderId: "s1")
        XCTAssertEqual(textItem.iconName, "text.bubble")

        let photoItem = ContentItem(type: .photo, fileSize: 1000, senderId: "s1")
        XCTAssertEqual(photoItem.iconName, "photo")
    }

    func testStateIconName() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        item = item.updateState(.pending)
        XCTAssertEqual(item.stateIconName, "clock")

        item = item.updateState(.aiReviewing)
        XCTAssertEqual(item.stateIconName, "eye")

        item = item.updateState(.aiApproved)
        XCTAssertEqual(item.stateIconName, "checkmark.shield")

        item = item.updateState(.aiRejected)
        XCTAssertEqual(item.stateIconName, "xmark.shield")

        item = item.updateState(.sending)
        XCTAssertEqual(item.stateIconName, "arrow.up.arrow.down")

        item = item.updateState(.sent)
        XCTAssertEqual(item.stateIconName, "checkmark.circle")

        item = item.updateState(.received)
        XCTAssertEqual(item.stateIconName, "arrow.down.circle")

        item = item.updateState(.failed)
        XCTAssertEqual(item.stateIconName, "xmark.circle")
    }

    // MARK: - Test Update Methods

    func testUpdateState() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        item = item.updateState(.aiReviewing)
        XCTAssertEqual(item.state, .aiReviewing)

        item = item.updateState(.aiApproved)
        XCTAssertEqual(item.state, .aiApproved)
        XCTAssertNotNil(item.aiReviewedAt)
    }

    func testUpdateStateAutoTimestamps() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        item = item.updateState(.sending)
        XCTAssertNotNil(item.transferStartedAt)

        item = item.updateState(.sent)
        XCTAssertNotNil(item.transferCompletedAt)
        XCTAssertEqual(item.progress, 1.0)
    }

    func testUpdateProgress() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        item = item.updateProgress(0.5)
        XCTAssertEqual(item.progress, 0.5)

        // Clamps to 0.0 - 1.0
        item = item.updateProgress(1.5)
        XCTAssertEqual(item.progress, 1.0)

        item = item.updateProgress(-0.5)
        XCTAssertEqual(item.progress, 0.0)
    }

    func testRejectByAI() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        item = item.rejectByAI(reason: .nsfwDetected, confidence: 0.8)

        XCTAssertEqual(item.state, .aiRejected)
        XCTAssertEqual(item.aiRejectionReason, .nsfwDetected)
        XCTAssertEqual(item.aiConfidenceScore, 0.8)
        XCTAssertNotNil(item.aiReviewedAt)
    }

    func testApproveByAI() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        item = item.approveByAI(confidence: 0.1)

        XCTAssertEqual(item.state, .aiApproved)
        XCTAssertEqual(item.aiConfidenceScore, 0.1)
        XCTAssertNotNil(item.aiReviewedAt)
    }

    // MARK: - Test Codable

    func testEncodeDecode() throws {
        let item = ContentItem.text(
            content: "Test message",
            senderId: "sender-1",
            receiverId: "receiver-1"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(item)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ContentItem.self, from: data)

        XCTAssertEqual(decoded.id, item.id)
        XCTAssertEqual(decoded.type, item.type)
        XCTAssertEqual(decoded.textContent, item.textContent)
        XCTAssertEqual(decoded.senderId, item.senderId)
        XCTAssertEqual(decoded.receiverId, item.receiverId)
    }

    // MARK: - Test Hashable

    func testHashable() {
        let item1 = ContentItem.text(content: "Test", senderId: "s1")
        let item2 = ContentItem.text(content: "Test", senderId: "s1")

        XCTAssertNotEqual(item1, item2) // Different IDs
        XCTAssertNotEqual(item1.hashValue, item2.hashValue)
    }

    func testIdentifiable() {
        let item = ContentItem.text(content: "Test", senderId: "s1")
        XCTAssertFalse(item.id.isEmpty)
    }

    // MARK: - Test Edge Cases

    func testEmptyTextContent() {
        let item = ContentItem.text(content: "", senderId: "s1")
        XCTAssertEqual(item.textContent, "")
        XCTAssertEqual(item.fileSize, 0)
    }

    func testLargeTextContent() {
        let largeText = String(repeating: "a", count: 1_000_000) // 1MB
        let item = ContentItem.text(content: largeText, senderId: "s1")

        XCTAssertEqual(item.textContent?.count, 1_000_000)
        XCTAssertGreaterThan(item.fileSize, 900_000)
    }

    func testMultipleStateUpdates() {
        var item = ContentItem.text(content: "Test", senderId: "s1")

        item = item.updateState(.aiReviewing)
        item = item.updateState(.aiApproved)
        item = item.updateState(.sending)
        item = item.updateState(.sent)

        XCTAssertEqual(item.state, .sent)
        XCTAssertNotNil(item.aiReviewedAt)
        XCTAssertNotNil(item.transferStartedAt)
        XCTAssertNotNil(item.transferCompletedAt)
    }

    // MARK: - Test Performance

    func testContentItemCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = ContentItem.text(content: "Test", senderId: "s1")
            }
        }
    }

    func testPhotoCreationPerformance() {
        let image = createTestImage()

        measure {
            for _ in 0..<10 {
                _ = ContentItem.photo(image: image, senderId: "s1")
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

//
//  ContentItem.swift
//  TrainBlink
//
//  Feature 3: Content Sharing
//  Model representing content that can be shared between peers
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import UIKit

/// Type of content that can be shared
enum ContentType: String, Codable {
    case photo
    case text
}

/// State of content item
enum ContentState: String, Codable {
    case pending           // Ready to send
    case aiReviewing       // Being reviewed by AI
    case aiApproved        // AI approved, ready to send
    case aiRejected        // AI rejected (NSFW/inappropriate)
    case sending           // Currently sending
    case sent              // Successfully sent
    case failed            // Failed to send
    case receiving         // Currently receiving
    case received          // Successfully received
}

/// Reason for AI rejection
enum AIRejectionReason: String, Codable {
    case nsfwDetected      // NSFW content detected
    case faceDetected      // Face detected (user cancelled)
    case processingError   // AI processing failed
    case timeout           // AI processing timeout
}

/// Content item that can be shared between peers
struct ContentItem: Identifiable, Codable, Hashable {

    // MARK: - Properties

    let id: String
    let type: ContentType
    var state: ContentState
    let createdAt: Date
    var sentAt: Date?
    var receivedAt: Date?

    // Content data
    var textContent: String?        // For text type
    var imageData: Data?            // For photo type (compressed)
    var originalImageSize: Int?     // Original size before compression
    var compressedImageSize: Int?   // Size after compression
    var thumbnail: Data?            // Small thumbnail for UI

    // Metadata
    var fileName: String?
    var mimeType: String?
    var fileSize: Int                // Size in bytes

    // Transfer progress
    var progress: Double = 0.0       // 0.0 to 1.0
    var transferStartedAt: Date?
    var transferCompletedAt: Date?

    // AI review
    var aiReviewedAt: Date?
    var aiRejectionReason: AIRejectionReason?
    var aiConfidenceScore: Double?   // NSFW confidence (< 0.3 = approved)

    // Sender/Receiver
    let senderId: String
    var receiverId: String?

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        type: ContentType,
        state: ContentState = .pending,
        createdAt: Date = Date(),
        textContent: String? = nil,
        imageData: Data? = nil,
        fileName: String? = nil,
        mimeType: String? = nil,
        fileSize: Int,
        senderId: String,
        receiverId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.state = state
        self.createdAt = createdAt
        self.textContent = textContent
        self.imageData = imageData
        self.fileName = fileName
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.senderId = senderId
        self.receiverId = receiverId
    }

    // MARK: - Computed Properties

    /// Whether content is ready to send
    var isReadyToSend: Bool {
        state == .aiApproved
    }

    /// Whether content is currently being transferred
    var isTransferring: Bool {
        state == .sending || state == .receiving
    }

    /// Whether transfer is complete
    var isComplete: Bool {
        state == .sent || state == .received
    }

    /// Whether transfer failed
    var isFailed: Bool {
        state == .failed || state == .aiRejected
    }

    /// File size in MB
    var fileSizeMB: Double {
        Double(fileSize) / 1_000_000.0
    }

    /// Whether file exceeds 10MB limit
    var exceedsSizeLimit: Bool {
        fileSizeMB > 10.0
    }

    /// Transfer duration in seconds
    var transferDuration: TimeInterval? {
        guard let start = transferStartedAt,
              let end = transferCompletedAt else {
            return nil
        }
        return end.timeIntervalSince(start)
    }

    /// Transfer speed in KB/s
    var transferSpeed: Double? {
        guard let duration = transferDuration, duration > 0 else {
            return nil
        }
        return Double(fileSize) / 1000.0 / duration
    }

    /// Progress percentage (0-100)
    var progressPercentage: Int {
        Int(progress * 100)
    }

    /// Display name for UI
    var displayName: String {
        switch type {
        case .photo:
            return fileName ?? "Photo"
        case .text:
            return "Text Message"
        }
    }

    /// Icon name for UI
    var iconName: String {
        switch type {
        case .photo:
            return "photo"
        case .text:
            return "text.bubble"
        }
    }

    /// State icon name for UI
    var stateIconName: String {
        switch state {
        case .pending:
            return "clock"
        case .aiReviewing:
            return "eye"
        case .aiApproved:
            return "checkmark.shield"
        case .aiRejected:
            return "xmark.shield"
        case .sending, .receiving:
            return "arrow.up.arrow.down"
        case .sent:
            return "checkmark.circle"
        case .received:
            return "arrow.down.circle"
        case .failed:
            return "xmark.circle"
        }
    }

    // MARK: - Static Constructors

    /// Create text content item
    static func text(
        content: String,
        senderId: String,
        receiverId: String? = nil
    ) -> ContentItem {
        let data = content.data(using: .utf8) ?? Data()
        return ContentItem(
            type: .text,
            textContent: content,
            mimeType: "text/plain",
            fileSize: data.count,
            senderId: senderId,
            receiverId: receiverId
        )
    }

    /// Create photo content item
    static func photo(
        image: UIImage,
        senderId: String,
        receiverId: String? = nil,
        compressionQuality: CGFloat = 0.7
    ) -> ContentItem? {
        // Get original size
        guard let originalData = image.jpegData(compressionQuality: 1.0) else {
            return nil
        }

        // Compress image
        guard let compressedData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }

        // Create thumbnail
        let thumbnailSize = CGSize(width: 100, height: 100)
        let thumbnail = image.resized(to: thumbnailSize)
        let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.5)

        return ContentItem(
            type: .photo,
            imageData: compressedData,
            fileName: "photo_\(UUID().uuidString.prefix(8)).jpg",
            mimeType: "image/jpeg",
            fileSize: compressedData.count,
            senderId: senderId,
            receiverId: receiverId
        ).with(
            originalImageSize: originalData.count,
            compressedImageSize: compressedData.count,
            thumbnail: thumbnailData
        )
    }

    // MARK: - Update Methods

    /// Update state
    func updateState(_ newState: ContentState) -> ContentItem {
        var updated = self
        updated.state = newState

        // Auto-update timestamps
        switch newState {
        case .sending, .receiving:
            updated.transferStartedAt = Date()
        case .sent, .received:
            updated.transferCompletedAt = Date()
            updated.progress = 1.0
        case .aiApproved, .aiRejected:
            updated.aiReviewedAt = Date()
        default:
            break
        }

        return updated
    }

    /// Update progress
    func updateProgress(_ newProgress: Double) -> ContentItem {
        var updated = self
        updated.progress = min(max(newProgress, 0.0), 1.0)
        return updated
    }

    /// Mark as AI rejected
    func rejectByAI(reason: AIRejectionReason, confidence: Double? = nil) -> ContentItem {
        var updated = self
        updated.state = .aiRejected
        updated.aiRejectionReason = reason
        updated.aiConfidenceScore = confidence
        updated.aiReviewedAt = Date()
        return updated
    }

    /// Mark as AI approved
    func approveByAI(confidence: Double? = nil) -> ContentItem {
        var updated = self
        updated.state = .aiApproved
        updated.aiConfidenceScore = confidence
        updated.aiReviewedAt = Date()
        return updated
    }

    /// Update with custom properties (builder pattern)
    private func with(
        originalImageSize: Int? = nil,
        compressedImageSize: Int? = nil,
        thumbnail: Data? = nil
    ) -> ContentItem {
        var updated = self
        updated.originalImageSize = originalImageSize
        updated.compressedImageSize = compressedImageSize
        updated.thumbnail = thumbnail
        return updated
    }
}

// MARK: - UIImage Extension

extension UIImage {
    /// Resize image to fit within size
    func resized(to size: CGSize) -> UIImage? {
        let aspectWidth = size.width / self.size.width
        let aspectHeight = size.height / self.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)

        let newSize = CGSize(
            width: self.size.width * aspectRatio,
            height: self.size.height * aspectRatio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

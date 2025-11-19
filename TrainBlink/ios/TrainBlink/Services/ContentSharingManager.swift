//
//  ContentSharingManager.swift
//  TrainBlink
//
//  Feature 3: Content Sharing
//  Manages content sharing between peers using MultipeerConnectivity
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Combine
import UIKit

/// Content sharing event types
enum ContentSharingEvent {
    case contentReadyToSend(ContentItem)
    case contentSendStarted(ContentItem)
    case contentSendProgress(ContentItem, Double)
    case contentSent(ContentItem)
    case contentSendFailed(ContentItem, Error)
    case contentReceiveStarted(ContentItem)
    case contentReceiveProgress(ContentItem, Double)
    case contentReceived(ContentItem)
    case contentReceiveFailed(ContentItem, Error)
    case aiReviewStarted(ContentItem)
    case aiReviewCompleted(ContentItem, Bool)
}

/// Content sharing errors
enum ContentSharingError: Error, LocalizedError {
    case peerNotConnected
    case sessionNotAvailable
    case contentTooLarge(sizeMB: Double)
    case transferTimeout
    case aiReviewFailed
    case invalidContentData
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .peerNotConnected:
            return "Peer is not connected"
        case .sessionNotAvailable:
            return "Multipeer session not available"
        case .contentTooLarge(let sizeMB):
            return "Content too large: \(String(format: "%.1f", sizeMB))MB (max 10MB)"
        case .transferTimeout:
            return "Transfer timed out after 30 seconds"
        case .aiReviewFailed:
            return "AI review failed"
        case .invalidContentData:
            return "Invalid content data"
        case .compressionFailed:
            return "Image compression failed"
        }
    }
}

/// Content sharing manager using MultipeerConnectivity
final class ContentSharingManager: ObservableObject {

    // MARK: - Published Properties

    @Published var pendingItems: [ContentItem] = []
    @Published var sentItems: [ContentItem] = []
    @Published var receivedItems: [ContentItem] = []

    // MARK: - Properties

    private weak var multipeerManager: MultipeerManager?

    // Configuration (from REQUIREMENTS.md)
    private let maxFileSizeMB: Double = 10.0
    private let chunkSize: Int = 64 * 1024  // 64KB chunks for streaming
    private let transferTimeout: TimeInterval = 30.0

    // Event publisher
    let eventPublisher = PassthroughSubject<ContentSharingEvent, Never>()

    // Transfer tracking
    private var activeTransfers: [String: Progress] = [:]
    private var transferTimers: [String: Timer] = [:]

    // MARK: - Initialization

    init(multipeerManager: MultipeerManager? = nil) {
        self.multipeerManager = multipeerManager
        print("📤 ContentSharingManager initialized")
    }

    deinit {
        transferTimers.values.forEach { $0.invalidate() }
    }

    // MARK: - Public Methods

    /// Set multipeer manager (dependency injection)
    func setMultipeerManager(_ manager: MultipeerManager) {
        self.multipeerManager = manager
    }

    /// Create content item from text
    func createTextContent(
        text: String,
        senderId: String,
        receiverId: String? = nil
    ) -> Result<ContentItem, ContentSharingError> {
        let item = ContentItem.text(
            content: text,
            senderId: senderId,
            receiverId: receiverId
        )

        // Check size limit
        if item.exceedsSizeLimit {
            return .failure(.contentTooLarge(sizeMB: item.fileSizeMB))
        }

        // Add to pending
        pendingItems.append(item)

        print("📝 Created text content: \(item.id)")

        // Log to Firebase
        AnalyticsManager.shared.logContentCreated(
            contentType: "text",
            fileSizeMB: item.fileSizeMB
        )

        return .success(item)
    }

    /// Create content item from image
    func createPhotoContent(
        image: UIImage,
        senderId: String,
        receiverId: String? = nil,
        compressionQuality: CGFloat = 0.7
    ) -> Result<ContentItem, ContentSharingError> {
        guard var item = ContentItem.photo(
            image: image,
            senderId: senderId,
            receiverId: receiverId,
            compressionQuality: compressionQuality
        ) else {
            return .failure(.compressionFailed)
        }

        // Check size limit - if too large, compress more
        if item.exceedsSizeLimit {
            print("⚠️ Photo too large (\(String(format: "%.1f", item.fileSizeMB))MB), increasing compression...")

            // Try higher compression
            guard let recompressed = ContentItem.photo(
                image: image,
                senderId: senderId,
                receiverId: receiverId,
                compressionQuality: 0.4
            ) else {
                return .failure(.compressionFailed)
            }

            item = recompressed

            // Still too large?
            if item.exceedsSizeLimit {
                return .failure(.contentTooLarge(sizeMB: item.fileSizeMB))
            }
        }

        // Add to pending
        pendingItems.append(item)

        print("📷 Created photo content: \(item.id) (\(String(format: "%.1f", item.fileSizeMB))MB)")

        // Log to Firebase
        AnalyticsManager.shared.logContentCreated(
            contentType: "photo",
            fileSizeMB: item.fileSizeMB
        )

        return .success(item)
    }

    /// Review content with AI (Feature 4: AI Safety)
    /// Performs NSFW detection and face detection
    func reviewWithAI(contentId: String) async -> Result<ContentItem, ContentSharingError> {
        guard let index = pendingItems.firstIndex(where: { $0.id == contentId }) else {
            return .failure(.invalidContentData)
        }

        var item = pendingItems[index]

        // Update state to reviewing
        item = item.updateState(.aiReviewing)
        pendingItems[index] = item
        eventPublisher.send(.aiReviewStarted(item))

        print("🤖 AI Review started for: \(item.id)")

        // Log to Firebase
        let reviewStart = Date()

        // Only review photo content (text doesn't need AI review for MVP)
        if item.type == .photo {
            // Convert image data to UIImage
            guard let imageData = item.imageData,
                  let image = UIImage(data: imageData) else {
                return .failure(.invalidContentData)
            }

            // 1. NSFW Detection (required)
            do {
                let nsfwResult = try await NSFWDetector.shared.analyze(image)

                print("🤖 NSFW Detection: confidence=\(String(format: "%.2f", nsfwResult.confidence)), " +
                      "isNSFW=\(nsfwResult.isNSFW)")

                // Log NSFW detection to Firebase
                if nsfwResult.isNSFW {
                    AnalyticsManager.shared.logAINSFWDetected(
                        confidence: String(format: "%.2f", nsfwResult.confidence),
                        action: "blocked"
                    )
                }

                // Reject if NSFW detected (confidence >= 0.3)
                if nsfwResult.isNSFW {
                    item = item.rejectByAI(
                        reason: .nsfwDetected,
                        confidence: nsfwResult.confidence
                    )
                    pendingItems[index] = item
                    eventPublisher.send(.aiReviewCompleted(item, false))

                    // Log to Firebase
                    let reviewDuration = Date().timeIntervalSince(reviewStart)
                    AnalyticsManager.shared.logContentReviewedByAI(
                        contentType: item.type.rawValue,
                        reviewResult: "blocked",
                        reviewDurationMs: Int(reviewDuration * 1000)
                    )

                    print("❌ AI Review completed for: \(item.id) - REJECTED (NSFW)")

                    return .success(item)
                }

                // 2. Face Detection (warning)
                let faceResult = try await FaceDetector.shared.analyze(image)

                print("🤖 Face Detection: count=\(faceResult.faceCount)")

                // Log face detection to Firebase
                if faceResult.hasFaces {
                    AnalyticsManager.shared.logAIFaceDetected(
                        faceCount: faceResult.faceCount,
                        action: "warned"
                    )
                }

                // Approve (user will be prompted for face confirmation in UI if needed)
                item = item.approveByAI(confidence: nsfwResult.confidence)
                pendingItems[index] = item
                eventPublisher.send(.aiReviewCompleted(item, true))

                // Log to Firebase
                let reviewDuration = Date().timeIntervalSince(reviewStart)
                AnalyticsManager.shared.logContentReviewedByAI(
                    contentType: item.type.rawValue,
                    reviewResult: "approved",
                    reviewDurationMs: Int(reviewDuration * 1000)
                )

                print("✅ AI Review completed for: \(item.id) - APPROVED" +
                      (faceResult.hasFaces ? " (⚠️ \(faceResult.faceCount) face(s) detected)" : ""))

                return .success(item)

            } catch {
                // AI processing failed - log error but allow content (fail open)
                print("❌ AI Review failed for: \(item.id) - \(error.localizedDescription)")

                ErrorTracker.record(
                    .modelInferenceFailed(modelType: "nsfw_face"),
                    context: [
                        "content_id": item.id,
                        "error": error.localizedDescription
                    ]
                )

                // Approve with warning (fail-open strategy for better UX)
                item = item.approveByAI(confidence: nil)
                pendingItems[index] = item
                eventPublisher.send(.aiReviewCompleted(item, true))

                let reviewDuration = Date().timeIntervalSince(reviewStart)
                AnalyticsManager.shared.logContentReviewedByAI(
                    contentType: item.type.rawValue,
                    reviewResult: "approved_with_error",
                    reviewDurationMs: Int(reviewDuration * 1000)
                )

                print("⚠️ AI Review completed for: \(item.id) - APPROVED (with error)")

                return .success(item)
            }
        } else {
            // Text content - auto-approve (no AI review needed for MVP)
            item = item.approveByAI(confidence: 0.0)
            pendingItems[index] = item
            eventPublisher.send(.aiReviewCompleted(item, true))

            let reviewDuration = Date().timeIntervalSince(reviewStart)
            AnalyticsManager.shared.logContentReviewedByAI(
                contentType: item.type.rawValue,
                reviewResult: "approved",
                reviewDurationMs: Int(reviewDuration * 1000)
            )

            print("✅ AI Review completed for: \(item.id) - APPROVED (text, no review needed)")

            return .success(item)
        }
    }

    /// Send content to peer
    func sendContent(
        contentId: String,
        toPeerId: String
    ) async -> Result<Void, ContentSharingError> {
        guard let index = pendingItems.firstIndex(where: { $0.id == contentId }) else {
            return .failure(.invalidContentData)
        }

        var item = pendingItems[index]

        // Check if AI approved
        guard item.isReadyToSend else {
            return .failure(.aiReviewFailed)
        }

        // Check session
        guard let session = multipeerManager?.getSession() else {
            return .failure(.sessionNotAvailable)
        }

        // Find peer
        let peerID = MCPeerID(displayName: toPeerId)
        guard session.connectedPeers.contains(peerID) else {
            return .failure(.peerNotConnected)
        }

        // Update state
        item = item.updateState(.sending)
        item.receiverId = toPeerId
        pendingItems[index] = item
        eventPublisher.send(.contentSendStarted(item))

        print("📤 Sending content: \(item.id) to \(toPeerId)")

        // Log to Firebase
        AnalyticsManager.shared.logContentSendStarted(
            contentType: item.type.rawValue,
            fileSizeMB: item.fileSizeMB,
            receiverId: toPeerId
        )

        // Prepare data to send
        guard let data = prepareContentData(item) else {
            return .failure(.invalidContentData)
        }

        // Send via MCSession
        do {
            try session.send(data, toPeers: [peerID], with: .reliable)

            // Update state to sent
            item = item.updateState(.sent)
            pendingItems[index] = item
            sentItems.append(item)
            eventPublisher.send(.contentSent(item))

            // Log to Firebase
            if let duration = item.transferDuration, let speed = item.transferSpeed {
                AnalyticsManager.shared.logContentSent(
                    contentType: item.type.rawValue,
                    fileSizeMB: item.fileSizeMB,
                    transferDurationMs: Int(duration * 1000),
                    transferSpeedKBps: Int(speed)
                )
            }

            print("✅ Content sent successfully: \(item.id)")
            return .success(())

        } catch {
            // Update state to failed
            item = item.updateState(.failed)
            pendingItems[index] = item
            eventPublisher.send(.contentSendFailed(item, error))

            // Log to Firebase
            ErrorTracker.record(
                .contentSendFailed(reason: error.localizedDescription),
                context: [
                    "content_id": item.id,
                    "content_type": item.type.rawValue,
                    "receiver_id": toPeerId,
                    "error": error.localizedDescription
                ]
            )

            print("❌ Failed to send content: \(error.localizedDescription)")
            return .failure(.invalidContentData)
        }
    }

    /// Handle received data from peer
    func handleReceivedData(_ data: Data, fromPeerId: String) {
        print("📥 Received content data from: \(fromPeerId) (\(data.count) bytes)")

        // Check if sender is blocked (Feature 7)
        if BlockingManager.shared.isBlocked(peerId: fromPeerId) {
            print("🚫 Rejecting content from blocked peer: \(fromPeerId)")
            AnalyticsManager.shared.logContentRejectedFromBlockedPeer(senderId: fromPeerId)
            return
        }

        // Decode content item
        guard let item = decodeContentData(data, fromPeerId: fromPeerId) else {
            print("❌ Failed to decode content data")
            return
        }

        // Update state to received
        var receivedItem = item.updateState(.received)
        receivedItem.receivedAt = Date()
        receivedItems.append(receivedItem)
        eventPublisher.send(.contentReceived(receivedItem))

        // Log to Firebase
        AnalyticsManager.shared.logContentReceived(
            contentType: receivedItem.type.rawValue,
            fileSizeMB: receivedItem.fileSizeMB,
            senderId: fromPeerId
        )

        print("✅ Content received successfully: \(receivedItem.id)")
    }

    /// Clear all items (called on station exit)
    func clearAll() {
        pendingItems.removeAll()
        sentItems.removeAll()
        receivedItems.removeAll()
        activeTransfers.removeAll()
        transferTimers.values.forEach { $0.invalidate() }
        transferTimers.removeAll()

        print("🗑️ Cleared all content items")
    }

    // MARK: - Private Methods

    /// Prepare content data for sending
    private func prepareContentData(_ item: ContentItem) -> Data? {
        // Create metadata
        var metadata: [String: Any] = [
            "id": item.id,
            "type": item.type.rawValue,
            "senderId": item.senderId,
            "createdAt": item.createdAt.timeIntervalSince1970
        ]

        // Add content data
        switch item.type {
        case .text:
            metadata["textContent"] = item.textContent ?? ""
        case .photo:
            guard let imageData = item.imageData else { return nil }
            metadata["imageData"] = imageData.base64EncodedString()
            metadata["fileName"] = item.fileName ?? "photo.jpg"
        }

        // Encode to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: metadata) else {
            return nil
        }

        return jsonData
    }

    /// Decode content data from received data
    private func decodeContentData(_ data: Data, fromPeerId: String) -> ContentItem? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String,
              let typeString = json["type"] as? String,
              let type = ContentType(rawValue: typeString),
              let senderId = json["senderId"] as? String,
              let createdAtTimestamp = json["createdAt"] as? TimeInterval else {
            return nil
        }

        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)

        switch type {
        case .text:
            guard let textContent = json["textContent"] as? String else { return nil }
            return ContentItem.text(
                content: textContent,
                senderId: senderId
            ).updateState(.receiving)

        case .photo:
            guard let imageDataString = json["imageData"] as? String,
                  let imageData = Data(base64Encoded: imageDataString) else {
                return nil
            }

            let fileName = json["fileName"] as? String

            return ContentItem(
                id: id,
                type: .photo,
                state: .receiving,
                createdAt: createdAt,
                imageData: imageData,
                fileName: fileName,
                mimeType: "image/jpeg",
                fileSize: imageData.count,
                senderId: senderId
            )
        }
    }

    /// Start transfer timeout timer
    private func startTransferTimeout(for contentId: String) {
        let timer = Timer.scheduledTimer(withTimeInterval: transferTimeout, repeats: false) { [weak self] _ in
            self?.handleTransferTimeout(contentId: contentId)
        }
        transferTimers[contentId] = timer
    }

    /// Handle transfer timeout
    private func handleTransferTimeout(contentId: String) {
        print("⏰ Transfer timeout for content: \(contentId)")

        // Find and update item
        if let index = pendingItems.firstIndex(where: { $0.id == contentId }) {
            var item = pendingItems[index]
            item = item.updateState(.failed)
            pendingItems[index] = item
            eventPublisher.send(.contentSendFailed(item, ContentSharingError.transferTimeout))

            // Log to Firebase
            ErrorTracker.record(
                .contentSendFailed(reason: "Transfer timeout"),
                context: ["content_id": contentId]
            )
        }

        // Cleanup
        transferTimers[contentId]?.invalidate()
        transferTimers.removeValue(forKey: contentId)
        activeTransfers.removeValue(forKey: contentId)
    }
}

// MARK: - Analytics Extensions (Feature 7)

extension AnalyticsManager {

    /// Log content rejected from blocked peer
    func logContentRejectedFromBlockedPeer(senderId: String) {
        let parameters: [String: Any] = [
            "sender_id": senderId
        ]
        logEvent("content_rejected_blocked_peer", parameters: parameters)
    }
}

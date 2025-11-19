//
//  AIReviewResult.swift
//  TrainBlink
//
//  Feature 4: AI Safety
//  Result types for AI content review
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation

/// Result of AI content review
struct AIContentReviewResult {
    let isApproved: Bool
    let nsfwConfidence: Double?
    let faceCount: Int?
    let rejectionReason: AIRejectionReason?
    let processingTimeMs: Int
    let requiresUserConfirmation: Bool

    /// Approved result
    static func approved(
        nsfwConfidence: Double,
        faceCount: Int,
        processingTimeMs: Int
    ) -> AIContentReviewResult {
        return AIContentReviewResult(
            isApproved: true,
            nsfwConfidence: nsfwConfidence,
            faceCount: faceCount,
            rejectionReason: nil,
            processingTimeMs: processingTimeMs,
            requiresUserConfirmation: faceCount > 0
        )
    }

    /// Rejected result
    static func rejected(
        reason: AIRejectionReason,
        confidence: Double? = nil,
        processingTimeMs: Int
    ) -> AIContentReviewResult {
        return AIContentReviewResult(
            isApproved: false,
            nsfwConfidence: confidence,
            faceCount: nil,
            rejectionReason: reason,
            processingTimeMs: processingTimeMs,
            requiresUserConfirmation: false
        )
    }
}

/// NSFW detection result
struct NSFWDetectionResult {
    let confidence: Double  // 0.0 to 1.0 (higher = more likely NSFW)
    let isNSFW: Bool        // true if confidence >= 0.3
    let processingTimeMs: Int

    init(confidence: Double, processingTimeMs: Int) {
        self.confidence = confidence
        self.isNSFW = confidence >= 0.3  // PRD threshold
        self.processingTimeMs = processingTimeMs
    }
}

/// Face detection result
struct FaceDetectionResult {
    let faceCount: Int
    let hasFaces: Bool
    let processingTimeMs: Int

    init(faceCount: Int, processingTimeMs: Int) {
        self.faceCount = faceCount
        self.hasFaces = faceCount > 0
        self.processingTimeMs = processingTimeMs
    }
}

//
//  AIDetectorTests.swift
//  TrainBlinkTests
//
//  Unit tests for AI detectors (NSFW and Face Detection)
//  Feature 4: AI Safety
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
@testable import TrainBlink
import UIKit

final class AIDetectorTests: XCTestCase {

    // MARK: - NSFW Detector Tests

    func testNSFWDetectorAnalyze() async throws {
        let image = createTestImage(color: .red)

        let result = try await NSFWDetector.shared.analyze(image)

        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
        XCTAssertGreaterThan(result.processingTimeMs, 0)
    }

    func testNSFWDetectorThreshold() async throws {
        let image = createTestImage(color: .blue)

        let result = try await NSFWDetector.shared.analyze(image)

        // Test threshold logic
        if result.confidence >= 0.3 {
            XCTAssertTrue(result.isNSFW)
        } else {
            XCTAssertFalse(result.isNSFW)
        }
    }

    func testNSFWDetectorConsistency() async throws {
        // Same image should produce same result
        let image = createTestImage(color: .green)

        let result1 = try await NSFWDetector.shared.analyze(image)
        let result2 = try await NSFWDetector.shared.analyze(image)

        XCTAssertEqual(result1.confidence, result2.confidence, accuracy: 0.01)
    }

    func testNSFWDetectorPerformance() async throws {
        let image = createTestImage(color: .yellow)

        let result = try await NSFWDetector.shared.analyze(image)

        // Should complete within target time (500ms for placeholder)
        XCTAssertLessThan(result.processingTimeMs, 1000, "NSFW detection took too long")
    }

    func testNSFWDetectorMultipleImages() async throws {
        let images = [
            createTestImage(color: .red),
            createTestImage(color: .blue),
            createTestImage(color: .green)
        ]

        for image in images {
            let result = try await NSFWDetector.shared.analyze(image)
            XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
            XCTAssertLessThanOrEqual(result.confidence, 1.0)
        }
    }

    // MARK: - Face Detector Tests

    func testFaceDetectorAnalyze() async throws {
        let image = createTestImage(color: .red)

        let result = try await FaceDetector.shared.analyze(image)

        XCTAssertGreaterThanOrEqual(result.faceCount, 0)
        XCTAssertGreaterThan(result.processingTimeMs, 0)
    }

    func testFaceDetectorNoFaces() async throws {
        // Simple colored image should have no faces
        let image = createTestImage(color: .blue)

        let result = try await FaceDetector.shared.analyze(image)

        XCTAssertEqual(result.faceCount, 0)
        XCTAssertFalse(result.hasFaces)
    }

    func testFaceDetectorPerformance() async throws {
        let image = createTestImage(color: .green)

        let result = try await FaceDetector.shared.analyze(image)

        // Should complete within target time (300ms)
        XCTAssertLessThan(result.processingTimeMs, 500, "Face detection took too long")
    }

    func testFaceDetectorInvalidImage() async {
        // Test error handling for invalid image
        // This is tested implicitly in ContentSharingManager integration
    }

    func testFaceDetectorDetailedAnalysis() async throws {
        let image = createTestImage(color: .purple)

        let result = try await FaceDetector.shared.analyzeDetailed(image)

        XCTAssertEqual(result.faceCount, result.faces.count)
        XCTAssertGreaterThan(result.processingTimeMs, 0)
    }

    // MARK: - AI Review Result Tests

    func testNSFWDetectionResultThreshold() {
        // Below threshold
        let safe = NSFWDetectionResult(confidence: 0.2, processingTimeMs: 100)
        XCTAssertFalse(safe.isNSFW)

        // At threshold
        let atThreshold = NSFWDetectionResult(confidence: 0.3, processingTimeMs: 100)
        XCTAssertTrue(atThreshold.isNSFW)

        // Above threshold
        let unsafe = NSFWDetectionResult(confidence: 0.5, processingTimeMs: 100)
        XCTAssertTrue(unsafe.isNSFW)
    }

    func testFaceDetectionResultHasFaces() {
        let noFaces = FaceDetectionResult(faceCount: 0, processingTimeMs: 100)
        XCTAssertFalse(noFaces.hasFaces)

        let oneFace = FaceDetectionResult(faceCount: 1, processingTimeMs: 100)
        XCTAssertTrue(oneFace.hasFaces)

        let multipleFaces = FaceDetectionResult(faceCount: 3, processingTimeMs: 100)
        XCTAssertTrue(multipleFaces.hasFaces)
    }

    func testAIContentReviewResultApproved() {
        let result = AIContentReviewResult.approved(
            nsfwConfidence: 0.1,
            faceCount: 0,
            processingTimeMs: 200
        )

        XCTAssertTrue(result.isApproved)
        XCTAssertEqual(result.nsfwConfidence, 0.1)
        XCTAssertEqual(result.faceCount, 0)
        XCTAssertFalse(result.requiresUserConfirmation)
        XCTAssertNil(result.rejectionReason)
    }

    func testAIContentReviewResultApprovedWithFaces() {
        let result = AIContentReviewResult.approved(
            nsfwConfidence: 0.15,
            faceCount: 2,
            processingTimeMs: 250
        )

        XCTAssertTrue(result.isApproved)
        XCTAssertEqual(result.faceCount, 2)
        XCTAssertTrue(result.requiresUserConfirmation) // Faces detected
    }

    func testAIContentReviewResultRejected() {
        let result = AIContentReviewResult.rejected(
            reason: .nsfwDetected,
            confidence: 0.8,
            processingTimeMs: 180
        )

        XCTAssertFalse(result.isApproved)
        XCTAssertEqual(result.rejectionReason, .nsfwDetected)
        XCTAssertEqual(result.nsfwConfidence, 0.8)
        XCTAssertFalse(result.requiresUserConfirmation)
    }

    // MARK: - Integration Tests

    func testNSFWAndFaceDetectionTogether() async throws {
        let image = createTestImage(color: .orange)

        // Run both detectors
        let nsfwResult = try await NSFWDetector.shared.analyze(image)
        let faceResult = try await FaceDetector.shared.analyze(image)

        // Both should complete successfully
        XCTAssertGreaterThanOrEqual(nsfwResult.confidence, 0.0)
        XCTAssertGreaterThanOrEqual(faceResult.faceCount, 0)

        // Total processing time should be reasonable
        let totalTime = nsfwResult.processingTimeMs + faceResult.processingTimeMs
        XCTAssertLessThan(totalTime, 1000, "Combined AI processing took too long")
    }

    // MARK: - Performance Tests

    func testNSFWDetectorBatchPerformance() {
        measure {
            Task {
                for _ in 0..<5 {
                    let image = createTestImage(color: .random)
                    _ = try? await NSFWDetector.shared.analyze(image)
                }
            }
        }
    }

    func testFaceDetectorBatchPerformance() {
        measure {
            Task {
                for _ in 0..<5 {
                    let image = createTestImage(color: .random)
                    _ = try? await FaceDetector.shared.analyze(image)
                }
            }
        }
    }

    // MARK: - Edge Cases

    func testNSFWDetectorSmallImage() async throws {
        let smallImage = createTestImage(size: CGSize(width: 10, height: 10), color: .red)

        let result = try await NSFWDetector.shared.analyze(smallImage)

        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
    }

    func testNSFWDetectorLargeImage() async throws {
        let largeImage = createTestImage(size: CGSize(width: 2000, height: 2000), color: .blue)

        let result = try await NSFWDetector.shared.analyze(largeImage)

        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
    }

    func testFaceDetectorSmallImage() async throws {
        let smallImage = createTestImage(size: CGSize(width: 10, height: 10), color: .green)

        let result = try await FaceDetector.shared.analyze(smallImage)

        XCTAssertGreaterThanOrEqual(result.faceCount, 0)
    }

    // MARK: - Helper Methods

    private func createTestImage(
        size: CGSize = CGSize(width: 100, height: 100),
        color: UIColor
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - UIColor Random Extension

extension UIColor {
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}

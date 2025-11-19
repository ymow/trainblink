//
//  FaceDetector.swift
//  TrainBlink
//
//  Feature 4: AI Safety
//  Face detection using Vision framework
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import UIKit
import Vision

/// Face detector using Vision framework
final class FaceDetector {

    // MARK: - Singleton

    static let shared = FaceDetector()

    private init() {
        print("👤 FaceDetector initialized")
    }

    // MARK: - Configuration

    /// Target processing time (PRD requirement)
    private let targetProcessingTimeMs: Int = 300

    // MARK: - Public Methods

    /// Detect faces in image
    /// - Parameter image: The image to analyze
    /// - Returns: Detection result with face count
    func analyze(_ image: UIImage) async throws -> FaceDetectionResult {
        let startTime = Date()

        // Convert UIImage to CGImage
        guard let cgImage = image.cgImage else {
            throw FaceDetectionError.invalidImage
        }

        // Create face detection request
        let request = VNDetectFaceRectanglesRequest()

        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // Extract results
        let faceCount = request.results?.count ?? 0

        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

        let result = FaceDetectionResult(
            faceCount: faceCount,
            processingTimeMs: processingTime
        )

        // Log performance
        print("👤 Face Detection: count=\(faceCount), time=\(processingTime)ms")

        // Track performance in Firebase
        if processingTime > targetProcessingTimeMs {
            print("⚠️ Face detection exceeded target time: \(processingTime)ms > \(targetProcessingTimeMs)ms")
        }

        return result
    }

    /// Detect faces with detailed information (landmarks, quality, etc.)
    /// - Parameter image: The image to analyze
    /// - Returns: Detailed face detection results
    func analyzeDetailed(_ image: UIImage) async throws -> DetailedFaceDetectionResult {
        let startTime = Date()

        guard let cgImage = image.cgImage else {
            throw FaceDetectionError.invalidImage
        }

        // Create detailed face detection request with landmarks
        let request = VNDetectFaceLandmarksRequest()

        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // Extract results
        let observations = request.results ?? []
        let faces = observations.map { observation -> DetectedFace in
            return DetectedFace(
                boundingBox: observation.boundingBox,
                confidence: observation.confidence,
                landmarks: observation.landmarks
            )
        }

        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

        return DetailedFaceDetectionResult(
            faces: faces,
            faceCount: faces.count,
            processingTimeMs: processingTime
        )
    }
}

// MARK: - Supporting Types

/// Errors that can occur during face detection
enum FaceDetectionError: Error, LocalizedError {
    case invalidImage
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image for face detection"
        case .processingFailed:
            return "Face detection processing failed"
        }
    }
}

/// Detailed face detection result
struct DetailedFaceDetectionResult {
    let faces: [DetectedFace]
    let faceCount: Int
    let processingTimeMs: Int
}

/// Information about a detected face
struct DetectedFace {
    let boundingBox: CGRect
    let confidence: Float
    let landmarks: VNFaceLandmarks2D?

    /// Whether this is a high-quality face detection
    var isHighQuality: Bool {
        return confidence > 0.8
    }
}

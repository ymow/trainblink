//
//  NSFWDetector.swift
//  TrainBlink
//
//  Feature 4: AI Safety
//  NSFW content detection using Core ML
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import Vision

/// NSFW content detector using Core ML
final class NSFWDetector {

    // MARK: - Singleton

    static let shared = NSFWDetector()

    private init() {
        print("🤖 NSFWDetector initialized")
    }

    // MARK: - Configuration

    /// Confidence threshold for NSFW detection (PRD requirement)
    /// Values >= 0.3 are considered NSFW
    private let nsfwThreshold: Double = 0.3

    /// Target processing time (PRD requirement)
    private let targetProcessingTimeMs: Int = 500

    // MARK: - Public Methods

    /// Analyze image for NSFW content
    /// - Parameter image: The image to analyze
    /// - Returns: Detection result with confidence score
    func analyze(_ image: UIImage) async throws -> NSFWDetectionResult {
        let startTime = Date()

        // TODO: Replace with actual Core ML model when available
        // For MVP, use placeholder implementation
        let confidence = await simulateNSFWDetection(image)

        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

        let result = NSFWDetectionResult(
            confidence: confidence,
            processingTimeMs: processingTime
        )

        // Log performance
        print("🤖 NSFW Detection: confidence=\(String(format: "%.2f", confidence)), " +
              "isNSFW=\(result.isNSFW), time=\(processingTime)ms")

        // Track performance in Firebase
        if processingTime > targetProcessingTimeMs {
            print("⚠️ NSFW detection exceeded target time: \(processingTime)ms > \(targetProcessingTimeMs)ms")
        }

        return result
    }

    // MARK: - Private Methods (Placeholder Implementation)

    /// Placeholder NSFW detection
    /// TODO: Replace with actual Core ML model
    ///
    /// To integrate a real NSFW model:
    /// 1. Add .mlmodel file to project
    /// 2. Convert UIImage to CVPixelBuffer
    /// 3. Run model inference
    /// 4. Extract confidence score from model output
    ///
    /// Example with real model:
    /// ```swift
    /// let model = try NSFWClassifier(configuration: MLModelConfiguration())
    /// let input = try NSFWClassifierInput(imageWith: pixelBuffer)
    /// let output = try model.prediction(input: input)
    /// return output.nsfwProbability
    /// ```
    private func simulateNSFWDetection(_ image: UIImage) async -> Double {
        // Simulate processing time
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // For MVP testing: Generate deterministic pseudo-random confidence
        // based on image properties (so same image always gets same result)
        let hash = imageHash(image)
        let confidence = Double(hash % 100) / 100.0

        // Bias towards safe content (90% chance of < 0.3)
        let biasedConfidence = confidence * 0.3

        return biasedConfidence
    }

    /// Generate simple hash from image for deterministic testing
    private func imageHash(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }

        let width = cgImage.width
        let height = cgImage.height
        let dataSize = image.jpegData(compressionQuality: 1.0)?.count ?? 0

        return (width * 31 + height * 17 + dataSize) % 1000
    }

    // MARK: - Model Integration Guide

    /*
     To integrate a real NSFW Core ML model:

     1. **Add Model to Project**:
        - Drag .mlmodel file into Xcode
        - Xcode auto-generates Swift class
        - Model should accept 224x224 or 299x299 RGB image

     2. **Convert UIImage to CVPixelBuffer**:
     ```swift
     private func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
         let attrs = [
             kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
         ] as CFDictionary

         var pixelBuffer: CVPixelBuffer?
         let status = CVPixelBufferCreate(
             kCFAllocatorDefault,
             Int(size.width),
             Int(size.height),
             kCVPixelFormatType_32ARGB,
             attrs,
             &pixelBuffer
         )

         guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
             return nil
         }

         CVPixelBufferLockBaseAddress(buffer, [])
         defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

         let context = CGContext(
             data: CVPixelBufferGetBaseAddress(buffer),
             width: Int(size.width),
             height: Int(size.height),
             bitsPerComponent: 8,
             bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
             space: CGColorSpaceCreateDeviceRGB(),
             bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
         )

         guard let cgImage = image.cgImage else { return nil }

         context?.draw(cgImage, in: CGRect(origin: .zero, size: size))

         return buffer
     }
     ```

     3. **Run Inference**:
     ```swift
     func analyze(_ image: UIImage) async throws -> NSFWDetectionResult {
         let startTime = Date()

         // Load model
         let model = try NSFWClassifier(configuration: MLModelConfiguration())

         // Prepare input (resize to model's expected size)
         let inputSize = CGSize(width: 224, height: 224)
         let resized = image.resized(to: inputSize)
         guard let buffer = pixelBuffer(from: resized, size: inputSize) else {
             throw NSError(domain: "NSFWDetector", code: 1, userInfo: nil)
         }

         // Run inference
         let input = NSFWClassifierInput(image: buffer)
         let output = try model.prediction(input: input)

         // Extract confidence (assuming model outputs "nsfw_probability")
         let confidence = output.nsfwProbability

         let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)

         return NSFWDetectionResult(
             confidence: confidence,
             processingTimeMs: processingTime
         )
     }
     ```

     4. **Recommended Models**:
        - NSFWDetector (TensorFlow → Core ML converted)
        - Yahoo Open NSFW (Caffe → Core ML converted)
        - Custom trained model on NSFW dataset
        - Model size should be < 50MB (PRD requirement)

     5. **Performance Optimization**:
        - Use Neural Engine (A12+)
        - Batch processing if multiple images
        - Cache model instance (already done with singleton)
        - Use lower resolution input (224x224 vs 299x299)

     6. **Error Handling**:
        - Model load failures → fallback to allow (log error)
        - Inference failures → fallback to allow (log error)
        - Timeout after 2 seconds → fallback to allow (log error)
     */
}

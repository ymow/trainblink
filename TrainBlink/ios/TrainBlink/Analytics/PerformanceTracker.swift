//
//  PerformanceTracker.swift
//  TrainBlink
//
//  Performance monitoring helpers for key operations
//  Feature 12: Firebase Monitoring & Analytics
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import FirebasePerformance

/// Convenience wrapper for Firebase Performance Monitoring
final class PerformanceTracker {

    // MARK: - AI Inference Tracking

    /// Track AI model inference performance
    static func trackAIInference(
        modelType: String,
        contentType: ContentType,
        operation: () async throws -> AIReviewResult
    ) async rethrows -> AIReviewResult {
        let trace = Performance.startTrace(name: "ai_\(modelType)_inference")
        trace?.setValue(contentType.rawValue, forAttribute: "content_type")

        let startTime = Date()

        defer {
            let duration = Date().timeIntervalSince(startTime)
            trace?.setMetric("inference_duration_ms", value: Int64(duration * 1000))
            trace?.incrementMetric("inference_count", by: 1)
            trace?.stop()
        }

        do {
            let result = try await operation()
            trace?.setValue(result.rawValue, forAttribute: "result")
            return result
        } catch {
            trace?.setValue("error", forAttribute: "result")
            throw error
        }
    }

    // MARK: - P2P Connection Tracking

    /// Track P2P connection establishment
    static func trackP2PConnection(
        operation: () async throws -> Void
    ) async rethrows {
        let trace = Performance.startTrace(name: "p2p_connection")
        defer { trace?.stop() }

        do {
            try await operation()
            trace?.incrementMetric("success_count", by: 1)
        } catch {
            trace?.incrementMetric("failure_count", by: 1)
            throw error
        }
    }

    // MARK: - Content Transfer Tracking

    /// Track content transfer performance
    static func trackContentTransfer(
        contentType: ContentType,
        fileSizeBytes: Int,
        operation: () async throws -> Void
    ) async rethrows {
        let trace = Performance.startTrace(name: "content_transfer_\(contentType.rawValue)")
        trace?.setValue(contentType.rawValue, forAttribute: "content_type")
        trace?.setMetric("file_size_kb", value: Int64(fileSizeBytes / 1024))

        let startTime = Date()

        defer {
            let duration = Date().timeIntervalSince(startTime)
            let speedKBps = Double(fileSizeBytes / 1024) / duration
            trace?.setMetric("transfer_duration_ms", value: Int64(duration * 1000))
            trace?.setMetric("speed_kbps", value: Int64(speedKBps))
            trace?.stop()
        }

        do {
            try await operation()
            trace?.incrementMetric("success_count", by: 1)
        } catch {
            trace?.incrementMetric("failure_count", by: 1)
            throw error
        }
    }

    // MARK: - Geofencing Tracking

    /// Track geofence trigger processing time
    static func trackGeofenceTrigger(
        stationName: String,
        operation: () async throws -> Void
    ) async rethrows {
        let trace = Performance.startTrace(name: "geofence_trigger")
        trace?.setValue(stationName, forAttribute: "station_name")

        defer { trace?.stop() }

        do {
            try await operation()
            trace?.incrementMetric("success_count", by: 1)
        } catch {
            trace?.incrementMetric("failure_count", by: 1)
            throw error
        }
    }

    // MARK: - Chat Room Initialization

    /// Track chat room initialization time
    static func trackChatRoomInit(
        encounterCount: Int,
        operation: () async throws -> Void
    ) async rethrows {
        let trace = Performance.startTrace(name: "chat_room_init")
        trace?.setMetric("encounter_count", value: Int64(encounterCount))

        defer { trace?.stop() }

        try await operation()
    }
}

// MARK: - Example Usage

/*
 // Example 1: Track AI NSFW inference
 let result = await PerformanceTracker.trackAIInference(
     modelType: "nsfw",
     contentType: .photo
 ) {
     return await nsfwDetector.detect(image)
 }

 // Example 2: Track P2P connection
 try await PerformanceTracker.trackP2PConnection {
     try await connectToPeer(peerID)
 }

 // Example 3: Track content transfer
 try await PerformanceTracker.trackContentTransfer(
     contentType: .photo,
     fileSizeBytes: 2048000
 ) {
     try await sendPhoto(to: peer)
 }
 */

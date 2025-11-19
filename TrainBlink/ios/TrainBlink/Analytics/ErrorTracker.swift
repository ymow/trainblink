//
//  ErrorTracker.swift
//  TrainBlink
//
//  Centralized error tracking and reporting
//  Feature 12: Firebase Monitoring & Analytics
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import FirebaseCrashlytics

/// Custom errors for TrainBlink
enum TrainBlinkError: Error, LocalizedError {
    // P2P Errors
    case p2pConnectionTimeout
    case p2pConnectionFailed(reason: String)
    case p2pAdvertisingFailed(reason: String)
    case p2pBrowsingFailed(reason: String)
    case peerNotFound
    case peerDisconnected

    // Content Transfer Errors
    case contentTransferFailed(contentType: ContentType, reason: String)
    case contentTooLarge(contentType: ContentType, size: Int, maxSize: Int)
    case contentEncryptionFailed

    // AI Model Errors
    case modelLoadFailed(modelType: String, reason: String)
    case modelInferenceFailed(modelType: String)
    case modelNotFound(modelType: String)

    // Geofencing Errors
    case geofenceRegisterFailed
    case locationPermissionDenied
    case locationUnavailable

    // General Errors
    case invalidState(reason: String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .p2pConnectionTimeout:
            return "P2P connection timed out"
        case .p2pConnectionFailed(let reason):
            return "P2P connection failed: \(reason)"
        case .p2pAdvertisingFailed(let reason):
            return "P2P advertising failed: \(reason)"
        case .p2pBrowsingFailed(let reason):
            return "P2P browsing failed: \(reason)"
        case .peerNotFound:
            return "Peer not found"
        case .peerDisconnected:
            return "Peer disconnected"

        case .contentTransferFailed(let type, let reason):
            return "Content transfer failed (\(type.rawValue)): \(reason)"
        case .contentTooLarge(let type, let size, let maxSize):
            return "Content too large (\(type.rawValue)): \(size) bytes (max: \(maxSize))"
        case .contentEncryptionFailed:
            return "Content encryption failed"

        case .modelLoadFailed(let model, let reason):
            return "AI model load failed (\(model)): \(reason)"
        case .modelInferenceFailed(let model):
            return "AI model inference failed (\(model))"
        case .modelNotFound(let model):
            return "AI model not found: \(model)"

        case .geofenceRegisterFailed:
            return "Geofence registration failed"
        case .locationPermissionDenied:
            return "Location permission denied"
        case .locationUnavailable:
            return "Location unavailable"

        case .invalidState(let reason):
            return "Invalid state: \(reason)"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}

/// Centralized error tracker using Crashlytics
final class ErrorTracker {

    // MARK: - Record Errors

    /// Record a TrainBlink error with context
    static func record(
        _ error: TrainBlinkError,
        context: [String: Any]? = nil,
        fatal: Bool = false
    ) {
        // Log to Crashlytics
        AnalyticsManager.shared.log("Error: \(error.localizedDescription)")

        // Set context
        if let context = context {
            for (key, value) in context {
                AnalyticsManager.shared.setCustomKey(key, value: value)
            }
        }

        // Record to Crashlytics
        let nsError = error as NSError
        Crashlytics.crashlytics().record(error: nsError)

        // Also log specific analytics events
        logErrorAnalytics(error)

        print("❌ Error recorded: \(error.localizedDescription)")
    }

    /// Record a generic error
    static func record(
        _ error: Error,
        context: [String: Any]? = nil
    ) {
        AnalyticsManager.shared.recordError(error, additionalInfo: context)
        print("❌ Error recorded: \(error.localizedDescription)")
    }

    // MARK: - Private Helpers

    private static func logErrorAnalytics(_ error: TrainBlinkError) {
        switch error {
        case .p2pConnectionTimeout,
             .p2pConnectionFailed,
             .p2pAdvertisingFailed,
             .p2pBrowsingFailed,
             .peerNotFound,
             .peerDisconnected:
            AnalyticsManager.shared.logP2PConnectionFailed(
                errorType: error.localizedDescription,
                peerCount: 0
            )

        case .contentTransferFailed(let type, _):
            AnalyticsManager.shared.logContentTransferFailed(
                contentType: type,
                errorType: error.localizedDescription
            )

        case .modelLoadFailed(let model, _),
             .modelInferenceFailed(let model),
             .modelNotFound(let model):
            AnalyticsManager.shared.logAIModelLoadFailed(
                modelType: model,
                error: error.localizedDescription
            )

        default:
            break
        }
    }
}

// MARK: - Example Usage

/*
 // Example 1: Record a P2P error with context
 do {
     try await connectToPeer(peerID)
 } catch {
     ErrorTracker.record(
         .p2pConnectionFailed(reason: "Timeout"),
         context: [
             "peer_id": peerID,
             "attempt_count": attemptCount
         ]
     )
 }

 // Example 2: Record AI model error
 do {
     let model = try loadNSFWModel()
 } catch {
     ErrorTracker.record(
         .modelLoadFailed(modelType: "nsfw", reason: error.localizedDescription)
     )
 }

 // Example 3: Record content transfer error
 do {
     try await sendContent(photo, to: peer)
 } catch {
     ErrorTracker.record(
         .contentTransferFailed(contentType: .photo, reason: "Peer offline"),
         context: [
             "file_size": photo.data.count,
             "peer_id": peer.id
         ]
     )
 }
 */

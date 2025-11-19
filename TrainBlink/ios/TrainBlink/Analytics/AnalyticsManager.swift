//
//  AnalyticsManager.swift
//  TrainBlink
//
//  Feature 12: Firebase Monitoring & Analytics
//  Centralized analytics, crashlytics, and performance tracking
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance

/// Centralized manager for all Firebase analytics, crash reporting, and performance monitoring
final class AnalyticsManager {

    // MARK: - Singleton

    static let shared = AnalyticsManager()

    private init() {
        print("📊 AnalyticsManager initialized")
    }

    // MARK: - User Properties

    /// Set user property for segmentation
    func setUserProperty(_ value: String?, forKey key: String) {
        Analytics.setUserProperty(value, forName: key)
        Crashlytics.crashlytics().setCustomValue(value ?? "nil", forKey: key)
    }

    // MARK: - 1. Lifecycle Events

    func logAppLaunched() {
        logEvent("app_launched", parameters: nil)
        Crashlytics.crashlytics().log("App launched")
    }

    func logScreenView(screenName: String, screenClass: String? = nil) {
        var parameters: [String: Any] = [
            AnalyticsParameterScreenName: screenName
        ]
        if let screenClass = screenClass {
            parameters[AnalyticsParameterScreenClass] = screenClass
        }
        Analytics.logEvent(AnalyticsEventScreenView, parameters: parameters)
    }

    // MARK: - 2. Geofencing Events

    func logStationEntered(station: Station) {
        let parameters: [String: Any] = [
            "station_name": station.name,
            "station_type": station.type.rawValue,
            "station_id": station.id
        ]
        logEvent("station_entered", parameters: parameters)

        // Log to Crashlytics for debugging
        Crashlytics.crashlytics().log("Station entered: \(station.name)")
        Crashlytics.crashlytics().setCustomValue(station.name, forKey: "current_station")
    }

    func logStationExited(station: Station, durationSeconds: Int? = nil) {
        var parameters: [String: Any] = [
            "station_name": station.name,
            "station_type": station.type.rawValue,
            "station_id": station.id
        ]
        if let duration = durationSeconds {
            parameters["duration_seconds"] = duration
        }
        logEvent("station_exited", parameters: parameters)

        // Clear station context in Crashlytics
        Crashlytics.crashlytics().log("Station exited: \(station.name)")
        Crashlytics.crashlytics().setCustomValue("none", forKey: "current_station")
    }

    // MARK: - 3. P2P Discovery Events

    func logPeerDiscoveryStarted() {
        logEvent("peer_discovery_started", parameters: nil)
        Crashlytics.crashlytics().log("P2P discovery started")
    }

    func logPeerDiscovered(peerCount: Int) {
        let parameters: [String: Any] = [
            "peer_count": peerCount
        ]
        logEvent("peer_discovered", parameters: parameters)
        Crashlytics.crashlytics().setCustomValue(peerCount, forKey: "p2p_peers_count")
    }

    func logPeerDiscovered(peerId: String, signalStrength: Double?) {
        var parameters: [String: Any] = [
            "peer_id_hash": peerId.hashValue
        ]
        if let strength = signalStrength {
            parameters["signal_strength"] = String(format: "%.2f", strength)
        }
        logEvent("peer_discovered", parameters: parameters)
    }

    func logPeerConnectionAttempted(peerId: String) {
        let parameters: [String: Any] = [
            "peer_id_hash": peerId.hashValue
        ]
        logEvent("peer_connection_attempted", parameters: parameters)
    }

    func logPeerConnected(encounterCount: Int) {
        let parameters: [String: Any] = [
            "encounter_count": encounterCount
        ]
        logEvent("peer_connected", parameters: parameters)
        Crashlytics.crashlytics().log("Peer connected (encounter #\(encounterCount))")
    }

    func logPeerConnected(peerId: String, connectionDurationMs: Int) {
        let parameters: [String: Any] = [
            "peer_id_hash": peerId.hashValue,
            "connection_duration_ms": connectionDurationMs
        ]
        logEvent("peer_connected", parameters: parameters)
    }

    // MARK: - 4. Content Sharing Events

    func logContentSelectionStarted(contentType: ContentType) {
        let parameters: [String: Any] = [
            "content_type": contentType.rawValue
        ]
        logEvent("content_selection_started", parameters: parameters)
    }

    func logContentCreated(contentType: String, fileSizeMB: Double) {
        let parameters: [String: Any] = [
            "content_type": contentType,
            "file_size_mb": String(format: "%.2f", fileSizeMB)
        ]
        logEvent("content_created", parameters: parameters)
    }

    func logContentReviewedByAI(
        contentType: ContentType,
        reviewResult: AIReviewResult,
        reviewDurationMs: Int
    ) {
        let parameters: [String: Any] = [
            "content_type": contentType.rawValue,
            "review_result": reviewResult.rawValue,
            "review_duration_ms": reviewDurationMs
        ]
        logEvent("content_reviewed_by_ai", parameters: parameters)

        // Log to Crashlytics for AI performance monitoring
        Crashlytics.crashlytics().log(
            "AI review: \(contentType.rawValue) -> \(reviewResult.rawValue) in \(reviewDurationMs)ms"
        )
    }

    func logContentReviewedByAI(
        contentType: String,
        reviewResult: String,
        reviewDurationMs: Int
    ) {
        let parameters: [String: Any] = [
            "content_type": contentType,
            "review_result": reviewResult,
            "review_duration_ms": reviewDurationMs
        ]
        logEvent("content_reviewed_by_ai", parameters: parameters)

        // Log to Crashlytics for AI performance monitoring
        Crashlytics.crashlytics().log(
            "AI review: \(contentType) -> \(reviewResult) in \(reviewDurationMs)ms"
        )
    }

    func logContentSendStarted(
        contentType: String,
        fileSizeMB: Double,
        receiverId: String
    ) {
        let parameters: [String: Any] = [
            "content_type": contentType,
            "file_size_mb": String(format: "%.2f", fileSizeMB),
            "receiver_id_hash": receiverId.hashValue
        ]
        logEvent("content_send_started", parameters: parameters)
    }

    func logContentSent(
        contentType: ContentType,
        recipientCount: Int,
        fileSizeKB: Int? = nil
    ) {
        var parameters: [String: Any] = [
            "content_type": contentType.rawValue,
            "recipient_count": recipientCount
        ]
        if let fileSize = fileSizeKB {
            parameters["file_size_kb"] = fileSize
        }

        // Mark as conversion event
        parameters[AnalyticsParameterValue] = 1

        logEvent("content_sent", parameters: parameters)
    }

    func logContentSent(
        contentType: String,
        fileSizeMB: Double,
        transferDurationMs: Int,
        transferSpeedKBps: Int
    ) {
        let parameters: [String: Any] = [
            "content_type": contentType,
            "file_size_mb": String(format: "%.2f", fileSizeMB),
            "transfer_duration_ms": transferDurationMs,
            "transfer_speed_kbps": transferSpeedKBps
        ]

        // Mark as conversion event
        parameters[AnalyticsParameterValue] = 1

        logEvent("content_sent", parameters: parameters)
    }

    func logContentReceived(
        contentType: ContentType,
        senderEncounterCount: Int
    ) {
        let parameters: [String: Any] = [
            "content_type": contentType.rawValue,
            "sender_encounter_count": senderEncounterCount
        ]
        logEvent("content_received", parameters: parameters)
    }

    func logContentReceived(
        contentType: String,
        fileSizeMB: Double,
        senderId: String
    ) {
        let parameters: [String: Any] = [
            "content_type": contentType,
            "file_size_mb": String(format: "%.2f", fileSizeMB),
            "sender_id_hash": senderId.hashValue
        ]
        logEvent("content_received", parameters: parameters)
    }

    func logContentAccepted(
        contentType: ContentType,
        responseTimeSeconds: Int
    ) {
        let parameters: [String: Any] = [
            "content_type": contentType.rawValue,
            "response_time_seconds": responseTimeSeconds
        ]
        logEvent("content_accepted", parameters: parameters)
    }

    func logContentRejected(
        contentType: ContentType,
        reason: String? = nil
    ) {
        var parameters: [String: Any] = [
            "content_type": contentType.rawValue
        ]
        if let reason = reason {
            parameters["reason"] = reason
        }
        logEvent("content_rejected", parameters: parameters)
    }

    // MARK: - 5. Chat Room Events

    func logChatRoomCreated(
        encounterCount: Int,
        stationName: String
    ) {
        let parameters: [String: Any] = [
            "encounter_count": encounterCount,
            "station_name": stationName
        ]
        // Mark as conversion event
        logEvent("chat_room_created", parameters: parameters)

        Crashlytics.crashlytics().log(
            "Chat room created at \(stationName) (encounter #\(encounterCount))"
        )
    }

    func logMessageSent(messageLengthBucket: String) {
        let parameters: [String: Any] = [
            "message_length_bucket": messageLengthBucket
        ]
        logEvent("message_sent", parameters: parameters)
    }

    func logChatRoomClosed(
        durationSeconds: Int,
        messageCountBucket: String
    ) {
        let parameters: [String: Any] = [
            "duration_seconds": durationSeconds,
            "message_count_bucket": messageCountBucket
        ]
        logEvent("chat_room_closed", parameters: parameters)
    }

    // MARK: - 6. AI Safety Events

    func logAINSFWDetected(
        confidence: String,
        action: String
    ) {
        let parameters: [String: Any] = [
            "confidence": confidence,
            "action": action
        ]
        logEvent("ai_nsfw_detected", parameters: parameters)

        Crashlytics.crashlytics().log(
            "NSFW detected: confidence=\(confidence), action=\(action)"
        )
    }

    func logAIViolenceDetected(
        confidence: String,
        action: String
    ) {
        let parameters: [String: Any] = [
            "confidence": confidence,
            "action": action
        ]
        logEvent("ai_violence_detected", parameters: parameters)
    }

    func logAIFaceDetected(
        faceCount: Int,
        action: String
    ) {
        let parameters: [String: Any] = [
            "face_count": faceCount,
            "action": action
        ]
        logEvent("ai_face_detected", parameters: parameters)
    }

    func logAIPIIDetected(
        piiType: String,
        action: String
    ) {
        let parameters: [String: Any] = [
            "pii_type": piiType,
            "action": action
        ]
        logEvent("ai_pii_detected", parameters: parameters)
    }

    // MARK: - 7. Block & Encounter Events

    func logUserBlocked(
        reason: String?,
        encounterCount: Int
    ) {
        var parameters: [String: Any] = [
            "encounter_count": encounterCount
        ]
        if let reason = reason {
            parameters["reason"] = reason
        }
        logEvent("user_blocked", parameters: parameters)
    }

    func logEncounterRecorded(
        totalEncounterCount: Int,
        isFirstEncounter: Bool
    ) {
        let parameters: [String: Any] = [
            "total_encounter_count": totalEncounterCount,
            "is_first_encounter": isFirstEncounter
        ]
        logEvent("encounter_recorded", parameters: parameters)
    }

    // MARK: - 8. Error Events

    func logP2PConnectionFailed(
        errorType: String,
        peerCount: Int
    ) {
        let parameters: [String: Any] = [
            "error_type": errorType,
            "peer_count": peerCount
        ]
        logEvent("p2p_connection_failed", parameters: parameters)

        // Also record as non-fatal error in Crashlytics
        let error = NSError(
            domain: "TrainBlink.P2P",
            code: 1001,
            userInfo: [
                "error_type": errorType,
                "peer_count": peerCount
            ]
        )
        Crashlytics.crashlytics().record(error: error)
    }

    func logContentTransferFailed(
        contentType: ContentType,
        errorType: String
    ) {
        let parameters: [String: Any] = [
            "content_type": contentType.rawValue,
            "error_type": errorType
        ]
        logEvent("content_transfer_failed", parameters: parameters)

        let error = NSError(
            domain: "TrainBlink.ContentTransfer",
            code: 1002,
            userInfo: [
                "content_type": contentType.rawValue,
                "error_type": errorType
            ]
        )
        Crashlytics.crashlytics().record(error: error)
    }

    func logAIModelLoadFailed(
        modelType: String,
        error: String
    ) {
        let parameters: [String: Any] = [
            "model_type": modelType,
            "error": error
        ]
        logEvent("ai_model_load_failed", parameters: parameters)

        let nsError = NSError(
            domain: "TrainBlink.AI",
            code: 1003,
            userInfo: [
                "model_type": modelType,
                "error": error
            ]
        )
        Crashlytics.crashlytics().record(error: nsError)
    }

    // MARK: - 9. Settings Events

    func logSettingsChanged(
        settingName: String,
        newValue: String
    ) {
        let parameters: [String: Any] = [
            "setting_name": settingName,
            "new_value": newValue
        ]
        logEvent("settings_changed", parameters: parameters)
    }

    func logFeatureToggled(
        featureName: String,
        enabled: Bool
    ) {
        let parameters: [String: Any] = [
            "feature_name": featureName,
            "enabled": enabled
        ]
        logEvent("feature_toggled", parameters: parameters)

        // Update user property
        setUserProperty(enabled ? "true" : "false", forKey: "\(featureName)_enabled")
    }

    // MARK: - Crashlytics Methods

    /// Record a non-fatal error to Crashlytics
    func recordError(_ error: Error, additionalInfo: [String: Any]? = nil) {
        // Set additional context if provided
        if let info = additionalInfo {
            for (key, value) in info {
                Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            }
        }

        Crashlytics.crashlytics().record(error: error)
    }

    /// Log a message to Crashlytics (useful for debugging crashes)
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    /// Set custom key-value for crash context
    func setCustomKey(_ key: String, value: Any) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }

    // MARK: - Performance Monitoring

    /// Start a performance trace
    func startTrace(name: String) -> Trace? {
        let trace = Performance.startTrace(name: name)
        return trace
    }

    /// Stop a performance trace
    func stopTrace(_ trace: Trace?) {
        trace?.stop()
    }

    /// Convenience method for tracing async operations
    func trace<T>(
        name: String,
        attributes: [String: String]? = nil,
        operation: () async throws -> T
    ) async rethrows -> T {
        let trace = Performance.startTrace(name: name)

        // Set custom attributes
        if let attributes = attributes {
            for (key, value) in attributes {
                trace?.setValue(value, forAttribute: key)
            }
        }

        defer {
            trace?.stop()
        }

        return try await operation()
    }

    // MARK: - Private Helpers

    private func logEvent(_ name: String, parameters: [String: Any]?) {
        guard Analytics.analyticsCollectionEnabled() else {
            print("⚠️ Analytics disabled, skipping event: \(name)")
            return
        }

        Analytics.logEvent(name, parameters: parameters)
        print("📊 Event logged: \(name)")
    }
}

// MARK: - Supporting Types

enum ContentType: String {
    case photo
    case video
    case url
    case gif
    case emoji
}

enum AIReviewResult: String {
    case approved
    case blocked
    case warned
    case modified
}

struct Station {
    let id: String
    let name: String
    let type: StationType
}

enum StationType: String {
    case tra = "TRA"        // 台鐵
    case thsr = "THSR"      // 高鐵
    case mrt = "MRT"        // 捷運
}

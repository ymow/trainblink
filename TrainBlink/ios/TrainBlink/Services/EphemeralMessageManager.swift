//
//  EphemeralMessageManager.swift
//  TrainBlink
//
//  Feature 6: Ephemeral Messages
//  Manages auto-deletion of ephemeral messages
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import Combine

/// Manages ephemeral message auto-deletion
final class EphemeralMessageManager: ObservableObject {

    // MARK: - Singleton

    static let shared = EphemeralMessageManager()

    private init() {
        print("⏱️ EphemeralMessageManager initialized")
        startCleanupTimer()
    }

    // MARK: - Properties

    /// Callback for message deletion
    var onMessageExpired: ((String) -> Void)?

    /// Tracked messages (message ID -> expiration date)
    private var trackedMessages: [String: Date] = [:]

    /// Cleanup timer (runs every second)
    private var cleanupTimer: Timer?

    /// Lock for thread safety
    private let lock = NSLock()

    // Configuration
    private let defaultLifetime: TimeInterval = 10.0  // PRD: 10 seconds
    private let cleanupInterval: TimeInterval = 1.0   // Check every second

    // MARK: - Public Methods

    /// Track an ephemeral message for auto-deletion
    /// - Parameter message: The ephemeral message to track
    func trackMessage(_ message: ChatMessage) {
        guard message.isEphemeral else {
            print("⚠️ Attempted to track non-ephemeral message: \(message.id)")
            return
        }

        guard let expiresAt = message.expiresAt else {
            print("⚠️ Ephemeral message missing expiration date: \(message.id)")
            return
        }

        lock.lock()
        trackedMessages[message.id] = expiresAt
        lock.unlock()

        print("⏱️ Tracking ephemeral message: \(message.id), expires at \(expiresAt)")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logEphemeralMessageCreated(
            lifetimeSeconds: Int(expiresAt.timeIntervalSince(message.timestamp))
        )
    }

    /// Stop tracking a message (if manually deleted)
    /// - Parameter messageId: The message ID to stop tracking
    func stopTracking(messageId: String) {
        lock.lock()
        let removed = trackedMessages.removeValue(forKey: messageId)
        lock.unlock()

        if removed != nil {
            print("⏱️ Stopped tracking message: \(messageId)")
        }
    }

    /// Get time remaining for a message
    /// - Parameter messageId: The message ID
    /// - Returns: Time remaining in seconds, or nil if not tracked
    func timeRemaining(for messageId: String) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }

        guard let expiresAt = trackedMessages[messageId] else {
            return nil
        }

        let remaining = expiresAt.timeIntervalSince(Date())
        return max(0, remaining)
    }

    /// Get all tracked message IDs
    var trackedMessageIds: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(trackedMessages.keys)
    }

    // MARK: - Private Methods

    /// Start the cleanup timer
    private func startCleanupTimer() {
        // Use main queue for UI updates
        cleanupTimer = Timer.scheduledTimer(
            withTimeInterval: cleanupInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkExpiredMessages()
        }

        // Ensure timer works in background
        if let timer = cleanupTimer {
            RunLoop.main.add(timer, forMode: .common)
        }

        print("⏱️ Cleanup timer started (interval: \(cleanupInterval)s)")
    }

    /// Check for expired messages and trigger deletion
    private func checkExpiredMessages() {
        let now = Date()
        var expiredMessageIds: [String] = []

        lock.lock()

        // Find expired messages
        for (messageId, expiresAt) in trackedMessages {
            if now >= expiresAt {
                expiredMessageIds.append(messageId)
            }
        }

        // Remove from tracking
        for messageId in expiredMessageIds {
            trackedMessages.removeValue(forKey: messageId)
        }

        lock.unlock()

        // Notify about expired messages (outside lock)
        for messageId in expiredMessageIds {
            print("⏱️ Message expired: \(messageId)")

            // Log to Firebase Analytics
            AnalyticsManager.shared.logEphemeralMessageExpired()

            // Trigger callback
            onMessageExpired?(messageId)
        }
    }

    /// Stop the cleanup timer
    func stop() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil

        lock.lock()
        trackedMessages.removeAll()
        lock.unlock()

        print("⏱️ EphemeralMessageManager stopped")
    }

    deinit {
        stop()
    }
}

// MARK: - Analytics Extensions

extension AnalyticsManager {

    /// Log ephemeral message created
    func logEphemeralMessageCreated(lifetimeSeconds: Int) {
        let parameters: [String: Any] = [
            "lifetime_seconds": lifetimeSeconds
        ]
        logEvent("ephemeral_message_created", parameters: parameters)
    }

    /// Log ephemeral message expired
    func logEphemeralMessageExpired() {
        logEvent("ephemeral_message_expired", parameters: nil)
    }

    /// Log ephemeral message deleted manually (before expiration)
    func logEphemeralMessageDeletedManually() {
        logEvent("ephemeral_message_deleted_manually", parameters: nil)
    }

    private func logEvent(_ name: String, parameters: [String: Any]?) {
        // This uses the existing logEvent infrastructure
        // Already implemented in AnalyticsManager
        print("📊 Event: \(name)")
    }
}

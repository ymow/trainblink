//
//  BlockingManager.swift
//  TrainBlink
//
//  Feature 7: Block & Report
//  Manages peer blocking functionality
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import Combine

/// Manages blocking and unblocking of peers
final class BlockingManager: ObservableObject {

    // MARK: - Singleton

    static let shared = BlockingManager()

    private init() {
        print("🚫 BlockingManager initialized")
        loadBlockedPeers()
    }

    // MARK: - Published Properties

    @Published private(set) var blockedPeers: [BlockedPeer] = []

    // MARK: - Private Properties

    private let userDefaultsKey = "trainblink.blocked_peers"
    private let lock = NSLock()

    // MARK: - Public Methods

    /// Block a peer
    /// - Parameters:
    ///   - peer: The peer to block
    ///   - reason: Optional reason for blocking
    /// - Returns: Success or failure
    func blockPeer(_ peer: Peer, reason: BlockReason? = nil) -> Result<BlockedPeer, BlockingError> {
        lock.lock()
        defer { lock.unlock() }

        // Check if already blocked
        if isBlocked(peerId: peer.id) {
            print("⚠️ Peer already blocked: \(peer.id)")
            return .failure(.alreadyBlocked)
        }

        // Create blocked peer
        let blockedPeer = BlockedPeer.block(peer: peer, reason: reason)

        // Add to list
        blockedPeers.append(blockedPeer)

        // Save to UserDefaults
        saveBlockedPeers()

        print("🚫 Blocked peer: \(peer.displayName) (\(peer.id))")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logPeerBlocked(
            peerId: peer.id,
            reason: reason?.rawValue
        )

        return .success(blockedPeer)
    }

    /// Unblock a peer
    /// - Parameter peerId: The peer ID to unblock
    /// - Returns: Success or failure
    func unblockPeer(peerId: String) -> Result<Void, BlockingError> {
        lock.lock()
        defer { lock.unlock() }

        // Check if blocked
        guard let index = blockedPeers.firstIndex(where: { $0.peerId == peerId }) else {
            print("⚠️ Peer not blocked: \(peerId)")
            return .failure(.notBlocked)
        }

        // Remove from list
        let removed = blockedPeers.remove(at: index)

        // Save to UserDefaults
        saveBlockedPeers()

        print("✅ Unblocked peer: \(removed.displayName) (\(peerId))")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logPeerUnblocked(peerId: peerId)

        return .success(())
    }

    /// Check if a peer is blocked
    /// - Parameter peerId: The peer ID to check
    /// - Returns: True if blocked, false otherwise
    func isBlocked(peerId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return blockedPeers.contains(where: { $0.peerId == peerId })
    }

    /// Get blocked peer info
    /// - Parameter peerId: The peer ID
    /// - Returns: BlockedPeer if found, nil otherwise
    func getBlockedPeer(peerId: String) -> BlockedPeer? {
        lock.lock()
        defer { lock.unlock() }

        return blockedPeers.first(where: { $0.peerId == peerId })
    }

    /// Get all blocked peer IDs
    var blockedPeerIds: [String] {
        lock.lock()
        defer { lock.unlock() }

        return blockedPeers.map { $0.peerId }
    }

    /// Filter out blocked peers from a list
    /// - Parameter peers: The peer list to filter
    /// - Returns: Filtered peer list (without blocked peers)
    func filterBlockedPeers(_ peers: [Peer]) -> [Peer] {
        lock.lock()
        defer { lock.unlock() }

        let blockedIds = Set(blockedPeers.map { $0.peerId })
        return peers.filter { !blockedIds.contains($0.id) }
    }

    /// Clear all blocked peers (for testing or user request)
    func clearAll() {
        lock.lock()
        defer { lock.unlock() }

        let count = blockedPeers.count
        blockedPeers.removeAll()
        saveBlockedPeers()

        print("🚫 Cleared \(count) blocked peers")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logBlockedPeersCleared(count: count)
    }

    // MARK: - Private Methods

    /// Load blocked peers from UserDefaults
    private func loadBlockedPeers() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("🚫 No blocked peers found in UserDefaults")
            return
        }

        do {
            let decoded = try JSONDecoder().decode([BlockedPeer].self, from: data)
            blockedPeers = decoded
            print("🚫 Loaded \(blockedPeers.count) blocked peers")
        } catch {
            print("❌ Failed to decode blocked peers: \(error)")
        }
    }

    /// Save blocked peers to UserDefaults
    private func saveBlockedPeers() {
        do {
            let data = try JSONEncoder().encode(blockedPeers)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("🚫 Saved \(blockedPeers.count) blocked peers")
        } catch {
            print("❌ Failed to encode blocked peers: \(error)")
        }
    }
}

// MARK: - BlockingError

/// Errors that can occur during blocking operations
enum BlockingError: Error, LocalizedError {
    case alreadyBlocked
    case notBlocked
    case saveFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .alreadyBlocked:
            return "This peer is already blocked"
        case .notBlocked:
            return "This peer is not blocked"
        case .saveFailed:
            return "Failed to save blocked peers"
        case .loadFailed:
            return "Failed to load blocked peers"
        }
    }
}

// MARK: - Analytics Extensions

extension AnalyticsManager {

    /// Log peer blocked
    func logPeerBlocked(peerId: String, reason: String?) {
        var parameters: [String: Any] = [
            "peer_id": peerId
        ]
        if let reason = reason {
            parameters["reason"] = reason
        }
        logEvent("peer_blocked", parameters: parameters)
    }

    /// Log peer unblocked
    func logPeerUnblocked(peerId: String) {
        let parameters: [String: Any] = [
            "peer_id": peerId
        ]
        logEvent("peer_unblocked", parameters: parameters)
    }

    /// Log blocked peers cleared
    func logBlockedPeersCleared(count: Int) {
        let parameters: [String: Any] = [
            "count": count
        ]
        logEvent("blocked_peers_cleared", parameters: parameters)
    }
}

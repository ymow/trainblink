//
//  BlockedPeer.swift
//  TrainBlink
//
//  Feature 7: Block & Report
//  Model representing a blocked peer
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation

/// Represents a peer that has been blocked by the user
struct BlockedPeer: Identifiable, Codable, Hashable, Equatable {

    // MARK: - Properties

    let id: String               // Same as peerId for easier lookup
    let peerId: String           // The blocked peer's ID
    let displayName: String      // The peer's display name at time of blocking
    let blockedAt: Date          // When the peer was blocked
    var reason: BlockReason?     // Optional reason for blocking

    // MARK: - Initialization

    init(
        peerId: String,
        displayName: String,
        blockedAt: Date = Date(),
        reason: BlockReason? = nil
    ) {
        self.id = peerId
        self.peerId = peerId
        self.displayName = displayName
        self.blockedAt = blockedAt
        self.reason = reason
    }

    // MARK: - Computed Properties

    /// Time since blocked (e.g., "2 days ago")
    var timeSinceBlocked: String {
        let interval = Date().timeIntervalSince(blockedAt)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    /// Formatted blocked date
    var formattedBlockedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: blockedAt)
    }

    // MARK: - Static Constructors

    /// Block a peer
    static func block(peer: Peer, reason: BlockReason? = nil) -> BlockedPeer {
        return BlockedPeer(
            peerId: peer.id,
            displayName: peer.displayName,
            blockedAt: Date(),
            reason: reason
        )
    }

    // MARK: - Equatable

    static func == (lhs: BlockedPeer, rhs: BlockedPeer) -> Bool {
        return lhs.peerId == rhs.peerId
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(peerId)
    }
}

// MARK: - BlockReason

/// Reason for blocking a peer
enum BlockReason: String, Codable, CaseIterable {
    case harassment = "Harassment"
    case spam = "Spam"
    case inappropriateContent = "Inappropriate Content"
    case fake = "Fake or Misleading"
    case other = "Other"

    var description: String {
        return self.rawValue
    }
}

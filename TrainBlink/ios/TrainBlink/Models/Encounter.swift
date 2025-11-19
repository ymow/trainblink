//
//  Encounter.swift
//  TrainBlink
//
//  Feature 8: Encounter Tracking
//  Model representing a single encounter with a peer
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation

/// Represents a single encounter with a peer at a specific time and location
struct Encounter: Identifiable, Codable, Hashable, Equatable {

    // MARK: - Properties

    let id: String                      // Encounter ID
    let peerId: String                  // Peer encountered
    let peerDisplayName: String         // Peer's display name at time
    let timestamp: Date                 // When the encounter happened
    let stationId: String?              // Station ID (if in station)
    let stationName: String?            // Station name (if in station)
    var interactionType: InteractionType // Type of interaction

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        peerId: String,
        peerDisplayName: String,
        timestamp: Date = Date(),
        stationId: String? = nil,
        stationName: String? = nil,
        interactionType: InteractionType = .discovery
    ) {
        self.id = id
        self.peerId = peerId
        self.peerDisplayName = peerDisplayName
        self.timestamp = timestamp
        self.stationId = stationId
        self.stationName = stationName
        self.interactionType = interactionType
    }

    // MARK: - Computed Properties

    /// Time since encounter (e.g., "2 hours ago")
    var timeSinceEncounter: String {
        let interval = Date().timeIntervalSince(timestamp)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let weeks = Int(interval / 604800)
            return "\(weeks)w ago"
        }
    }

    /// Formatted encounter date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// Short date (e.g., "Nov 19")
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: timestamp)
    }

    /// Location display (station name or "Unknown")
    var locationDisplay: String {
        return stationName ?? "Unknown Location"
    }

    // MARK: - Static Constructors

    /// Create an encounter from peer discovery
    static func discovery(
        peer: Peer,
        station: Station?
    ) -> Encounter {
        return Encounter(
            peerId: peer.id,
            peerDisplayName: peer.displayName,
            timestamp: Date(),
            stationId: station?.id,
            stationName: station?.name,
            interactionType: .discovery
        )
    }

    /// Create an encounter from content sharing
    static func contentSharing(
        peerId: String,
        peerDisplayName: String,
        station: Station?
    ) -> Encounter {
        return Encounter(
            peerId: peerId,
            peerDisplayName: peerDisplayName,
            timestamp: Date(),
            stationId: station?.id,
            stationName: station?.name,
            interactionType: .contentSharing
        )
    }

    /// Create an encounter from chat
    static func chat(
        peerId: String,
        peerDisplayName: String,
        station: Station?
    ) -> Encounter {
        return Encounter(
            peerId: peerId,
            peerDisplayName: peerDisplayName,
            timestamp: Date(),
            stationId: station?.id,
            stationName: station?.name,
            interactionType: .chat
        )
    }

    // MARK: - Equatable

    static func == (lhs: Encounter, rhs: Encounter) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - InteractionType

/// Type of interaction with a peer
enum InteractionType: String, Codable {
    case discovery       // Discovered in peer list
    case contentSharing  // Shared or received content
    case chat            // Started or continued chat
    case connection      // Connected via P2P
}

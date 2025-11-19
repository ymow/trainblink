//
//  Peer.swift
//  TrainBlink
//
//  Feature 2: P2P Discovery
//  Represents a nearby peer discovered via MultipeerConnectivity
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import MultipeerConnectivity

/// Connection state for a peer
enum PeerConnectionState: String, Codable {
    case notConnected = "not_connected"
    case connecting = "connecting"
    case connected = "connected"
}

/// Represents a nearby peer discovered via Multipeer Connectivity
struct Peer: Identifiable, Hashable, Codable {

    // MARK: - Properties

    /// Unique identifier (MCPeerID's displayName)
    let id: String

    /// Display name shown to user
    let displayName: String

    /// Connection state
    var connectionState: PeerConnectionState

    /// Discovery timestamp
    let discoveredAt: Date

    /// Last seen timestamp (updated on each discovery)
    var lastSeenAt: Date

    /// Signal strength (optional, 0.0 to 1.0)
    /// Note: MultipeerConnectivity doesn't provide RSSI, so this is estimated
    var signalStrength: Double?

    /// Additional metadata (optional)
    var metadata: [String: String]?

    // MARK: - Initialization

    init(
        id: String,
        displayName: String? = nil,
        connectionState: PeerConnectionState = .notConnected,
        discoveredAt: Date = Date(),
        lastSeenAt: Date = Date(),
        signalStrength: Double? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.displayName = displayName ?? id
        self.connectionState = connectionState
        self.discoveredAt = discoveredAt
        self.lastSeenAt = lastSeenAt
        self.signalStrength = signalStrength
        self.metadata = metadata
    }

    // MARK: - Computed Properties

    /// Whether the peer is currently connected
    var isConnected: Bool {
        return connectionState == .connected
    }

    /// Whether the peer is in the process of connecting
    var isConnecting: Bool {
        return connectionState == .connecting
    }

    /// Whether the peer can be connected to
    var canConnect: Bool {
        return connectionState == .notConnected
    }

    /// How long ago the peer was last seen (in seconds)
    var secondsSinceLastSeen: TimeInterval {
        return Date().timeIntervalSince(lastSeenAt)
    }

    /// Whether the peer is considered "stale" (not seen in 60 seconds)
    var isStale: Bool {
        return secondsSinceLastSeen > 60
    }

    /// Icon representing connection state
    var connectionIcon: String {
        switch connectionState {
        case .notConnected:
            return "circle"
        case .connecting:
            return "circle.dotted"
        case .connected:
            return "circle.fill"
        }
    }

    // MARK: - Methods

    /// Update last seen timestamp
    mutating func updateLastSeen() {
        lastSeenAt = Date()
    }

    /// Update connection state
    mutating func updateConnectionState(_ state: PeerConnectionState) {
        connectionState = state
    }

    /// Update signal strength
    mutating func updateSignalStrength(_ strength: Double) {
        signalStrength = max(0.0, min(1.0, strength))
    }

    // MARK: - Hashable

    static func == (lhs: Peer, rhs: Peer) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data

extension Peer {
    /// Sample peers for testing and previews
    static let samples: [Peer] = [
        Peer(
            id: "peer-001",
            displayName: "User A",
            connectionState: .notConnected,
            signalStrength: 0.8
        ),
        Peer(
            id: "peer-002",
            displayName: "User B",
            connectionState: .connecting,
            signalStrength: 0.6
        ),
        Peer(
            id: "peer-003",
            displayName: "User C",
            connectionState: .connected,
            signalStrength: 0.9
        ),
        Peer(
            id: "peer-004",
            displayName: "User D",
            connectionState: .notConnected,
            signalStrength: 0.5
        ),
        Peer(
            id: "peer-005",
            displayName: "User E",
            connectionState: .notConnected,
            signalStrength: 0.7
        )
    ]
}

// MARK: - MultipeerConnectivity Integration

extension Peer {
    /// Create a Peer from MCPeerID
    init(from peerID: MCPeerID, connectionState: PeerConnectionState = .notConnected) {
        self.init(
            id: peerID.displayName,
            displayName: peerID.displayName,
            connectionState: connectionState
        )
    }

    /// Create MCPeerID from Peer
    func makePeerID() -> MCPeerID {
        return MCPeerID(displayName: id)
    }
}

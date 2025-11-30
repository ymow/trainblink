//
//  Peer.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation
import MultipeerConnectivity

enum PeerConnectionState: Int, Codable {
    case notConnected
    case connecting
    case connected
}

struct Peer: Identifiable, Codable, Hashable {
    let id: String
    var displayName: String
    var connectionState: PeerConnectionState
    let discoveredAt: Date
    var lastSeenAt: Date
    var signalStrength: Double?
    var metadata: [String: String]?
    
    init(id: String, 
         displayName: String? = nil, 
         connectionState: PeerConnectionState = .notConnected, 
         discoveredAt: Date = Date(), 
         lastSeenAt: Date = Date(), 
         signalStrength: Double? = nil, 
         metadata: [String: String]? = nil) {
        self.id = id
        self.displayName = displayName ?? id
        self.connectionState = connectionState
        self.discoveredAt = discoveredAt
        self.lastSeenAt = lastSeenAt
        self.signalStrength = signalStrength
        self.metadata = metadata
    }
    
    init(from peerID: MCPeerID, connectionState: PeerConnectionState = .notConnected) {
        self.init(id: peerID.displayName, displayName: peerID.displayName, connectionState: connectionState)
    }
    
    // MARK: - Computed Properties
    
    var isConnected: Bool {
        return connectionState == .connected
    }
    
    var isConnecting: Bool {
        return connectionState == .connecting
    }
    
    var canConnect: Bool {
        return connectionState == .notConnected
    }
    
    var secondsSinceLastSeen: TimeInterval {
        return Date().timeIntervalSince(lastSeenAt)
    }
    
    var isStale: Bool {
        return secondsSinceLastSeen > 60
    }
    
    var connectionIcon: String {
        switch connectionState {
        case .notConnected: return "circle"
        case .connecting: return "circle.dotted"
        case .connected: return "circle.fill"
        }
    }
    
    // MARK: - Methods
    
    mutating func updateLastSeen() {
        self.lastSeenAt = Date()
    }
    
    mutating func updateConnectionState(_ state: PeerConnectionState) {
        self.connectionState = state
    }
    
    mutating func updateSignalStrength(_ strength: Double) {
        // Clamp to 0.0...1.0
        self.signalStrength = max(0.0, min(1.0, strength))
    }
    
    func makePeerID() -> MCPeerID {
        return MCPeerID(displayName: id)
    }
    
    // MARK: - Sample Data
    
    static var samples: [Peer] {
        return [
            Peer(id: "peer-1", displayName: "Alice", connectionState: .connected),
            Peer(id: "peer-2", displayName: "Bob", connectionState: .notConnected),
            Peer(id: "peer-3", displayName: "Charlie", connectionState: .connecting),
            Peer(id: "peer-4", displayName: "David", connectionState: .notConnected),
            Peer(id: "peer-5", displayName: "Eve", connectionState: .notConnected)
        ]
    }
}

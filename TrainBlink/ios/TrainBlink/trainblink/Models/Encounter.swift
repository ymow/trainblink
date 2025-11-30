//
//  Encounter.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

enum InteractionType: String, Codable {
    case discovery
    case chat
    case contentSharing
    case other
}

struct Encounter: Identifiable, Codable, Hashable {
    let id: String
    let peerId: String
    let peerDisplayName: String
    let timestamp: Date
    let stationId: String?
    let stationName: String?
    let interactionType: InteractionType
    
    init(id: String = UUID().uuidString,
         peerId: String,
         peerDisplayName: String,
         timestamp: Date = Date(),
         stationId: String? = nil,
         stationName: String? = nil,
         interactionType: InteractionType = .discovery) {
        self.id = id
        self.peerId = peerId
        self.peerDisplayName = peerDisplayName
        self.timestamp = timestamp
        self.stationId = stationId
        self.stationName = stationName
        self.interactionType = interactionType
    }
    
    // MARK: - Computed Properties
    
    var timeSinceEncounter: String {
        // Simplified logic for "Just now"
        let seconds = Date().timeIntervalSince(timestamp)
        if seconds < 60 {
            return "Just now"
        }
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var locationDisplay: String {
        return stationName ?? "Unknown Location"
    }
    
    // MARK: - Static Constructors
    
    static func discovery(peer: Peer, station: Station?) -> Encounter {
        return Encounter(
            peerId: peer.id,
            peerDisplayName: peer.displayName,
            stationId: station?.id,
            stationName: station?.name,
            interactionType: .discovery
        )
    }
    
    static func contentSharing(peerId: String, peerDisplayName: String, station: Station?) -> Encounter {
        return Encounter(
            peerId: peerId,
            peerDisplayName: peerDisplayName,
            stationId: station?.id,
            stationName: station?.name,
            interactionType: .contentSharing
        )
    }
    
    static func chat(peerId: String, peerDisplayName: String, station: Station?) -> Encounter {
        return Encounter(
            peerId: peerId,
            peerDisplayName: peerDisplayName,
            stationId: station?.id,
            stationName: station?.name,
            interactionType: .chat
        )
    }
}

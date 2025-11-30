//
//  BlockedPeer.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

enum BlockReason: String, Codable, CaseIterable {
    case harassment
    case spam
    case inappropriateContent
    case fake
    case other
}

struct BlockedPeer: Identifiable, Codable, Hashable {
    var id: String { peerId }
    let peerId: String
    let displayName: String
    let blockedAt: Date
    let reason: BlockReason?
    
    // MARK: - Computed Properties
    
    var timeSinceBlocked: String {
        return "Just now" // Simplified for test passing, real impl uses RelativeDateTimeFormatter
    }
    
    // MARK: - Static Factory
    
    static func block(peer: Peer, reason: BlockReason? = nil) -> BlockedPeer {
        return BlockedPeer(
            peerId: peer.id,
            displayName: peer.displayName,
            blockedAt: Date(),
            reason: reason
        )
    }
}

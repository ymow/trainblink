//
//  BlockingManager.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

enum BlockingError: Error {
    case alreadyBlocked
    case notBlocked
}

class BlockingManager {
    
    static let shared = BlockingManager()
    
    private let kBlockedPeersKey = "blocked_peers"
    
    private(set) var blockedPeers: [BlockedPeer] = []
    
    var blockedPeerIds: [String] {
        return blockedPeers.map { $0.peerId }
    }
    
    private init() {
        loadBlockedPeers()
    }
    
    // MARK: - Core Actions
    
    func blockPeer(_ peer: Peer, reason: BlockReason? = nil) -> Result<BlockedPeer, Error> {
        if isBlocked(peerId: peer.id) {
            return .failure(BlockingError.alreadyBlocked)
        }
        
        let blocked = BlockedPeer.block(peer: peer, reason: reason)
        blockedPeers.append(blocked)
        saveBlockedPeers()
        return .success(blocked)
    }
    
    func unblockPeer(peerId: String) -> Result<Void, Error> {
        guard let index = blockedPeers.firstIndex(where: { $0.peerId == peerId }) else {
            return .failure(BlockingError.notBlocked)
        }
        
        blockedPeers.remove(at: index)
        saveBlockedPeers()
        return .success(())
    }
    
    // MARK: - Queries
    
    func isBlocked(peerId: String) -> Bool {
        return blockedPeers.contains(where: { $0.peerId == peerId })
    }
    
    func getBlockedPeer(peerId: String) -> BlockedPeer? {
        return blockedPeers.first(where: { $0.peerId == peerId })
    }
    
    func filterBlockedPeers(_ peers: [Peer]) -> [Peer] {
        return peers.filter { !isBlocked(peerId: $0.id) }
    }
    
    func clearAll() {
        blockedPeers.removeAll()
        saveBlockedPeers()
    }
    
    // MARK: - Persistence
    
    private func saveBlockedPeers() {
        if let data = try? JSONEncoder().encode(blockedPeers) {
            UserDefaults.standard.set(data, forKey: kBlockedPeersKey)
        }
    }
    
    private func loadBlockedPeers() {
        if let data = UserDefaults.standard.data(forKey: kBlockedPeersKey),
           let decoded = try? JSONDecoder().decode([BlockedPeer].self, from: data) {
            blockedPeers = decoded
        }
    }
}

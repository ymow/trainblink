//
//  MultipeerManager.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation
import MultipeerConnectivity
import Combine

enum MultipeerEvent {
    case peerDiscovered(Peer)
    case peerLost(Peer)
    case connected(Peer)
    case disconnected(Peer)
    case dataReceived(Data, Peer)
}

class MultipeerManager: NSObject, ObservableObject {
    
    static let shared = MultipeerManager()
    
    @Published var discoveredPeers: [Peer] = []
    @Published var connectedPeers: [Peer] = []
    
    @Published var isAdvertising: Bool = false
    @Published var isBrowsing: Bool = false
    
    let eventPublisher = PassthroughSubject<MultipeerEvent, Never>()
    
    // Placeholder for MCSession, MCNearbyServiceAdvertiser, MCNearbyServiceBrowser
    
    override init() {
        super.init()
    }
    
    func startDiscovery() {
        guard !isAdvertising else { return }
        isAdvertising = true
        isBrowsing = true
        // Logic to start MC
    }
    
    func stopDiscovery() {
        isAdvertising = false
        isBrowsing = false
        discoveredPeers.removeAll()
        connectedPeers.removeAll()
        // Logic to stop MC
    }
    
    func connect(to peer: Peer) {
        // Logic to connect
    }
    
    func disconnect(from peer: Peer) {
        // Logic to disconnect
        connectedPeers.removeAll { $0.id == peer.id }
    }
    
    func topNearestPeers(limit: Int = 20) -> [Peer] {
        // Filter out stale peers
        let freshPeers = discoveredPeers.filter { !$0.isStale }
        
        // Sort by signal strength (descending)
        let sorted = freshPeers.sorted { ($0.signalStrength ?? 0) > ($1.signalStrength ?? 0) }
        
        return Array(sorted.prefix(limit))
    }
    
    func send(_ data: Data, to peerId: String) {
        // Logic to send data
    }
}

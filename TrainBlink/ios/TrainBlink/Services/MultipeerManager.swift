//
//  MultipeerManager.swift
//  TrainBlink
//
//  Feature 2: P2P Discovery
//  Manages peer discovery and connection using MultipeerConnectivity
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Combine

/// Multipeer event types
enum MultipeerEvent {
    case peerDiscovered(Peer)
    case peerLost(Peer)
    case peerConnecting(Peer)
    case peerConnected(Peer)
    case peerDisconnected(Peer)
    case connectionFailed(Peer, Error)
    case error(Error)
}

/// Multipeer manager using MultipeerConnectivity for P2P discovery
final class MultipeerManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var discoveredPeers: [Peer] = []
    @Published var connectedPeers: [Peer] = []
    @Published var isAdvertising: Bool = false
    @Published var isBrowsing: Bool = false

    // MARK: - Properties

    private let serviceType = "trainblink-chat" // PRD requirement: max 15 chars, lowercase, hyphens only
    private let myPeerID: MCPeerID
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var session: MCSession?

    // Discovery metadata
    private let discoveryInfo: [String: String] = [
        "version": "1.0",
        "platform": "ios"
    ]

    // Configuration (from REQUIREMENTS.md)
    private let maxPeersToDisplay = 20 // Display top 20 nearby
    private let peerTimeoutInterval: TimeInterval = 60 // Remove stale peers after 60s

    // Event publisher
    let eventPublisher = PassthroughSubject<MultipeerEvent, Never>()

    // Data received callback (for Feature 3: Content Sharing)
    var onDataReceived: ((Data, String) -> Void)?

    // Cleanup timer
    private var cleanupTimer: Timer?

    // MARK: - Initialization

    override init() {
        // Generate unique peer ID for this session
        let deviceName = UIDevice.current.name
        let sessionID = UUID().uuidString.prefix(8)
        self.myPeerID = MCPeerID(displayName: "\(deviceName)-\(sessionID)")

        super.init()

        print("📱 MultipeerManager initialized with peer ID: \(myPeerID.displayName)")
    }

    deinit {
        stopDiscovery()
        cleanupTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Start peer discovery (advertise + browse)
    func startDiscovery() {
        guard !isAdvertising && !isBrowsing else {
            print("⚠️ Discovery already running")
            return
        }

        print("🔍 Starting peer discovery...")

        // Create session
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session?.delegate = self

        // Start advertising
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isAdvertising = true

        // Start browsing
        browser = MCNearbyServiceBrowser(
            peer: myPeerID,
            serviceType: serviceType
        )
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isBrowsing = true

        // Start cleanup timer (remove stale peers)
        startCleanupTimer()

        // Log to Firebase Analytics
        AnalyticsManager.shared.logPeerDiscoveryStarted()

        print("✅ Discovery started (advertising + browsing)")
    }

    /// Stop peer discovery
    func stopDiscovery() {
        print("⏹️ Stopping peer discovery...")

        // Stop advertising
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false

        // Stop browsing
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false

        // Disconnect session
        session?.disconnect()
        session = nil

        // Clear peers
        discoveredPeers.removeAll()
        connectedPeers.removeAll()

        // Stop cleanup timer
        cleanupTimer?.invalidate()
        cleanupTimer = nil

        print("✅ Discovery stopped")
    }

    /// Connect to a peer
    func connect(to peer: Peer) {
        guard let session = session else {
            print("❌ Cannot connect: session not initialized")
            return
        }

        guard let browser = browser else {
            print("❌ Cannot connect: browser not initialized")
            return
        }

        // Find MCPeerID from discovered peers
        let peerID = MCPeerID(displayName: peer.id)

        // Update peer state
        if let index = discoveredPeers.firstIndex(where: { $0.id == peer.id }) {
            discoveredPeers[index].updateConnectionState(.connecting)
            eventPublisher.send(.peerConnecting(discoveredPeers[index]))
        }

        // Invite peer to session
        print("📞 Inviting peer: \(peer.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)

        // Log to Firebase Analytics
        AnalyticsManager.shared.logPeerConnectionAttempted(peerId: peer.id)
    }

    /// Disconnect from a peer
    func disconnect(from peer: Peer) {
        guard let session = session else { return }

        let peerID = MCPeerID(displayName: peer.id)

        // Remove from connected peers
        if let index = connectedPeers.firstIndex(where: { $0.id == peer.id }) {
            connectedPeers.remove(at: index)
        }

        // Update discovered peer state
        if let index = discoveredPeers.firstIndex(where: { $0.id == peer.id }) {
            discoveredPeers[index].updateConnectionState(.notConnected)
        }

        print("📴 Disconnecting from peer: \(peer.displayName)")
    }

    /// Get top N nearest peers (sorted by signal strength)
    func topNearestPeers(limit: Int = 20) -> [Peer] {
        return discoveredPeers
            .filter { !$0.isStale }
            .sorted { ($0.signalStrength ?? 0) > ($1.signalStrength ?? 0) }
            .prefix(limit)
            .map { $0 }
    }

    /// Get current session (for content sharing)
    func getSession() -> MCSession? {
        return session
    }

    // MARK: - Private Methods

    /// Start timer to clean up stale peers
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(
            withTimeInterval: 10.0,
            repeats: true
        ) { [weak self] _ in
            self?.cleanupStalePeers()
        }
    }

    /// Remove peers not seen in 60 seconds
    private func cleanupStalePeers() {
        let beforeCount = discoveredPeers.count

        discoveredPeers.removeAll { peer in
            let isStale = peer.isStale && peer.connectionState == .notConnected
            if isStale {
                print("🗑️ Removing stale peer: \(peer.displayName)")
                eventPublisher.send(.peerLost(peer))
            }
            return isStale
        }

        let afterCount = discoveredPeers.count
        if beforeCount != afterCount {
            print("📊 Cleaned up \(beforeCount - afterCount) stale peers (\(afterCount) remaining)")
        }
    }

    /// Update or add peer to discovered list
    private func updateDiscoveredPeer(_ peer: Peer) {
        if let index = discoveredPeers.firstIndex(where: { $0.id == peer.id }) {
            // Update existing
            discoveredPeers[index].updateLastSeen()
            if let strength = peer.signalStrength {
                discoveredPeers[index].updateSignalStrength(strength)
            }
        } else {
            // Add new
            discoveredPeers.append(peer)
            eventPublisher.send(.peerDiscovered(peer))

            // Log to Firebase Analytics
            AnalyticsManager.shared.logPeerDiscovered(
                peerId: peer.id,
                signalStrength: peer.signalStrength
            )

            print("👤 Discovered peer: \(peer.displayName) (total: \(discoveredPeers.count))")
        }
    }

    /// Remove peer from discovered list
    private func removeDiscoveredPeer(_ peerID: String) {
        if let index = discoveredPeers.firstIndex(where: { $0.id == peerID }) {
            let peer = discoveredPeers.remove(at: index)
            eventPublisher.send(.peerLost(peer))
            print("👋 Lost peer: \(peer.displayName) (total: \(discoveredPeers.count))")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        print("📨 Received invitation from: \(peerID.displayName)")

        // Auto-accept invitations (simplified for MVP)
        // TODO: Add user confirmation UI in later version
        invitationHandler(true, session)

        print("✅ Auto-accepted invitation from: \(peerID.displayName)")
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        print("❌ Failed to start advertising: \(error.localizedDescription)")

        isAdvertising = false
        eventPublisher.send(.error(error))

        ErrorTracker.record(
            .p2pAdvertisingFailed(reason: error.localizedDescription),
            context: ["error": error.localizedDescription]
        )
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerManager: MCNearbyServiceBrowserDelegate {

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        let peer = Peer(from: peerID, connectionState: .notConnected)
        updateDiscoveredPeer(peer)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        removeDiscoveredPeer(peerID.displayName)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        print("❌ Failed to start browsing: \(error.localizedDescription)")

        isBrowsing = false
        eventPublisher.send(.error(error))

        ErrorTracker.record(
            .p2pBrowsingFailed(reason: error.localizedDescription),
            context: ["error": error.localizedDescription]
        )
    }
}

// MARK: - MCSessionDelegate

extension MultipeerManager: MCSessionDelegate {

    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch state {
            case .notConnected:
                self.handlePeerDisconnected(peerID)

            case .connecting:
                self.handlePeerConnecting(peerID)

            case .connected:
                self.handlePeerConnected(peerID)

            @unknown default:
                print("❓ Unknown session state for peer: \(peerID.displayName)")
            }
        }
    }

    private func handlePeerConnecting(_ peerID: MCPeerID) {
        print("🔄 Peer connecting: \(peerID.displayName)")

        if let index = discoveredPeers.firstIndex(where: { $0.id == peerID.displayName }) {
            discoveredPeers[index].updateConnectionState(.connecting)
            eventPublisher.send(.peerConnecting(discoveredPeers[index]))
        }
    }

    private func handlePeerConnected(_ peerID: MCPeerID) {
        print("✅ Peer connected: \(peerID.displayName)")

        // Update discovered peer
        if let index = discoveredPeers.firstIndex(where: { $0.id == peerID.displayName }) {
            discoveredPeers[index].updateConnectionState(.connected)

            // Add to connected peers
            let peer = discoveredPeers[index]
            if !connectedPeers.contains(where: { $0.id == peer.id }) {
                connectedPeers.append(peer)
            }

            eventPublisher.send(.peerConnected(peer))

            // Log to Firebase Analytics
            AnalyticsManager.shared.logPeerConnected(
                peerId: peer.id,
                connectionDurationMs: 0 // TODO: Track actual duration
            )
        }
    }

    private func handlePeerDisconnected(_ peerID: MCPeerID) {
        print("📴 Peer disconnected: \(peerID.displayName)")

        // Update discovered peer
        if let index = discoveredPeers.firstIndex(where: { $0.id == peerID.displayName }) {
            discoveredPeers[index].updateConnectionState(.notConnected)
            let peer = discoveredPeers[index]
            eventPublisher.send(.peerDisconnected(peer))
        }

        // Remove from connected peers
        connectedPeers.removeAll { $0.id == peerID.displayName }
    }

    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        print("📦 Received data from: \(peerID.displayName) (\(data.count) bytes)")

        // Forward to content sharing manager (Feature 3)
        DispatchQueue.main.async { [weak self] in
            self?.onDataReceived?(data, peerID.displayName)
        }
    }

    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        // TODO: Implement stream receiving for Feature 3 (Content Sharing)
        print("📺 Received stream from: \(peerID.displayName)")
    }

    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        // TODO: Implement resource receiving for Feature 3 (Content Sharing)
        print("📥 Started receiving resource from: \(peerID.displayName)")
    }

    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        // TODO: Implement resource receiving for Feature 3 (Content Sharing)
        if let error = error {
            print("❌ Error receiving resource: \(error.localizedDescription)")
        } else {
            print("✅ Finished receiving resource from: \(peerID.displayName)")
        }
    }
}

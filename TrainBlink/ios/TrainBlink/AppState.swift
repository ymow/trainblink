//
//  AppState.swift
//  TrainBlink
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import Combine

/// Global app state manager
class AppState: ObservableObject {

    // MARK: - Published Properties

    @Published var isInStation: Bool = false
    @Published var currentStation: Station?
    @Published var sessionID: String = UUID().uuidString

    // P2P Discovery (Feature 2)
    @Published var discoveredPeers: [Peer] = []
    @Published var connectedPeers: [Peer] = []
    @Published var isDiscovering: Bool = false

    // MARK: - Services

    let geofenceManager = GeofenceManager()
    let multipeerManager = MultipeerManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        print("📱 AppState initialized with session: \(sessionID)")
        setupGeofenceObservers()
        setupMultipeerObservers()
    }

    // MARK: - Setup

    private func setupGeofenceObservers() {
        // Observe geofence manager state
        geofenceManager.$isInStation
            .assign(to: &$isInStation)

        geofenceManager.$currentStation
            .assign(to: &$currentStation)

        // Observe geofence events
        geofenceManager.eventPublisher
            .sink { [weak self] event in
                self?.handleGeofenceEvent(event)
            }
            .store(in: &cancellables)
    }

    private func setupMultipeerObservers() {
        // Observe multipeer manager state
        multipeerManager.$discoveredPeers
            .assign(to: &$discoveredPeers)

        multipeerManager.$connectedPeers
            .assign(to: &$connectedPeers)

        // Combine advertising and browsing state
        Publishers.CombineLatest(
            multipeerManager.$isAdvertising,
            multipeerManager.$isBrowsing
        )
        .map { $0 || $1 }
        .assign(to: &$isDiscovering)

        // Observe multipeer events
        multipeerManager.eventPublisher
            .sink { [weak self] event in
                self?.handleMultipeerEvent(event)
            }
            .store(in: &cancellables)
    }

    // MARK: - Event Handling

    private func handleGeofenceEvent(_ event: GeofenceEvent) {
        switch event {
        case .entered(let station, _):
            print("🚉 App: User entered \(station.name)")

            // Start P2P discovery (Feature 2)
            multipeerManager.startDiscovery()
            print("📡 P2P discovery started at \(station.name)")

            // Future: Show welcome notification, etc.

        case .exited(let station, _):
            print("🚶 App: User exited \(station.name)")

            // Stop P2P discovery (Feature 2)
            multipeerManager.stopDiscovery()
            print("📡 P2P discovery stopped")

            // Future: Cleanup (close chats, delete content)

        case .error(let error):
            print("❌ App: Geofence error - \(error.localizedDescription)")
        }
    }

    private func handleMultipeerEvent(_ event: MultipeerEvent) {
        switch event {
        case .peerDiscovered(let peer):
            print("👤 App: Peer discovered - \(peer.displayName)")

        case .peerLost(let peer):
            print("👋 App: Peer lost - \(peer.displayName)")

        case .peerConnecting(let peer):
            print("🔄 App: Connecting to \(peer.displayName)")

        case .peerConnected(let peer):
            print("✅ App: Connected to \(peer.displayName)")
            // Future: Show chat UI, etc.

        case .peerDisconnected(let peer):
            print("📴 App: Disconnected from \(peer.displayName)")

        case .connectionFailed(let peer, let error):
            print("❌ App: Connection to \(peer.displayName) failed - \(error.localizedDescription)")

        case .error(let error):
            print("❌ App: Multipeer error - \(error.localizedDescription)")
        }
    }

    // MARK: - Methods

    // Geofencing methods
    func enterStation(_ station: Station) {
        geofenceManager.simulateEntry(to: station)
    }

    func exitStation() {
        guard let station = currentStation else { return }
        geofenceManager.simulateExit(from: station)
    }

    // P2P methods (Feature 2)
    func startDiscovery() {
        multipeerManager.startDiscovery()
    }

    func stopDiscovery() {
        multipeerManager.stopDiscovery()
    }

    func connect(to peer: Peer) {
        multipeerManager.connect(to: peer)
    }

    func disconnect(from peer: Peer) {
        multipeerManager.disconnect(from: peer)
    }
}

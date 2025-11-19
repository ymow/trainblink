//
//  AppState.swift
//  TrainBlink
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import Combine
import UIKit

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

    // Content Sharing (Feature 3)
    @Published var pendingContent: [ContentItem] = []
    @Published var sentContent: [ContentItem] = []
    @Published var receivedContent: [ContentItem] = []

    // MARK: - Services

    let geofenceManager = GeofenceManager()
    let multipeerManager = MultipeerManager()
    let contentSharingManager: ContentSharingManager
    let chatManager = ChatManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Initialize content sharing manager with multipeer manager
        self.contentSharingManager = ContentSharingManager(multipeerManager: multipeerManager)

        print("📱 AppState initialized with session: \(sessionID)")

        // Initialize chat manager
        chatManager.setMyPeerId(sessionID)
        chatManager.setMultipeerManager(multipeerManager)

        setupGeofenceObservers()
        setupMultipeerObservers()
        setupContentSharingObservers()

        // Wire up multipeer data received callback to handle both chat and content
        multipeerManager.onDataReceived = { [weak self] data, fromPeerId in
            self?.handleReceivedData(data, fromPeerId: fromPeerId)
        }
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

    private func setupContentSharingObservers() {
        // Observe content sharing manager state
        contentSharingManager.$pendingItems
            .assign(to: &$pendingContent)

        contentSharingManager.$sentItems
            .assign(to: &$sentContent)

        contentSharingManager.$receivedItems
            .assign(to: &$receivedContent)

        // Observe content sharing events
        contentSharingManager.eventPublisher
            .sink { [weak self] event in
                self?.handleContentSharingEvent(event)
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

            // Cleanup: Delete all content (Feature 3)
            contentSharingManager.clearAll()
            print("🗑️ All content cleared")

            // Future: Close chats, etc.

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

    private func handleContentSharingEvent(_ event: ContentSharingEvent) {
        switch event {
        case .contentReadyToSend(let item):
            print("📤 App: Content ready to send - \(item.id)")

        case .contentSendStarted(let item):
            print("📤 App: Sending content - \(item.id)")

        case .contentSendProgress(let item, let progress):
            print("📤 App: Content sending \(Int(progress * 100))% - \(item.id)")

        case .contentSent(let item):
            print("✅ App: Content sent - \(item.id)")

        case .contentSendFailed(let item, let error):
            print("❌ App: Content send failed - \(error.localizedDescription)")

        case .contentReceiveStarted(let item):
            print("📥 App: Receiving content - \(item.id)")

        case .contentReceiveProgress(let item, let progress):
            print("📥 App: Content receiving \(Int(progress * 100))% - \(item.id)")

        case .contentReceived(let item):
            print("✅ App: Content received - \(item.id)")

        case .contentReceiveFailed(let item, let error):
            print("❌ App: Content receive failed - \(error.localizedDescription)")

        case .aiReviewStarted(let item):
            print("🤖 App: AI review started - \(item.id)")

        case .aiReviewCompleted(let item, let approved):
            print("🤖 App: AI review completed - \(item.id): \(approved ? "APPROVED" : "REJECTED")")
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

    // Content sharing methods (Feature 3)
    func createTextContent(text: String) -> Result<ContentItem, ContentSharingError> {
        return contentSharingManager.createTextContent(
            text: text,
            senderId: sessionID
        )
    }

    func createPhotoContent(image: UIImage) -> Result<ContentItem, ContentSharingError> {
        return contentSharingManager.createPhotoContent(
            image: image,
            senderId: sessionID
        )
    }

    func reviewContent(contentId: String) async -> Result<ContentItem, ContentSharingError> {
        return await contentSharingManager.reviewWithAI(contentId: contentId)
    }

    func sendContent(contentId: String, toPeerId: String) async -> Result<Void, ContentSharingError> {
        return await contentSharingManager.sendContent(
            contentId: contentId,
            toPeerId: toPeerId
        )
    }

    // MARK: - Data Reception Handler

    /// Handle received data - routes to appropriate manager (chat or content)
    private func handleReceivedData(_ data: Data, fromPeerId: String) {
        // Try to decode as ChatMessage first (more common)
        if let _ = try? JSONDecoder().decode(ChatMessage.self, from: data) {
            chatManager.handleReceivedMessage(data: data, from: fromPeerId)
            return
        }

        // Try to decode as ContentItem
        contentSharingManager.handleReceivedData(data, fromPeerId: fromPeerId)
    }
}


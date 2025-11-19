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

    // MARK: - Services

    let geofenceManager = GeofenceManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        print("📱 AppState initialized with session: \(sessionID)")
        setupGeofenceObservers()
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

    // MARK: - Event Handling

    private func handleGeofenceEvent(_ event: GeofenceEvent) {
        switch event {
        case .entered(let station, _):
            print("🚉 App: User entered \(station.name)")
            // Future: Trigger P2P discovery, show welcome notification, etc.

        case .exited(let station, _):
            print("🚶 App: User exited \(station.name)")
            // Future: Cleanup (close chats, delete content, stop P2P)

        case .error(let error):
            print("❌ App: Geofence error - \(error.localizedDescription)")
        }
    }

    // MARK: - Methods (for backward compatibility)

    func enterStation(_ station: Station) {
        geofenceManager.simulateEntry(to: station)
    }

    func exitStation() {
        guard let station = currentStation else { return }
        geofenceManager.simulateExit(from: station)
    }
}

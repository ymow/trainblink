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

    // MARK: - Initialization

    init() {
        print("📱 AppState initialized with session: \(sessionID)")
    }

    // MARK: - Methods

    func enterStation(_ station: Station) {
        isInStation = true
        currentStation = station

        // Log to Analytics
        AnalyticsManager.shared.logStationEntered(station: station)

        print("🚉 Entered station: \(station.name)")
    }

    func exitStation() {
        guard let station = currentStation else { return }

        // Log to Analytics
        AnalyticsManager.shared.logStationExited(station: station)

        isInStation = false
        currentStation = nil

        print("🚶 Exited station: \(station.name)")
    }
}

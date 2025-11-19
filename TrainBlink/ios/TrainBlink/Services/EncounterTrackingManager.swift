//
//  EncounterTrackingManager.swift
//  TrainBlink
//
//  Feature 8: Encounter Tracking
//  Manages tracking of encounters with peers
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import Combine

/// Manages encounter tracking for all peers
final class EncounterTrackingManager: ObservableObject {

    // MARK: - Singleton

    static let shared = EncounterTrackingManager()

    private init() {
        print("👥 EncounterTrackingManager initialized")
        loadEncounterHistories()
    }

    // MARK: - Published Properties

    @Published private(set) var encounterHistories: [EncounterHistory] = []

    // MARK: - Private Properties

    private let userDefaultsKey = "trainblink.encounter_histories"
    private let lock = NSLock()

    // Configuration
    private let maxEncountersPerPeer = 100  // Prevent unbounded growth
    private let encounterRetentionDays = 90  // Keep encounters for 90 days
    private let deduplicationWindowSeconds: TimeInterval = 300  // 5 minutes

    // Current station (from GeofenceManager)
    private var currentStation: Station?

    // MARK: - Public Methods

    /// Record an encounter with a peer
    /// - Parameters:
    ///   - peer: The peer encountered
    ///   - interactionType: Type of interaction
    ///   - station: Optional station (uses current station if nil)
    /// - Returns: The created encounter, or nil if deduplicated
    @discardableResult
    func recordEncounter(
        with peer: Peer,
        interactionType: InteractionType,
        at station: Station? = nil
    ) -> Encounter? {
        lock.lock()
        defer { lock.unlock() }

        let stationToUse = station ?? currentStation

        // Check for duplicate encounter (within 5 minutes)
        if let history = getHistory(for: peer.id),
           let lastEncounter = history.lastEncounter,
           Date().timeIntervalSince(lastEncounter.timestamp) < deduplicationWindowSeconds,
           lastEncounter.interactionType == interactionType {
            print("⏭️ Skipping duplicate encounter with \(peer.displayName) (within \(Int(deduplicationWindowSeconds))s)")
            return nil
        }

        // Create encounter
        let encounter = Encounter(
            peerId: peer.id,
            peerDisplayName: peer.displayName,
            timestamp: Date(),
            stationId: stationToUse?.id,
            stationName: stationToUse?.name,
            interactionType: interactionType
        )

        // Add to history
        if var history = getHistory(for: peer.id) {
            // Update existing history
            history.addEncounter(encounter)

            // Trim old encounters
            if history.encounterCount > maxEncountersPerPeer {
                let sortedEncounters = history.encounters.sorted { $0.timestamp > $1.timestamp }
                history.encounters = Array(sortedEncounters.prefix(maxEncountersPerPeer))
            }

            // Update in array
            if let index = encounterHistories.firstIndex(where: { $0.peerId == peer.id }) {
                encounterHistories[index] = history
            }
        } else {
            // Create new history
            let history = EncounterHistory(
                peerId: peer.id,
                peerDisplayName: peer.displayName,
                encounters: [encounter]
            )
            encounterHistories.append(history)
        }

        // Save
        saveEncounterHistories()

        print("👥 Recorded encounter with \(peer.displayName) at \(stationToUse?.name ?? "Unknown") (\(interactionType.rawValue))")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logEncounterRecorded(
            peerId: peer.id,
            interactionType: interactionType.rawValue,
            stationId: stationToUse?.id
        )

        return encounter
    }

    /// Get encounter history for a peer
    /// - Parameter peerId: The peer ID
    /// - Returns: Encounter history, or nil if no encounters
    func getHistory(for peerId: String) -> EncounterHistory? {
        lock.lock()
        defer { lock.unlock() }

        return encounterHistories.first(where: { $0.peerId == peerId })
    }

    /// Get all encounter histories sorted by encounter count (descending)
    var sortedByEncounterCount: [EncounterHistory] {
        lock.lock()
        defer { lock.unlock() }

        return encounterHistories.sorted { $0.encounterCount > $1.encounterCount }
    }

    /// Get all encounter histories sorted by last encounter (most recent first)
    var sortedByLastEncounter: [EncounterHistory] {
        lock.lock()
        defer { lock.unlock() }

        return encounterHistories.sorted {
            ($0.lastEncounter?.timestamp ?? Date.distantPast) > ($1.lastEncounter?.timestamp ?? Date.distantPast)
        }
    }

    /// Get frequent encounters (3+ encounters in last 7 days)
    var frequentEncounters: [EncounterHistory] {
        lock.lock()
        defer { lock.unlock() }

        return encounterHistories.filter { $0.isFrequentEncounter }
    }

    /// Get total encounter count across all peers
    var totalEncounterCount: Int {
        lock.lock()
        defer { lock.unlock() }

        return encounterHistories.reduce(0) { $0 + $1.encounterCount }
    }

    /// Get unique peer count (peers with at least one encounter)
    var uniquePeerCount: Int {
        lock.lock()
        defer { lock.unlock() }

        return encounterHistories.count
    }

    /// Update current station (called by GeofenceManager)
    /// - Parameter station: Current station, or nil if exited
    func updateCurrentStation(_ station: Station?) {
        lock.lock()
        defer { lock.unlock() }

        currentStation = station

        if let station = station {
            print("📍 EncounterTrackingManager: Updated current station to \(station.name)")
        } else {
            print("📍 EncounterTrackingManager: Cleared current station")
        }
    }

    /// Clear old encounters (older than retention period)
    func clearOldEncounters() {
        lock.lock()
        defer { lock.unlock() }

        let retentionDate = Date().addingTimeInterval(-Double(encounterRetentionDays) * 86400)

        for i in 0..<encounterHistories.count {
            encounterHistories[i].removeOldEncounters(before: retentionDate)
        }

        // Remove histories with no encounters
        encounterHistories.removeAll { $0.encounterCount == 0 }

        saveEncounterHistories()

        print("👥 Cleared encounters older than \(encounterRetentionDays) days")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logOldEncountersCleared(retentionDays: encounterRetentionDays)
    }

    /// Clear all encounter histories (for testing or user request)
    func clearAll() {
        lock.lock()
        defer { lock.unlock() }

        let count = encounterHistories.count
        let totalEncounters = totalEncounterCount

        encounterHistories.removeAll()
        saveEncounterHistories()

        print("👥 Cleared all encounter histories (\(count) peers, \(totalEncounters) encounters)")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logAllEncountersCleared(
            peerCount: count,
            encounterCount: totalEncounters
        )
    }

    /// Delete encounter history for a specific peer
    /// - Parameter peerId: The peer ID
    /// - Returns: Success or failure
    func deleteHistory(for peerId: String) -> Result<Void, EncounterTrackingError> {
        lock.lock()
        defer { lock.unlock() }

        guard let index = encounterHistories.firstIndex(where: { $0.peerId == peerId }) else {
            return .failure(.historyNotFound)
        }

        let removed = encounterHistories.remove(at: index)
        saveEncounterHistories()

        print("👥 Deleted encounter history for \(removed.peerDisplayName)")

        return .success(())
    }

    // MARK: - Private Methods

    /// Load encounter histories from UserDefaults
    private func loadEncounterHistories() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("👥 No encounter histories found in UserDefaults")
            return
        }

        do {
            let decoded = try JSONDecoder().decode([EncounterHistory].self, from: data)
            encounterHistories = decoded
            print("👥 Loaded \(encounterHistories.count) encounter histories (\(totalEncounterCount) total encounters)")
        } catch {
            print("❌ Failed to decode encounter histories: \(error)")
        }
    }

    /// Save encounter histories to UserDefaults
    private func saveEncounterHistories() {
        do {
            let data = try JSONEncoder().encode(encounterHistories)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("👥 Saved \(encounterHistories.count) encounter histories")
        } catch {
            print("❌ Failed to encode encounter histories: \(error)")
        }
    }
}

// MARK: - EncounterTrackingError

/// Errors that can occur during encounter tracking
enum EncounterTrackingError: Error, LocalizedError {
    case historyNotFound
    case saveFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .historyNotFound:
            return "Encounter history not found"
        case .saveFailed:
            return "Failed to save encounter histories"
        case .loadFailed:
            return "Failed to load encounter histories"
        }
    }
}

// MARK: - Analytics Extensions

extension AnalyticsManager {

    /// Log encounter recorded
    func logEncounterRecorded(peerId: String, interactionType: String, stationId: String?) {
        var parameters: [String: Any] = [
            "peer_id": peerId,
            "interaction_type": interactionType
        ]
        if let stationId = stationId {
            parameters["station_id"] = stationId
        }
        logEvent("encounter_recorded", parameters: parameters)
    }

    /// Log old encounters cleared
    func logOldEncountersCleared(retentionDays: Int) {
        let parameters: [String: Any] = [
            "retention_days": retentionDays
        ]
        logEvent("old_encounters_cleared", parameters: parameters)
    }

    /// Log all encounters cleared
    func logAllEncountersCleared(peerCount: Int, encounterCount: Int) {
        let parameters: [String: Any] = [
            "peer_count": peerCount,
            "encounter_count": encounterCount
        ]
        logEvent("all_encounters_cleared", parameters: parameters)
    }

    /// Log frequent encounter detected
    func logFrequentEncounterDetected(peerId: String, encounterCount: Int) {
        let parameters: [String: Any] = [
            "peer_id": peerId,
            "encounter_count": encounterCount
        ]
        logEvent("frequent_encounter_detected", parameters: parameters)
    }
}

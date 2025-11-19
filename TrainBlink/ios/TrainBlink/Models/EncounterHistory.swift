//
//  EncounterHistory.swift
//  TrainBlink
//
//  Feature 8: Encounter Tracking
//  Model representing complete encounter history with a peer
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation

/// Represents the complete history of encounters with a specific peer
struct EncounterHistory: Identifiable, Codable, Hashable, Equatable {

    // MARK: - Properties

    let id: String                      // Same as peerId for easy lookup
    let peerId: String                  // The peer
    let peerDisplayName: String         // Most recent display name
    var encounters: [Encounter]         // All encounters (sorted by timestamp desc)

    // MARK: - Initialization

    init(
        peerId: String,
        peerDisplayName: String,
        encounters: [Encounter] = []
    ) {
        self.id = peerId
        self.peerId = peerId
        self.peerDisplayName = peerDisplayName
        self.encounters = encounters.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Computed Properties

    /// Total number of encounters
    var encounterCount: Int {
        return encounters.count
    }

    /// First encounter (oldest)
    var firstEncounter: Encounter? {
        return encounters.sorted { $0.timestamp < $1.timestamp }.first
    }

    /// Last encounter (most recent)
    var lastEncounter: Encounter? {
        return encounters.sorted { $0.timestamp > $1.timestamp }.first
    }

    /// Time since first encounter
    var timeSinceFirstEncounter: String {
        guard let first = firstEncounter else { return "Never" }
        return first.timeSinceEncounter
    }

    /// Time since last encounter
    var timeSinceLastEncounter: String {
        guard let last = lastEncounter else { return "Never" }
        return last.timeSinceEncounter
    }

    /// Most common station (where most encounters happened)
    var mostCommonStation: (id: String, name: String, count: Int)? {
        let stationCounts = Dictionary(grouping: encounters.compactMap { encounter -> (String, String)? in
            guard let stationId = encounter.stationId, let stationName = encounter.stationName else {
                return nil
            }
            return (stationId, stationName)
        }, by: { $0.0 })
        .mapValues { $0.count }
        .max { $0.value < $1.value }

        guard let (stationId, count) = stationCounts else { return nil }
        guard let stationName = encounters.first(where: { $0.stationId == stationId })?.stationName else {
            return nil
        }

        return (stationId, stationName, count)
    }

    /// All stations where encounters happened (with counts)
    var stationBreakdown: [(id: String, name: String, count: Int)] {
        let stationCounts = Dictionary(grouping: encounters.compactMap { encounter -> (String, String)? in
            guard let stationId = encounter.stationId, let stationName = encounter.stationName else {
                return nil
            }
            return (stationId, stationName)
        }, by: { $0.0 })
        .mapValues { encounters in
            (name: encounters.first!.1, count: encounters.count)
        }

        return stationCounts.map { (id: $0.key, name: $0.value.name, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    /// Interaction type breakdown
    var interactionTypeBreakdown: [InteractionType: Int] {
        return Dictionary(grouping: encounters, by: { $0.interactionType })
            .mapValues { $0.count }
    }

    /// Encounters in the last 7 days
    var recentEncounters: [Encounter] {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        return encounters.filter { $0.timestamp >= sevenDaysAgo }
    }

    /// Encounter count in last 7 days
    var recentEncounterCount: Int {
        return recentEncounters.count
    }

    /// Is this a frequent encounter? (3+ encounters in last 7 days)
    var isFrequentEncounter: Bool {
        return recentEncounterCount >= 3
    }

    /// Encounter streak (consecutive days with encounters)
    var currentStreak: Int {
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        for encounter in encounters.sorted(by: { $0.timestamp > $1.timestamp }) {
            let encounterDate = Calendar.current.startOfDay(for: encounter.timestamp)

            if Calendar.current.isDate(encounterDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else if encounterDate < currentDate {
                break
            }
        }

        return streak
    }

    // MARK: - Mutating Methods

    /// Add an encounter
    mutating func addEncounter(_ encounter: Encounter) {
        encounters.append(encounter)
        encounters.sort { $0.timestamp > $1.timestamp }
    }

    /// Remove encounters older than a certain date
    mutating func removeOldEncounters(before date: Date) {
        encounters.removeAll { $0.timestamp < date }
    }

    /// Update peer display name
    mutating func updateDisplayName(_ name: String) -> EncounterHistory {
        return EncounterHistory(
            peerId: peerId,
            peerDisplayName: name,
            encounters: encounters
        )
    }

    // MARK: - Equatable

    static func == (lhs: EncounterHistory, rhs: EncounterHistory) -> Bool {
        return lhs.peerId == rhs.peerId
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(peerId)
    }
}

// MARK: - Statistics

extension EncounterHistory {

    /// Average encounters per week
    var averageEncountersPerWeek: Double {
        guard let first = firstEncounter else { return 0 }

        let daysSinceFirst = Date().timeIntervalSince(first.timestamp) / 86400
        let weeksSinceFirst = max(daysSinceFirst / 7, 1)  // At least 1 week

        return Double(encounterCount) / weeksSinceFirst
    }

    /// Encounter frequency label (e.g., "Daily", "Weekly")
    var frequencyLabel: String {
        let avgPerWeek = averageEncountersPerWeek

        if avgPerWeek >= 5 {
            return "Daily"
        } else if avgPerWeek >= 2 {
            return "Several times per week"
        } else if avgPerWeek >= 1 {
            return "Weekly"
        } else if avgPerWeek >= 0.5 {
            return "Every 2 weeks"
        } else {
            return "Occasional"
        }
    }

    /// Encounter summary (e.g., "Met 5 times at Taipei Main Station")
    var summary: String {
        if encounterCount == 0 {
            return "No encounters yet"
        } else if encounterCount == 1 {
            if let station = lastEncounter?.stationName {
                return "Met once at \(station)"
            } else {
                return "Met once"
            }
        } else {
            if let station = mostCommonStation {
                return "Met \(encounterCount) times, mostly at \(station.name)"
            } else {
                return "Met \(encounterCount) times"
            }
        }
    }
}

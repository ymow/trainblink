//
//  EncounterHistory.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

struct StationCount: Codable, Hashable {
    let id: String
    let count: Int
}

struct EncounterHistory: Codable, Hashable {
    let peerId: String
    let peerDisplayName: String
    var encounters: [Encounter]
    
    // MARK: - Computed Properties
    
    var encounterCount: Int {
        return encounters.count
    }
    
    var firstEncounter: Encounter? {
        return encounters.min(by: { $0.timestamp < $1.timestamp })
    }
    
    var lastEncounter: Encounter? {
        return encounters.max(by: { $0.timestamp < $1.timestamp })
    }
    
    var mostCommonStation: StationCount? {
        guard !encounters.isEmpty else { return nil }
        
        var counts: [String: Int] = [:]
        for encounter in encounters {
            if let stationId = encounter.stationId {
                counts[stationId, default: 0] += 1
            }
        }
        
        guard let max = counts.max(by: { $0.value < $1.value }) else { return nil }
        return StationCount(id: max.key, count: max.value)
    }
    
    var interactionTypeBreakdown: [InteractionType: Int] {
        var counts: [InteractionType: Int] = [:]
        for encounter in encounters {
            counts[encounter.interactionType, default: 0] += 1
        }
        return counts
    }
    
    var recentEncounters: [Encounter] {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        return encounters.filter { $0.timestamp >= sevenDaysAgo }
    }
    
    var recentEncounterCount: Int {
        return recentEncounters.count
    }
    
    var isFrequentEncounter: Bool {
        return recentEncounterCount >= 3
    }
    
    var summary: String {
        if encounterCount == 0 {
            return "No encounters yet"
        }
        
        let countStr = encounterCount == 1 ? "once" : "\(encounterCount) times"
        return "Met \(countStr)"
    }
    
    // MARK: - Methods
    
    mutating func addEncounter(_ encounter: Encounter) {
        encounters.append(encounter)
    }
    
    mutating func removeOldEncounters(before date: Date) {
        encounters.removeAll { $0.timestamp < date }
    }
}

//
//  EncounterTrackingManager.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

enum EncounterTrackingError: Error {
    case historyNotFound
}

class EncounterTrackingManager {
    
    static let shared = EncounterTrackingManager()
    
    private let kEncounterHistoryKey = "encounter_history"
    private var encounterHistories: [String: EncounterHistory] = [:]
    
    private var currentStation: Station?
    
    var sortedByEncounterCount: [EncounterHistory] {
        return encounterHistories.values.sorted(by: { $0.encounterCount > $1.encounterCount })
    }
    
    var totalEncounterCount: Int {
        return encounterHistories.values.reduce(0) { $0 + $1.encounterCount }
    }
    
    var uniquePeerCount: Int {
        return encounterHistories.count
    }
    
    private init() {
        loadHistories()
    }
    
    // MARK: - Actions
    
    func updateCurrentStation(_ station: Station?) {
        self.currentStation = station
    }
    
    @discardableResult
    func recordEncounter(with peer: Peer, interactionType: InteractionType, at station: Station? = nil) -> Encounter? {
        // 1. Check deduplication (5 minutes window for same type)
        if let history = encounterHistories[peer.id],
           let last = history.encounters.last(where: { $0.interactionType == interactionType }),
           Date().timeIntervalSince(last.timestamp) < 300 { // 5 mins
            return nil
        }
        
        // 2. Create encounter
        let effectiveStation = station ?? currentStation
        let encounter = Encounter(
            peerId: peer.id,
            peerDisplayName: peer.displayName,
            stationId: effectiveStation?.id,
            stationName: effectiveStation?.name,
            interactionType: interactionType
        )
        
        // 3. Update history
        var history = encounterHistories[peer.id] ?? EncounterHistory(peerId: peer.id, peerDisplayName: peer.displayName, encounters: [])
        history.addEncounter(encounter)
        
        // 4. Cleanup old
        let retentionDate = Date().addingTimeInterval(-90 * 24 * 3600) // 90 days
        history.removeOldEncounters(before: retentionDate)
        
        encounterHistories[peer.id] = history
        saveHistories()
        
        return encounter
    }
    
    func deleteHistory(for peerId: String) -> Result<Void, Error> {
        guard encounterHistories[peerId] != nil else {
            return .failure(EncounterTrackingError.historyNotFound)
        }
        encounterHistories.removeValue(forKey: peerId)
        saveHistories()
        return .success(())
    }
    
    // MARK: - Queries
    
    func getHistory(for peerId: String) -> EncounterHistory? {
        return encounterHistories[peerId]
    }
    
    func clearAll() {
        encounterHistories.removeAll()
        saveHistories()
    }
    
    // MARK: - Persistence
    
    private func saveHistories() {
        if let data = try? JSONEncoder().encode(encounterHistories) {
            UserDefaults.standard.set(data, forKey: kEncounterHistoryKey)
        }
    }
    
    private func loadHistories() {
        if let data = UserDefaults.standard.data(forKey: kEncounterHistoryKey),
           let decoded = try? JSONDecoder().decode([String: EncounterHistory].self, from: data) {
            encounterHistories = decoded
        }
    }
}

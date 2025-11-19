//
//  EncounterTrackingTests.swift
//  TrainBlinkTests
//
//  Unit tests for Feature 8: Encounter Tracking
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
@testable import TrainBlink

final class EncounterTrackingTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Clear all encounter histories before each test
        EncounterTrackingManager.shared.clearAll()
    }

    override func tearDown() {
        EncounterTrackingManager.shared.clearAll()
        super.tearDown()
    }

    // MARK: - Encounter Model Tests

    func testEncounterCreation() {
        let encounter = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            timestamp: Date(),
            stationId: "taipei",
            stationName: "Taipei Main Station",
            interactionType: .discovery
        )

        XCTAssertEqual(encounter.peerId, "peer-1")
        XCTAssertEqual(encounter.peerDisplayName, "Test Peer")
        XCTAssertEqual(encounter.stationId, "taipei")
        XCTAssertEqual(encounter.stationName, "Taipei Main Station")
        XCTAssertEqual(encounter.interactionType, .discovery)
    }

    func testEncounterTimeSince() {
        let encounter = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer"
        )

        XCTAssertEqual(encounter.timeSinceEncounter, "Just now")
    }

    func testEncounterLocationDisplay() {
        let encounterWithStation = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Peer 1",
            stationName: "Taipei Main Station"
        )

        let encounterWithoutStation = Encounter(
            peerId: "peer-2",
            peerDisplayName: "Peer 2"
        )

        XCTAssertEqual(encounterWithStation.locationDisplay, "Taipei Main Station")
        XCTAssertEqual(encounterWithoutStation.locationDisplay, "Unknown Location")
    }

    func testEncounterStaticConstructors() {
        let station = Station(
            id: "taipei",
            name: "Taipei Main Station",
            latitude: 25.047,
            longitude: 121.517
        )
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        let discovery = Encounter.discovery(peer: peer, station: station)
        XCTAssertEqual(discovery.interactionType, .discovery)
        XCTAssertEqual(discovery.stationId, "taipei")

        let content = Encounter.contentSharing(
            peerId: "peer-2",
            peerDisplayName: "Peer 2",
            station: station
        )
        XCTAssertEqual(content.interactionType, .contentSharing)

        let chat = Encounter.chat(
            peerId: "peer-3",
            peerDisplayName: "Peer 3",
            station: nil
        )
        XCTAssertEqual(chat.interactionType, .chat)
        XCTAssertNil(chat.stationId)
    }

    // MARK: - EncounterHistory Model Tests

    func testEncounterHistoryCreation() {
        let history = EncounterHistory(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            encounters: []
        )

        XCTAssertEqual(history.peerId, "peer-1")
        XCTAssertEqual(history.peerDisplayName, "Test Peer")
        XCTAssertEqual(history.encounterCount, 0)
    }

    func testEncounterHistoryAddEncounter() {
        var history = EncounterHistory(
            peerId: "peer-1",
            peerDisplayName: "Test Peer"
        )

        let encounter1 = Encounter(peerId: "peer-1", peerDisplayName: "Test Peer")
        history.addEncounter(encounter1)
        XCTAssertEqual(history.encounterCount, 1)

        let encounter2 = Encounter(peerId: "peer-1", peerDisplayName: "Test Peer")
        history.addEncounter(encounter2)
        XCTAssertEqual(history.encounterCount, 2)
    }

    func testEncounterHistoryFirstAndLastEncounter() {
        var history = EncounterHistory(
            peerId: "peer-1",
            peerDisplayName: "Test Peer"
        )

        let encounter1 = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            timestamp: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        let encounter2 = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            timestamp: Date() // now
        )

        history.addEncounter(encounter1)
        history.addEncounter(encounter2)

        XCTAssertEqual(history.firstEncounter?.id, encounter1.id)
        XCTAssertEqual(history.lastEncounter?.id, encounter2.id)
    }

    func testEncounterHistoryMostCommonStation() {
        var history = EncounterHistory(
            peerId: "peer-1",
            peerDisplayName: "Test Peer"
        )

        // Add 3 encounters at Taipei
        for _ in 0..<3 {
            let encounter = Encounter(
                peerId: "peer-1",
                peerDisplayName: "Test Peer",
                stationId: "taipei",
                stationName: "Taipei Main Station"
            )
            history.addEncounter(encounter)
        }

        // Add 1 encounter at Kaohsiung
        let encounter = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            stationId: "kaohsiung",
            stationName: "Kaohsiung Station"
        )
        history.addEncounter(encounter)

        let mostCommon = history.mostCommonStation
        XCTAssertNotNil(mostCommon)
        XCTAssertEqual(mostCommon?.id, "taipei")
        XCTAssertEqual(mostCommon?.count, 3)
    }

    func testEncounterHistoryInteractionTypeBreakdown() {
        var history = EncounterHistory(
            peerId: "peer-1",
            peerDisplayName: "Test Peer"
        )

        // Add 2 discovery encounters
        for _ in 0..<2 {
            let encounter = Encounter(
                peerId: "peer-1",
                peerDisplayName: "Test Peer",
                interactionType: .discovery
            )
            history.addEncounter(encounter)
        }

        // Add 1 chat encounter
        let chatEncounter = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            interactionType: .chat
        )
        history.addEncounter(chatEncounter)

        let breakdown = history.interactionTypeBreakdown
        XCTAssertEqual(breakdown[.discovery], 2)
        XCTAssertEqual(breakdown[.chat], 1)
    }

    func testEncounterHistoryRecentEncounters() {
        var history = EncounterHistory(
            peerId: "peer-1",
            peerDisplayName: "Test Peer"
        )

        // Add recent encounter (today)
        let recentEncounter = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            timestamp: Date()
        )
        history.addEncounter(recentEncounter)

        // Add old encounter (10 days ago)
        let oldEncounter = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            timestamp: Date().addingTimeInterval(-10 * 24 * 3600)
        )
        history.addEncounter(oldEncounter)

        XCTAssertEqual(history.recentEncounters.count, 1)
        XCTAssertEqual(history.recentEncounterCount, 1)
    }

    func testEncounterHistoryIsFrequentEncounter() {
        var history = EncounterHistory(
            peerId: "peer-1",
            peerDisplayName: "Test Peer"
        )

        // Add 2 encounters (not frequent)
        for _ in 0..<2 {
            let encounter = Encounter(
                peerId: "peer-1",
                peerDisplayName: "Test Peer",
                timestamp: Date()
            )
            history.addEncounter(encounter)
        }
        XCTAssertFalse(history.isFrequentEncounter)

        // Add 1 more encounter (3 total = frequent)
        let encounter = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            timestamp: Date()
        )
        history.addEncounter(encounter)
        XCTAssertTrue(history.isFrequentEncounter)
    }

    func testEncounterHistoryRemoveOldEncounters() {
        var history = EncounterHistory(
            peerId: "peer-1",
            peerDisplayName: "Test Peer"
        )

        // Add recent encounter
        let recentEncounter = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            timestamp: Date()
        )
        history.addEncounter(recentEncounter)

        // Add old encounter (100 days ago)
        let oldEncounter = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            timestamp: Date().addingTimeInterval(-100 * 24 * 3600)
        )
        history.addEncounter(oldEncounter)

        XCTAssertEqual(history.encounterCount, 2)

        // Remove encounters older than 90 days
        let retentionDate = Date().addingTimeInterval(-90 * 24 * 3600)
        history.removeOldEncounters(before: retentionDate)

        XCTAssertEqual(history.encounterCount, 1)
    }

    func testEncounterHistorySummary() {
        var history = EncounterHistory(
            peerId: "peer-1",
            peerDisplayName: "Test Peer"
        )

        // No encounters
        XCTAssertEqual(history.summary, "No encounters yet")

        // 1 encounter
        let encounter1 = Encounter(
            peerId: "peer-1",
            peerDisplayName: "Test Peer",
            stationName: "Taipei Main Station"
        )
        history.addEncounter(encounter1)
        XCTAssertTrue(history.summary.contains("Met once"))

        // 3 encounters at same station
        for _ in 0..<2 {
            let encounter = Encounter(
                peerId: "peer-1",
                peerDisplayName: "Test Peer",
                stationName: "Taipei Main Station"
            )
            history.addEncounter(encounter)
        }
        XCTAssertTrue(history.summary.contains("Met 3 times"))
    }

    // MARK: - EncounterTrackingManager Tests

    func testRecordEncounter() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        let station = Station(
            id: "taipei",
            name: "Taipei Main Station",
            latitude: 25.047,
            longitude: 121.517
        )

        let encounter = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .discovery,
            at: station
        )

        XCTAssertNotNil(encounter)
        XCTAssertEqual(encounter?.peerId, "peer-1")
        XCTAssertEqual(encounter?.interactionType, .discovery)
    }

    func testRecordEncounterDeduplication() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // First encounter
        let encounter1 = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .discovery
        )
        XCTAssertNotNil(encounter1)

        // Second encounter within 5 minutes (should be deduplicated)
        let encounter2 = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .discovery
        )
        XCTAssertNil(encounter2)

        // Different interaction type (should record)
        let encounter3 = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .chat
        )
        XCTAssertNotNil(encounter3)
    }

    func testGetHistory() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // No history initially
        XCTAssertNil(EncounterTrackingManager.shared.getHistory(for: "peer-1"))

        // Record encounter
        _ = EncounterTrackingManager.shared.recordEncounter(with: peer, interactionType: .discovery)

        // Should have history now
        let history = EncounterTrackingManager.shared.getHistory(for: "peer-1")
        XCTAssertNotNil(history)
        XCTAssertEqual(history?.encounterCount, 1)
    }

    func testMultipleEncounters() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // Record 3 different types of encounters
        _ = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .discovery
        )
        _ = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .chat
        )
        _ = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .contentSharing
        )

        let history = EncounterTrackingManager.shared.getHistory(for: "peer-1")
        XCTAssertEqual(history?.encounterCount, 3)
    }

    func testUpdateCurrentStation() {
        let station = Station(
            id: "taipei",
            name: "Taipei Main Station",
            latitude: 25.047,
            longitude: 121.517
        )

        EncounterTrackingManager.shared.updateCurrentStation(station)

        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        let encounter = EncounterTrackingManager.shared.recordEncounter(
            with: peer,
            interactionType: .discovery
        )

        XCTAssertEqual(encounter?.stationId, "taipei")
        XCTAssertEqual(encounter?.stationName, "Taipei Main Station")
    }

    func testSortedByEncounterCount() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")

        // peer1: 1 encounter
        _ = EncounterTrackingManager.shared.recordEncounter(
            with: peer1,
            interactionType: .discovery
        )

        // peer2: 2 encounters
        _ = EncounterTrackingManager.shared.recordEncounter(
            with: peer2,
            interactionType: .discovery
        )
        _ = EncounterTrackingManager.shared.recordEncounter(
            with: peer2,
            interactionType: .chat
        )

        let sorted = EncounterTrackingManager.shared.sortedByEncounterCount
        XCTAssertEqual(sorted.count, 2)
        XCTAssertEqual(sorted.first?.peerId, "peer-2")
        XCTAssertEqual(sorted.last?.peerId, "peer-1")
    }

    func testTotalEncounterCount() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")

        _ = EncounterTrackingManager.shared.recordEncounter(with: peer1, interactionType: .discovery)
        _ = EncounterTrackingManager.shared.recordEncounter(with: peer1, interactionType: .chat)
        _ = EncounterTrackingManager.shared.recordEncounter(with: peer2, interactionType: .discovery)

        XCTAssertEqual(EncounterTrackingManager.shared.totalEncounterCount, 3)
        XCTAssertEqual(EncounterTrackingManager.shared.uniquePeerCount, 2)
    }

    func testClearAll() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")

        _ = EncounterTrackingManager.shared.recordEncounter(with: peer1, interactionType: .discovery)
        _ = EncounterTrackingManager.shared.recordEncounter(with: peer2, interactionType: .discovery)

        XCTAssertEqual(EncounterTrackingManager.shared.uniquePeerCount, 2)

        EncounterTrackingManager.shared.clearAll()

        XCTAssertEqual(EncounterTrackingManager.shared.uniquePeerCount, 0)
        XCTAssertEqual(EncounterTrackingManager.shared.totalEncounterCount, 0)
    }

    func testDeleteHistory() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        _ = EncounterTrackingManager.shared.recordEncounter(with: peer, interactionType: .discovery)
        XCTAssertNotNil(EncounterTrackingManager.shared.getHistory(for: "peer-1"))

        let result = EncounterTrackingManager.shared.deleteHistory(for: "peer-1")
        XCTAssertTrue(result.isSuccess)
        XCTAssertNil(EncounterTrackingManager.shared.getHistory(for: "peer-1"))
    }

    func testDeleteHistoryNotFound() {
        let result = EncounterTrackingManager.shared.deleteHistory(for: "nonexistent-peer")

        switch result {
        case .success:
            XCTFail("Should not delete nonexistent history")
        case .failure(let error):
            XCTAssertEqual(error as? EncounterTrackingError, .historyNotFound)
        }
    }

    // MARK: - ChatRoom Integration Tests

    func testChatRoomSyncEncounterCount() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // Record 3 encounters
        _ = EncounterTrackingManager.shared.recordEncounter(with: peer, interactionType: .discovery)
        _ = EncounterTrackingManager.shared.recordEncounter(with: peer, interactionType: .chat)
        _ = EncounterTrackingManager.shared.recordEncounter(with: peer, interactionType: .contentSharing)

        var chatRoom = ChatRoom.createWith(peer: peer, encounterCount: 1)
        XCTAssertEqual(chatRoom.encounterCount, 1)

        chatRoom.syncEncounterCount()
        XCTAssertEqual(chatRoom.encounterCount, 3)
    }

    func testChatRoomCreateWithTracking() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // Record 2 encounters
        _ = EncounterTrackingManager.shared.recordEncounter(with: peer, interactionType: .discovery)
        _ = EncounterTrackingManager.shared.recordEncounter(with: peer, interactionType: .chat)

        let chatRoom = ChatRoom.createWithTracking(peer: peer)
        XCTAssertEqual(chatRoom.encounterCount, 2)
    }

    // MARK: - Performance Tests

    func testRecordEncounterPerformance() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        measure {
            for i in 0..<100 {
                _ = EncounterTrackingManager.shared.recordEncounter(
                    with: Peer(id: "peer-\(i)", displayName: "Peer \(i)"),
                    interactionType: .discovery
                )
            }
            EncounterTrackingManager.shared.clearAll()
        }
    }

    func testGetHistoryPerformance() {
        // Setup: Create 100 peers with encounters
        for i in 0..<100 {
            let peer = Peer(id: "peer-\(i)", displayName: "Peer \(i)")
            _ = EncounterTrackingManager.shared.recordEncounter(
                with: peer,
                interactionType: .discovery
            )
        }

        measure {
            for i in 0..<100 {
                _ = EncounterTrackingManager.shared.getHistory(for: "peer-\(i)")
            }
        }

        EncounterTrackingManager.shared.clearAll()
    }
}

// MARK: - Helper Extensions

extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
}

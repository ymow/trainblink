//
//  PeerTests.swift
//  TrainBlinkTests
//
//  Unit tests for Peer model (Feature 2: P2P Discovery)
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
import MultipeerConnectivity
@testable import TrainBlink

final class PeerTests: XCTestCase {

    // MARK: - Test Properties

    var peer: Peer!
    let testID = "test-peer-001"
    let testDisplayName = "Test User"

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        peer = Peer(
            id: testID,
            displayName: testDisplayName,
            connectionState: .notConnected
        )
    }

    override func tearDown() {
        peer = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitWithAllParameters() {
        let customPeer = Peer(
            id: "peer-123",
            displayName: "Custom User",
            connectionState: .connected,
            discoveredAt: Date(),
            lastSeenAt: Date(),
            signalStrength: 0.8,
            metadata: ["key": "value"]
        )

        XCTAssertEqual(customPeer.id, "peer-123")
        XCTAssertEqual(customPeer.displayName, "Custom User")
        XCTAssertEqual(customPeer.connectionState, .connected)
        XCTAssertEqual(customPeer.signalStrength, 0.8)
        XCTAssertNotNil(customPeer.metadata)
        XCTAssertEqual(customPeer.metadata?["key"], "value")
    }

    func testInitWithMinimalParameters() {
        let simplePeer = Peer(id: "simple-peer")

        XCTAssertEqual(simplePeer.id, "simple-peer")
        XCTAssertEqual(simplePeer.displayName, "simple-peer") // defaults to id
        XCTAssertEqual(simplePeer.connectionState, .notConnected)
        XCTAssertNil(simplePeer.signalStrength)
        XCTAssertNil(simplePeer.metadata)
    }

    func testInitFromMCPeerID() {
        let peerID = MCPeerID(displayName: "MCPeer")
        let mcPeer = Peer(from: peerID, connectionState: .connecting)

        XCTAssertEqual(mcPeer.id, "MCPeer")
        XCTAssertEqual(mcPeer.displayName, "MCPeer")
        XCTAssertEqual(mcPeer.connectionState, .connecting)
    }

    // MARK: - Computed Properties Tests

    func testIsConnectedWhenConnected() {
        peer.updateConnectionState(.connected)
        XCTAssertTrue(peer.isConnected)
    }

    func testIsConnectedWhenNotConnected() {
        XCTAssertFalse(peer.isConnected)
    }

    func testIsConnectingWhenConnecting() {
        peer.updateConnectionState(.connecting)
        XCTAssertTrue(peer.isConnecting)
    }

    func testIsConnectingWhenConnected() {
        peer.updateConnectionState(.connected)
        XCTAssertFalse(peer.isConnecting)
    }

    func testCanConnectWhenNotConnected() {
        XCTAssertTrue(peer.canConnect)
    }

    func testCannotConnectWhenConnected() {
        peer.updateConnectionState(.connected)
        XCTAssertFalse(peer.canConnect)
    }

    func testSecondsSinceLastSeen() {
        let now = Date()
        let twoSecondsAgo = now.addingTimeInterval(-2)
        var peer = Peer(id: "test", lastSeenAt: twoSecondsAgo)

        // Allow small tolerance for test execution time
        XCTAssertGreaterThanOrEqual(peer.secondsSinceLastSeen, 2.0)
        XCTAssertLessThan(peer.secondsSinceLastSeen, 3.0)
    }

    func testIsNotStale() {
        // Just discovered
        XCTAssertFalse(peer.isStale)
    }

    func testIsStale() {
        let oldTime = Date().addingTimeInterval(-70) // 70 seconds ago
        var stalePeer = Peer(id: "old", lastSeenAt: oldTime)
        XCTAssertTrue(stalePeer.isStale)
    }

    func testConnectionIconNotConnected() {
        XCTAssertEqual(peer.connectionIcon, "circle")
    }

    func testConnectionIconConnecting() {
        peer.updateConnectionState(.connecting)
        XCTAssertEqual(peer.connectionIcon, "circle.dotted")
    }

    func testConnectionIconConnected() {
        peer.updateConnectionState(.connected)
        XCTAssertEqual(peer.connectionIcon, "circle.fill")
    }

    // MARK: - Method Tests

    func testUpdateLastSeen() {
        let originalTime = peer.lastSeenAt

        // Wait a tiny bit
        Thread.sleep(forTimeInterval: 0.01)

        peer.updateLastSeen()

        XCTAssertNotEqual(peer.lastSeenAt, originalTime)
        XCTAssertGreaterThan(peer.lastSeenAt, originalTime)
    }

    func testUpdateConnectionState() {
        XCTAssertEqual(peer.connectionState, .notConnected)

        peer.updateConnectionState(.connecting)
        XCTAssertEqual(peer.connectionState, .connecting)

        peer.updateConnectionState(.connected)
        XCTAssertEqual(peer.connectionState, .connected)
    }

    func testUpdateSignalStrength() {
        XCTAssertNil(peer.signalStrength)

        peer.updateSignalStrength(0.75)
        XCTAssertEqual(peer.signalStrength, 0.75)
    }

    func testUpdateSignalStrengthClampedToValidRange() {
        // Test upper bound
        peer.updateSignalStrength(1.5)
        XCTAssertEqual(peer.signalStrength, 1.0)

        // Test lower bound
        peer.updateSignalStrength(-0.5)
        XCTAssertEqual(peer.signalStrength, 0.0)
    }

    // MARK: - Codable Tests

    func testEncodeThenDecode() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(peer)

        let decoder = JSONDecoder()
        let decodedPeer = try decoder.decode(Peer.self, from: data)

        XCTAssertEqual(decodedPeer.id, peer.id)
        XCTAssertEqual(decodedPeer.displayName, peer.displayName)
        XCTAssertEqual(decodedPeer.connectionState, peer.connectionState)
    }

    func testEncodeDecodeWithMetadata() throws {
        peer.metadata = ["version": "1.0", "platform": "ios"]

        let encoder = JSONEncoder()
        let data = try encoder.encode(peer)

        let decoder = JSONDecoder()
        let decodedPeer = try decoder.decode(Peer.self, from: data)

        XCTAssertEqual(decodedPeer.metadata?["version"], "1.0")
        XCTAssertEqual(decodedPeer.metadata?["platform"], "ios")
    }

    // MARK: - Hashable Tests

    func testHashableEquality() {
        let peer1 = Peer(id: "peer-1", displayName: "User 1")
        let peer2 = Peer(id: "peer-1", displayName: "Different Name")
        let peer3 = Peer(id: "peer-2", displayName: "User 1")

        // Same ID = equal
        XCTAssertEqual(peer1, peer2)

        // Different ID = not equal
        XCTAssertNotEqual(peer1, peer3)
    }

    func testHashValue() {
        let peer1 = Peer(id: "peer-1", displayName: "User 1")
        let peer2 = Peer(id: "peer-1", displayName: "Different Name")

        XCTAssertEqual(peer1.hashValue, peer2.hashValue)
    }

    func testHashableInSet() {
        let peer1 = Peer(id: "peer-1", displayName: "User 1")
        let peer2 = Peer(id: "peer-1", displayName: "User 1") // duplicate ID
        let peer3 = Peer(id: "peer-2", displayName: "User 2")

        let peerSet: Set<Peer> = [peer1, peer2, peer3]

        // Should only have 2 unique peers (peer1 and peer2 are same ID)
        XCTAssertEqual(peerSet.count, 2)
        XCTAssertTrue(peerSet.contains(peer1))
        XCTAssertTrue(peerSet.contains(peer3))
    }

    // MARK: - MultipeerConnectivity Integration Tests

    func testMakePeerID() {
        let mcPeerID = peer.makePeerID()

        XCTAssertEqual(mcPeerID.displayName, peer.id)
    }

    func testRoundTripMCPeerIDConversion() {
        let originalPeerID = MCPeerID(displayName: "OriginalPeer")
        let peer = Peer(from: originalPeerID)
        let convertedPeerID = peer.makePeerID()

        XCTAssertEqual(convertedPeerID.displayName, originalPeerID.displayName)
    }

    // MARK: - Sample Data Tests

    func testSamplePeersExist() {
        XCTAssertFalse(Peer.samples.isEmpty)
        XCTAssertEqual(Peer.samples.count, 5)
    }

    func testSamplePeersHaveUniqueIDs() {
        let ids = Peer.samples.map { $0.id }
        let uniqueIDs = Set(ids)

        XCTAssertEqual(ids.count, uniqueIDs.count)
    }

    func testSamplePeersHaveVariousStates() {
        let states = Peer.samples.map { $0.connectionState }

        XCTAssertTrue(states.contains(.notConnected))
        XCTAssertTrue(states.contains(.connecting))
        XCTAssertTrue(states.contains(.connected))
    }

    // MARK: - Performance Tests

    func testInitializationPerformance() {
        measure {
            for i in 0..<1000 {
                _ = Peer(id: "peer-\(i)", displayName: "User \(i)")
            }
        }
    }

    func testHashingPerformance() {
        let peers = (0..<1000).map { Peer(id: "peer-\($0)") }

        measure {
            _ = Set(peers)
        }
    }

    // MARK: - Edge Case Tests

    func testEmptyID() {
        let emptyPeer = Peer(id: "")
        XCTAssertEqual(emptyPeer.id, "")
        XCTAssertEqual(emptyPeer.displayName, "") // defaults to id
    }

    func testVeryLongDisplayName() {
        let longName = String(repeating: "a", count: 1000)
        let peer = Peer(id: "test", displayName: longName)
        XCTAssertEqual(peer.displayName, longName)
    }

    func testSignalStrengthBoundaries() {
        peer.updateSignalStrength(0.0)
        XCTAssertEqual(peer.signalStrength, 0.0)

        peer.updateSignalStrength(1.0)
        XCTAssertEqual(peer.signalStrength, 1.0)
    }

    func testStateTransitions() {
        // Not connected → Connecting → Connected
        XCTAssertEqual(peer.connectionState, .notConnected)

        peer.updateConnectionState(.connecting)
        XCTAssertEqual(peer.connectionState, .connecting)

        peer.updateConnectionState(.connected)
        XCTAssertEqual(peer.connectionState, .connected)

        // Connected → Not connected (disconnect)
        peer.updateConnectionState(.notConnected)
        XCTAssertEqual(peer.connectionState, .notConnected)
    }
}

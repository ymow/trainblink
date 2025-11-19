//
//  MultipeerManagerTests.swift
//  TrainBlinkTests
//
//  Unit tests for MultipeerManager (Feature 2: P2P Discovery)
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
import Combine
@testable import TrainBlink

final class MultipeerManagerTests: XCTestCase {

    // MARK: - Test Properties

    var manager: MultipeerManager!
    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        manager = MultipeerManager()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        manager.stopDiscovery()
        manager = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(manager)
        XCTAssertFalse(manager.isAdvertising)
        XCTAssertFalse(manager.isBrowsing)
        XCTAssertTrue(manager.discoveredPeers.isEmpty)
        XCTAssertTrue(manager.connectedPeers.isEmpty)
    }

    // MARK: - Discovery State Tests

    func testStartDiscovery() {
        // Note: This will attempt to start actual discovery
        // In real tests, this would be mocked
        manager.startDiscovery()

        // Give it a moment to start
        let expectation = XCTestExpectation(description: "Start discovery")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(manager.isAdvertising)
        XCTAssertTrue(manager.isBrowsing)
    }

    func testStopDiscovery() {
        manager.startDiscovery()

        // Wait for start
        let startExpectation = XCTestExpectation(description: "Start discovery")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startExpectation.fulfill()
        }
        wait(for: [startExpectation], timeout: 1.0)

        manager.stopDiscovery()

        XCTAssertFalse(manager.isAdvertising)
        XCTAssertFalse(manager.isBrowsing)
        XCTAssertTrue(manager.discoveredPeers.isEmpty)
        XCTAssertTrue(manager.connectedPeers.isEmpty)
    }

    func testStartDiscoveryTwiceDoesNothing() {
        manager.startDiscovery()
        manager.startDiscovery() // Should be ignored

        let expectation = XCTestExpectation(description: "Discovery started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(manager.isAdvertising)
        XCTAssertTrue(manager.isBrowsing)
    }

    // MARK: - Published Properties Tests

    func testDiscoveredPeersPublisher() {
        let expectation = XCTestExpectation(description: "Peers updated")
        var updateCount = 0

        manager.$discoveredPeers
            .dropFirst() // Skip initial value
            .sink { _ in
                updateCount += 1
                if updateCount == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Manually update (simulating discovery)
        manager.discoveredPeers.append(Peer(id: "test-peer"))

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(updateCount, 1)
    }

    func testConnectedPeersPublisher() {
        let expectation = XCTestExpectation(description: "Connected peers updated")

        manager.$connectedPeers
            .dropFirst()
            .sink { peers in
                if !peers.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        manager.connectedPeers.append(Peer(id: "connected-peer"))

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(manager.connectedPeers.count, 1)
    }

    // MARK: - Event Publisher Tests

    func testEventPublisher() {
        let expectation = XCTestExpectation(description: "Event published")

        manager.eventPublisher
            .sink { event in
                switch event {
                case .peerDiscovered:
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Manually trigger event
        let testPeer = Peer(id: "test")
        manager.eventPublisher.send(.peerDiscovered(testPeer))

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Top Nearest Peers Tests

    func testTopNearestPeersWithEmptyList() {
        let nearest = manager.topNearestPeers(limit: 5)
        XCTAssertTrue(nearest.isEmpty)
    }

    func testTopNearestPeersFiltersStale() {
        // Add fresh peer
        let freshPeer = Peer(id: "fresh", signalStrength: 0.8)
        manager.discoveredPeers.append(freshPeer)

        // Add stale peer (70 seconds ago)
        let oldTime = Date().addingTimeInterval(-70)
        var stalePeer = Peer(id: "stale", lastSeenAt: oldTime, signalStrength: 0.9)
        manager.discoveredPeers.append(stalePeer)

        let nearest = manager.topNearestPeers(limit: 10)

        // Should only include fresh peer
        XCTAssertEqual(nearest.count, 1)
        XCTAssertEqual(nearest.first?.id, "fresh")
    }

    func testTopNearestPeersSortsBySignalStrength() {
        let peer1 = Peer(id: "peer1", signalStrength: 0.5)
        let peer2 = Peer(id: "peer2", signalStrength: 0.9)
        let peer3 = Peer(id: "peer3", signalStrength: 0.7)

        manager.discoveredPeers = [peer1, peer2, peer3]

        let nearest = manager.topNearestPeers(limit: 10)

        XCTAssertEqual(nearest.count, 3)
        XCTAssertEqual(nearest[0].id, "peer2") // Highest signal
        XCTAssertEqual(nearest[1].id, "peer3")
        XCTAssertEqual(nearest[2].id, "peer1") // Lowest signal
    }

    func testTopNearestPeersRespectsLimit() {
        for i in 0..<30 {
            let peer = Peer(id: "peer-\(i)", signalStrength: Double(i) / 30.0)
            manager.discoveredPeers.append(peer)
        }

        let nearest = manager.topNearestPeers(limit: 20)

        XCTAssertEqual(nearest.count, 20)
    }

    // MARK: - Connection Management Tests

    func testConnectToPeerRequiresSession() {
        let peer = Peer(id: "test")

        // Should not crash when session not started
        manager.connect(to: peer)
    }

    func testDisconnectFromPeer() {
        let peer = Peer(id: "test", connectionState: .connected)
        manager.connectedPeers.append(peer)
        manager.discoveredPeers.append(peer)

        XCTAssertEqual(manager.connectedPeers.count, 1)

        manager.disconnect(from: peer)

        XCTAssertEqual(manager.connectedPeers.count, 0)
    }

    // MARK: - Memory Management Tests

    func testManagerDeallocatesCorrectly() {
        weak var weakManager: MultipeerManager?

        autoreleasepool {
            let tempManager = MultipeerManager()
            weakManager = tempManager

            tempManager.startDiscovery()

            // Wait briefly
            let expectation = XCTestExpectation(description: "Discovery started")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)

            tempManager.stopDiscovery()
        }

        // Manager should be deallocated
        XCTAssertNil(weakManager, "MultipeerManager should be deallocated")
    }

    func testEventPublisherDoesNotRetain() {
        weak var weakManager: MultipeerManager?

        autoreleasepool {
            let tempManager = MultipeerManager()
            weakManager = tempManager

            _ = tempManager.eventPublisher
                .sink { _ in
                    // Event handler
                }
        }

        XCTAssertNil(weakManager, "Event publisher should not retain manager")
    }

    // MARK: - State Consistency Tests

    func testPeerStateConsistency() {
        let peer = Peer(id: "test", connectionState: .notConnected)
        manager.discoveredPeers.append(peer)

        // Connect
        manager.discoveredPeers[0].updateConnectionState(.connected)
        XCTAssertTrue(manager.discoveredPeers[0].isConnected)

        // Disconnect
        manager.discoveredPeers[0].updateConnectionState(.notConnected)
        XCTAssertFalse(manager.discoveredPeers[0].isConnected)
    }

    // MARK: - Performance Tests

    func testDiscoveryStartStopPerformance() {
        measure {
            manager.startDiscovery()

            // Wait briefly
            let expectation = XCTestExpectation(description: "Discovery started")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)

            manager.stopDiscovery()
        }
    }

    func testTopNearestPeersPerformance() {
        // Add 100 peers
        for i in 0..<100 {
            let peer = Peer(id: "peer-\(i)", signalStrength: Double.random(in: 0...1))
            manager.discoveredPeers.append(peer)
        }

        measure {
            _ = manager.topNearestPeers(limit: 20)
        }
    }

    // MARK: - Edge Case Tests

    func testEmptyPeerList() {
        XCTAssertTrue(manager.discoveredPeers.isEmpty)
        XCTAssertTrue(manager.connectedPeers.isEmpty)

        let nearest = manager.topNearestPeers()
        XCTAssertTrue(nearest.isEmpty)
    }

    func testStopDiscoveryWhenNotStarted() {
        // Should not crash
        manager.stopDiscovery()

        XCTAssertFalse(manager.isAdvertising)
        XCTAssertFalse(manager.isBrowsing)
    }

    func testMultipleStartStopCycles() {
        for _ in 0..<5 {
            manager.startDiscovery()

            let expectation = XCTestExpectation(description: "Discovery started")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)

            manager.stopDiscovery()
        }

        XCTAssertFalse(manager.isAdvertising)
        XCTAssertFalse(manager.isBrowsing)
        XCTAssertTrue(manager.discoveredPeers.isEmpty)
    }
}

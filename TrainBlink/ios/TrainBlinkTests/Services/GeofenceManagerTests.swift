//
//  GeofenceManagerTests.swift
//  TrainBlinkTests
//
//  Unit tests for GeofenceManager
//  Feature 1: Geofencing System
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
import CoreLocation
import Combine
@testable import TrainBlink

final class GeofenceManagerTests: XCTestCase {

    var geofenceManager: GeofenceManager!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        geofenceManager = GeofenceManager()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        geofenceManager = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testManagerInitialization() {
        XCTAssertNotNil(geofenceManager)
        XCTAssertFalse(geofenceManager.isInStation)
        XCTAssertNil(geofenceManager.currentStation)
    }

    func testInitialAuthorizationStatus() {
        // Initial status should be notDetermined or current system status
        let status = geofenceManager.authorizationStatus
        XCTAssertTrue([
            .notDetermined,
            .authorizedAlways,
            .authorizedWhenInUse,
            .denied,
            .restricted
        ].contains(status))
    }

    // MARK: - Simulate Entry Tests

    func testSimulateEntry() {
        let expectation = XCTestExpectation(description: "Entry event received")
        let station = Station.samples[0]

        geofenceManager.eventPublisher
            .sink { event in
                if case .entered(let enteredStation, _) = event {
                    XCTAssertEqual(enteredStation.id, station.id)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        geofenceManager.simulateEntry(to: station)

        wait(for: [expectation], timeout: 2.0)
    }

    func testSimulateEntryUpdatesState() {
        let station = Station.samples[0]

        XCTAssertFalse(geofenceManager.isInStation)
        XCTAssertNil(geofenceManager.currentStation)

        let expectation = XCTestExpectation(description: "State updated")

        geofenceManager.simulateEntry(to: station)

        // Wait for async state update
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertTrue(self.geofenceManager.isInStation)
            XCTAssertEqual(self.geofenceManager.currentStation?.id, station.id)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Simulate Exit Tests

    func testSimulateExit() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Exit event received")

        // First enter
        geofenceManager.simulateEntry(to: station)

        // Wait for entry to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Then exit
            self.geofenceManager.eventPublisher
                .sink { event in
                    if case .exited(let exitedStation, _) = event {
                        XCTAssertEqual(exitedStation.id, station.id)
                        expectation.fulfill()
                    }
                }
                .store(in: &self.cancellables)

            self.geofenceManager.simulateExit(from: station)
        }

        wait(for: [expectation], timeout: 4.0)
    }

    func testSimulateExitUpdatesState() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Exit state updated")

        // Enter
        geofenceManager.simulateEntry(to: station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Verify in station
            XCTAssertTrue(self.geofenceManager.isInStation)

            // Exit
            self.geofenceManager.simulateExit(from: station)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                XCTAssertFalse(self.geofenceManager.isInStation)
                XCTAssertNil(self.geofenceManager.currentStation)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 4.0)
    }

    // MARK: - Event Publisher Tests

    func testEventPublisherPublishesEvents() {
        let station = Station.samples[0]
        var receivedEvents: [GeofenceEvent] = []

        geofenceManager.eventPublisher
            .sink { event in
                receivedEvents.append(event)
            }
            .store(in: &cancellables)

        geofenceManager.simulateEntry(to: station)

        // Wait for event
        let expectation = XCTestExpectation(description: "Event published")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertGreaterThan(receivedEvents.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func testMultipleSubscribers() {
        let station = Station.samples[0]
        var subscriber1Events: [GeofenceEvent] = []
        var subscriber2Events: [GeofenceEvent] = []

        geofenceManager.eventPublisher
            .sink { event in
                subscriber1Events.append(event)
            }
            .store(in: &cancellables)

        geofenceManager.eventPublisher
            .sink { event in
                subscriber2Events.append(event)
            }
            .store(in: &cancellables)

        geofenceManager.simulateEntry(to: station)

        let expectation = XCTestExpectation(description: "Both subscribers notified")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(subscriber1Events.count, subscriber2Events.count)
            XCTAssertGreaterThan(subscriber1Events.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - State Management Tests

    func testEntryExitCycle() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Entry-exit cycle completed")

        // Initial state
        XCTAssertFalse(geofenceManager.isInStation)

        // Enter
        geofenceManager.simulateEntry(to: station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Should be in station
            XCTAssertTrue(self.geofenceManager.isInStation)
            XCTAssertNotNil(self.geofenceManager.currentStation)

            // Exit
            self.geofenceManager.simulateExit(from: station)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Should be out of station
                XCTAssertFalse(self.geofenceManager.isInStation)
                XCTAssertNil(self.geofenceManager.currentStation)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 4.0)
    }

    func testMultipleEntryToSameStation() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Multiple entries handled")

        var entryCount = 0
        geofenceManager.eventPublisher
            .sink { event in
                if case .entered = event {
                    entryCount += 1
                }
            }
            .store(in: &cancellables)

        // Enter first time
        geofenceManager.simulateEntry(to: station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Enter again (should be ignored since already in station)
            self.geofenceManager.simulateEntry(to: station)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Should only have one entry event
                XCTAssertEqual(entryCount, 1, "Should ignore duplicate entry")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 4.0)
    }

    func testEntryToDifferentStation() {
        let station1 = Station.samples[0]
        let station2 = Station.samples[1]
        let expectation = XCTestExpectation(description: "Switch stations")

        // Enter station 1
        geofenceManager.simulateEntry(to: station1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.geofenceManager.currentStation?.id, station1.id)

            // Enter station 2 (should replace station 1)
            self.geofenceManager.simulateEntry(to: station2)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                XCTAssertEqual(self.geofenceManager.currentStation?.id, station2.id)
                XCTAssertTrue(self.geofenceManager.isInStation)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 4.0)
    }

    // MARK: - Published Property Tests

    func testIsInStationPublished() {
        let station = Station.samples[0]
        var stateChanges: [Bool] = []

        geofenceManager.$isInStation
            .sink { isInStation in
                stateChanges.append(isInStation)
            }
            .store(in: &cancellables)

        let expectation = XCTestExpectation(description: "isInStation published")

        // Should start with false
        XCTAssertEqual(stateChanges.first, false)

        geofenceManager.simulateEntry(to: station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Should have changed to true
            XCTAssertTrue(stateChanges.contains(true))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func testCurrentStationPublished() {
        let station = Station.samples[0]
        var stationChanges: [Station?] = []

        geofenceManager.$currentStation
            .sink { currentStation in
                stationChanges.append(currentStation)
            }
            .store(in: &cancellables)

        let expectation = XCTestExpectation(description: "currentStation published")

        // Should start with nil
        XCTAssertNil(stationChanges.first as Any)

        geofenceManager.simulateEntry(to: station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Should have the station
            let hasStation = stationChanges.contains { $0?.id == station.id }
            XCTAssertTrue(hasStation)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Error Handling Tests

    func testErrorEvent() {
        let expectation = XCTestExpectation(description: "Error event received")
        let testError = TrainBlinkError.locationPermissionDenied

        geofenceManager.eventPublisher
            .sink { event in
                if case .error(let error) = event {
                    XCTAssertEqual(error.localizedDescription,
                                 testError.localizedDescription)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Simulate error by publishing directly
        geofenceManager.eventPublisher.send(.error(testError))

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Integration with StationDatabase Tests

    func testGeofenceUsesStationDatabase() {
        // Verify geofence manager can access station database
        let database = StationDatabase.shared
        XCTAssertGreaterThan(database.totalCount, 0)

        // If we have station 1001, we can test with it
        if let station = database.station(withID: "1001") {
            let expectation = XCTestExpectation(description: "Entry with database station")

            geofenceManager.eventPublisher
                .sink { event in
                    if case .entered(let enteredStation, _) = event {
                        XCTAssertEqual(enteredStation.id, "1001")
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)

            geofenceManager.simulateEntry(to: station)

            wait(for: [expectation], timeout: 2.0)
        }
    }

    // MARK: - Thread Safety Tests

    func testConcurrentEntryRequests() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Concurrent entries handled")
        expectation.expectedFulfillmentCount = 3

        // Simulate multiple concurrent entry requests
        DispatchQueue.global(qos: .userInitiated).async {
            self.geofenceManager.simulateEntry(to: station)
            expectation.fulfill()
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.geofenceManager.simulateEntry(to: station)
            expectation.fulfill()
        }

        DispatchQueue.global(qos: .background).async {
            self.geofenceManager.simulateEntry(to: station)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)

        // Should not crash and should end up in valid state
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertTrue(self.geofenceManager.isInStation)
        }
    }

    // MARK: - Performance Tests

    func testSimulateEntryPerformance() {
        let station = Station.samples[0]

        measure {
            for _ in 0..<10 {
                geofenceManager.simulateEntry(to: station)
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }

    func testEventPublishingPerformance() {
        let station = Station.samples[0]
        var eventCount = 0

        geofenceManager.eventPublisher
            .sink { _ in
                eventCount += 1
            }
            .store(in: &cancellables)

        measure {
            for _ in 0..<10 {
                geofenceManager.simulateEntry(to: station)
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }

    // MARK: - Memory Tests

    func testNoMemoryLeaksOnEntryExit() {
        weak var weakManager: GeofenceManager?

        autoreleasepool {
            let manager = GeofenceManager()
            weakManager = manager

            let station = Station.samples[0]
            manager.simulateEntry(to: station)

            // Wait for entry
            Thread.sleep(forTimeInterval: 1.5)

            XCTAssertNotNil(weakManager)
        }

        // Manager should be deallocated
        XCTAssertNil(weakManager, "GeofenceManager should be deallocated")
    }

    func testEventPublisherDoesNotRetainManager() {
        weak var weakManager: GeofenceManager?
        var cancellables = Set<AnyCancellable>()

        autoreleasepool {
            let manager = GeofenceManager()
            weakManager = manager

            manager.eventPublisher
                .sink { _ in
                    // Do nothing
                }
                .store(in: &cancellables)
        }

        // Clean up subscribers
        cancellables.removeAll()

        // Manager should be deallocated
        XCTAssertNil(weakManager, "GeofenceManager should not be retained by publisher")
    }
}

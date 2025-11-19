//
//  GeofenceIntegrationTests.swift
//  TrainBlinkTests
//
//  Integration tests for complete geofencing flow
//  Feature 1: Geofencing System
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
import CoreLocation
import Combine
@testable import TrainBlink

final class GeofenceIntegrationTests: XCTestCase {

    var appState: AppState!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        appState = AppState()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        appState = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    // MARK: - Full Entry/Exit Flow Tests

    func testCompleteEntryExitFlow() {
        let expectation = XCTestExpectation(description: "Complete entry-exit flow")
        let station = Station.samples[0]

        var events: [String] = []

        // Monitor app state changes
        appState.$isInStation
            .sink { isInStation in
                events.append("isInStation: \(isInStation)")
            }
            .store(in: &cancellables)

        appState.$currentStation
            .sink { station in
                if let station = station {
                    events.append("currentStation: \(station.name)")
                } else {
                    events.append("currentStation: nil")
                }
            }
            .store(in: &cancellables)

        // Initial state
        XCTAssertFalse(appState.isInStation)
        XCTAssertNil(appState.currentStation)

        // Simulate entry
        appState.enterStation(station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Should be in station
            XCTAssertTrue(self.appState.isInStation)
            XCTAssertEqual(self.appState.currentStation?.id, station.id)

            // Simulate exit
            self.appState.exitStation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Should be out of station
                XCTAssertFalse(self.appState.isInStation)
                XCTAssertNil(self.appState.currentStation)

                // Verify event sequence
                print("Events: \(events)")
                XCTAssertTrue(events.contains { $0.contains("true") })
                XCTAssertTrue(events.contains { $0.contains(station.name) })

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testMultipleStationVisits() {
        let expectation = XCTestExpectation(description: "Multiple station visits")
        let station1 = Station.samples[0]
        let station2 = Station.samples[1]
        let station3 = Station.samples[2]

        var visitedStations: [String] = []

        appState.$currentStation
            .compactMap { $0 }
            .sink { station in
                visitedStations.append(station.id)
            }
            .store(in: &cancellables)

        // Visit station 1
        appState.enterStation(station1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.appState.currentStation?.id, station1.id)

            // Exit and visit station 2
            self.appState.exitStation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.appState.enterStation(station2)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    XCTAssertEqual(self.appState.currentStation?.id, station2.id)

                    // Exit and visit station 3
                    self.appState.exitStation()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.appState.enterStation(station3)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            XCTAssertEqual(self.appState.currentStation?.id, station3.id)

                            // Verify all visits recorded
                            XCTAssertTrue(visitedStations.contains(station1.id))
                            XCTAssertTrue(visitedStations.contains(station2.id))
                            XCTAssertTrue(visitedStations.contains(station3.id))

                            expectation.fulfill()
                        }
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - State Synchronization Tests

    func testAppStateAndGeofenceManagerSync() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "State synchronization")

        // Enter via AppState
        appState.enterStation(station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Both should be synchronized
            XCTAssertEqual(
                self.appState.isInStation,
                self.appState.geofenceManager.isInStation
            )
            XCTAssertEqual(
                self.appState.currentStation?.id,
                self.appState.geofenceManager.currentStation?.id
            )

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func testGeofenceEventPropagation() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Event propagation")

        var receivedGeofenceEvent = false
        var appStateUpdated = false

        // Monitor geofence events
        appState.geofenceManager.eventPublisher
            .sink { event in
                if case .entered = event {
                    receivedGeofenceEvent = true
                }
            }
            .store(in: &cancellables)

        // Monitor app state
        appState.$isInStation
            .sink { isInStation in
                if isInStation {
                    appStateUpdated = true
                }
            }
            .store(in: &cancellables)

        // Trigger entry
        appState.enterStation(station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertTrue(receivedGeofenceEvent, "Geofence event should be received")
            XCTAssertTrue(appStateUpdated, "App state should be updated")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Database Integration Tests

    func testStationFromDatabase() {
        let expectation = XCTestExpectation(description: "Station from database")
        let database = StationDatabase.shared

        // Get a station from database
        guard let station = database.allStations.first else {
            XCTFail("No stations in database")
            return
        }

        // Use it in geofence
        appState.enterStation(station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertEqual(self.appState.currentStation?.id, station.id)
            XCTAssertTrue(self.appState.isInStation)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func testNearestStationEntry() {
        let expectation = XCTestExpectation(description: "Nearest station entry")
        let database = StationDatabase.shared

        // Find nearest station to Taipei
        let taipeiLocation = CLLocation(latitude: 25.0478, longitude: 121.5170)
        guard let nearest = database.nearestStation(to: taipeiLocation) else {
            XCTFail("No nearest station found")
            return
        }

        // Enter that station
        appState.enterStation(nearest)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertTrue(self.appState.isInStation)
            XCTAssertNotNil(self.appState.currentStation)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Analytics Integration Tests

    func testAnalyticsLoggingOnEntry() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Analytics logged on entry")

        // Note: We can't directly test Firebase Analytics in unit tests
        // But we can verify the app doesn't crash when logging
        appState.enterStation(station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // If we got here, analytics didn't crash the app
            XCTAssertTrue(self.appState.isInStation)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func testAnalyticsLoggingOnExit() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Analytics logged on exit")

        // Enter first
        appState.enterStation(station)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Then exit
            self.appState.exitStation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // If we got here, analytics didn't crash
                XCTAssertFalse(self.appState.isInStation)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 4.0)
    }

    // MARK: - Rapid State Change Tests

    func testRapidEntryExit() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Rapid entry-exit handled")

        // Rapid entry-exit
        appState.enterStation(station)
        appState.exitStation()
        appState.enterStation(station)
        appState.exitStation()

        // Wait and check final state
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Should handle rapid changes gracefully
            // Final state should be stable (either in or out)
            XCTAssertNotNil(self.appState) // App should not crash
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testSwitchStationsQuickly() {
        let station1 = Station.samples[0]
        let station2 = Station.samples[1]
        let station3 = Station.samples[2]
        let expectation = XCTestExpectation(description: "Quick station switches")

        // Quickly switch between stations
        appState.enterStation(station1)
        appState.enterStation(station2)
        appState.enterStation(station3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Should end up at last station
            XCTAssertEqual(self.appState.currentStation?.id, station3.id)
            XCTAssertTrue(self.appState.isInStation)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Error Recovery Tests

    func testRecoveryAfterError() {
        let station = Station.samples[0]
        let expectation = XCTestExpectation(description: "Recovery after error")

        var errorReceived = false

        // Monitor errors
        appState.geofenceManager.eventPublisher
            .sink { event in
                if case .error = event {
                    errorReceived = true
                }
            }
            .store(in: &cancellables)

        // Simulate error
        appState.geofenceManager.eventPublisher.send(
            .error(TrainBlinkError.locationPermissionDenied)
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(errorReceived)

            // Should still be able to enter station after error
            self.appState.enterStation(station)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                XCTAssertTrue(self.appState.isInStation)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Memory and Performance Integration

    func testLongRunningSession() {
        let expectation = XCTestExpectation(description: "Long session stability")
        let stations = Station.samples

        var visitCount = 0

        // Simulate visiting multiple stations over time
        func visitNextStation() {
            guard visitCount < stations.count else {
                expectation.fulfill()
                return
            }

            let station = stations[visitCount]
            self.appState.enterStation(station)
            visitCount += 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.appState.exitStation()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    visitNextStation()
                }
            }
        }

        visitNextStation()

        wait(for: [expectation], timeout: 10.0)

        // Should have visited all stations without crashes or leaks
        XCTAssertEqual(visitCount, stations.count)
    }

    func testConcurrentUsersSimulation() {
        // Simulate multiple "users" (app states) at different stations
        let appState1 = AppState()
        let appState2 = AppState()
        let appState3 = AppState()

        let expectation = XCTestExpectation(description: "Concurrent users handled")
        expectation.expectedFulfillmentCount = 3

        // User 1 enters station 0
        appState1.enterStation(Station.samples[0])

        // User 2 enters station 1
        appState2.enterStation(Station.samples[1])

        // User 3 enters station 2
        appState3.enterStation(Station.samples[2])

        // Verify after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertTrue(appState1.isInStation)
            expectation.fulfill()

            XCTAssertTrue(appState2.isInStation)
            expectation.fulfill()

            XCTAssertTrue(appState3.isInStation)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Real-World Scenario Tests

    func testTypicalCommuterJourney() {
        let expectation = XCTestExpectation(description: "Typical commuter journey")

        // Morning: Enter home station
        let homeStation = Station.samples[0]
        appState.enterStation(homeStation)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertTrue(self.appState.isInStation)

            // Board train: Exit home station
            self.appState.exitStation()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                XCTAssertFalse(self.appState.isInStation)

                // Arrive at work station
                let workStation = Station.samples[1]
                self.appState.enterStation(workStation)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    XCTAssertTrue(self.appState.isInStation)
                    XCTAssertEqual(self.appState.currentStation?.id, workStation.id)

                    // Leave work station
                    self.appState.exitStation()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        XCTAssertFalse(self.appState.isInStation)
                        expectation.fulfill()
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 8.0)
    }

    func testWeekendTripScenario() {
        let expectation = XCTestExpectation(description: "Weekend trip scenario")

        // Visit multiple stations during weekend trip
        let stations = [
            Station.samples[0], // Start
            Station.samples[1], // Transfer
            Station.samples[2], // Destination
            Station.samples[1], // Transfer back
            Station.samples[0]  // Home
        ]

        var currentIndex = 0

        func visitStation() {
            guard currentIndex < stations.count else {
                expectation.fulfill()
                return
            }

            let station = stations[currentIndex]
            self.appState.enterStation(station)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertEqual(self.appState.currentStation?.id, station.id)

                self.appState.exitStation()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    currentIndex += 1
                    visitStation()
                }
            }
        }

        visitStation()

        wait(for: [expectation], timeout: 10.0)
    }
}

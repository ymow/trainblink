//
//  StationDatabaseTests.swift
//  TrainBlinkTests
//
//  Unit tests for StationDatabase
//  Feature 1: Geofencing System
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
import CoreLocation
@testable import TrainBlink

final class StationDatabaseTests: XCTestCase {

    var database: StationDatabase!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = StationDatabase.shared
    }

    override func tearDownWithError() throws {
        database = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testDatabaseInitialization() {
        XCTAssertNotNil(database)
        XCTAssertGreaterThan(database.totalCount, 0, "Database should load stations")
    }

    func testDatabaseLoadsStations() {
        // Should load either from JSON (34 stations) or samples (5 stations)
        let count = database.totalCount
        XCTAssertTrue(count == 34 || count == 5, "Should load 34 stations from JSON or 5 samples")
    }

    // MARK: - Query by ID Tests

    func testFindStationByID() {
        // Test with known station ID from samples
        let station = database.station(withID: "1001")

        if let station = station {
            XCTAssertEqual(station.id, "1001")
            XCTAssertFalse(station.name.isEmpty)
        } else {
            // If full JSON loaded, try a different ID
            let anyStation = database.allStations.first
            XCTAssertNotNil(anyStation)
        }
    }

    func testFindStationByInvalidID() {
        let station = database.station(withID: "INVALID-ID-9999")
        XCTAssertNil(station)
    }

    func testFindStationByEmptyID() {
        let station = database.station(withID: "")
        XCTAssertNil(station)
    }

    // MARK: - Query by Type Tests

    func testFindStationsByTypeTRA() {
        let traStations = database.stations(ofType: .tra)

        XCTAssertGreaterThan(traStations.count, 0, "Should have TRA stations")

        // Verify all returned stations are TRA
        for station in traStations {
            XCTAssertEqual(station.type, .tra)
        }
    }

    func testFindStationsByTypeTHSR() {
        let thsrStations = database.stations(ofType: .thsr)

        XCTAssertGreaterThan(thsrStations.count, 0, "Should have THSR stations")

        // Verify all returned stations are THSR
        for station in thsrStations {
            XCTAssertEqual(station.type, .thsr)
        }
    }

    func testFindStationsByTypeMRT() {
        let mrtStations = database.stations(ofType: .mrt)

        // MRT stations may not exist in current dataset
        // Just verify the query doesn't crash
        for station in mrtStations {
            XCTAssertEqual(station.type, .mrt)
        }
    }

    func testStationTypesCounts() {
        let traCount = database.count(ofType: .tra)
        let thsrCount = database.count(ofType: .thsr)
        let mrtCount = database.count(ofType: .mrt)
        let total = database.totalCount

        XCTAssertEqual(traCount + thsrCount + mrtCount, total,
                       "Sum of type counts should equal total count")
    }

    // MARK: - Search Tests

    func testSearchStationsByName() {
        let results = database.stations(matching: "台北")

        XCTAssertGreaterThan(results.count, 0, "Should find stations with 台北")

        // Verify all results contain the search term
        for station in results {
            let containsInName = station.name.lowercased().contains("台北".lowercased())
            let containsInNameEn = station.nameEn.lowercased().contains("台北".lowercased())
            XCTAssertTrue(containsInName || containsInNameEn)
        }
    }

    func testSearchStationsByEnglishName() {
        let results = database.stations(matching: "Taipei")

        XCTAssertGreaterThan(results.count, 0, "Should find stations with Taipei")

        for station in results {
            let containsInName = station.name.lowercased().contains("taipei")
            let containsInNameEn = station.nameEn.lowercased().contains("taipei")
            XCTAssertTrue(containsInName || containsInNameEn)
        }
    }

    func testSearchStationsCaseInsensitive() {
        let lowercase = database.stations(matching: "taipei")
        let uppercase = database.stations(matching: "TAIPEI")
        let mixedcase = database.stations(matching: "TaiPei")

        XCTAssertEqual(lowercase.count, uppercase.count)
        XCTAssertEqual(lowercase.count, mixedcase.count)
    }

    func testSearchStationsNoResults() {
        let results = database.stations(matching: "NonExistentStation12345")
        XCTAssertEqual(results.count, 0)
    }

    func testSearchStationsEmptyQuery() {
        let results = database.stations(matching: "")

        // Empty query should match all stations (since empty string is contained in all)
        XCTAssertEqual(results.count, database.totalCount)
    }

    // MARK: - Nearest Station Tests

    func testFindNearestStation() {
        // Location near Taipei Station (25.0478, 121.5170)
        let location = CLLocation(latitude: 25.05, longitude: 121.52)

        let nearest = database.nearestStation(to: location)

        XCTAssertNotNil(nearest)
        if let nearest = nearest {
            // Should find Taipei Station or a nearby station
            let distance = nearest.distance(from: location)
            XCTAssertLessThan(distance, 10_000) // Within 10km
        }
    }

    func testNearestStationWithMultipleCandidates() {
        // Create a location
        let location = CLLocation(latitude: 25.0, longitude: 121.0)

        let nearest1 = database.nearestStation(to: location)
        XCTAssertNotNil(nearest1)

        // All other stations should be farther
        if let nearest = nearest1 {
            let nearestDistance = nearest.distance(from: location)

            for station in database.allStations where station.id != nearest.id {
                let distance = station.distance(from: location)
                XCTAssertGreaterThanOrEqual(distance, nearestDistance)
            }
        }
    }

    func testNearestStationEmptyDatabase() {
        // Can't easily test with singleton, but verify it doesn't crash
        let location = CLLocation(latitude: 0, longitude: 0)
        let nearest = database.nearestStation(to: location)

        // With current data, should always find something
        XCTAssertNotNil(nearest)
    }

    // MARK: - Stations Within Radius Tests

    func testStationsWithinRadius() {
        // Taipei Station location
        let taipeiLocation = CLLocation(latitude: 25.0478, longitude: 121.5170)

        // Find stations within 1km
        let nearbyStations = database.stations(within: 1000, of: taipeiLocation)

        XCTAssertGreaterThan(nearbyStations.count, 0, "Should find at least Taipei Station itself")

        // Verify all stations are within radius
        for station in nearbyStations {
            let distance = station.distance(from: taipeiLocation)
            XCTAssertLessThanOrEqual(distance, 1000)
        }
    }

    func testStationsWithinRadiusSorted() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)
        let stations = database.stations(within: 50_000, of: location) // 50km

        // Verify sorted by distance
        var previousDistance: CLLocationDistance = 0
        for station in stations {
            let distance = station.distance(from: location)
            XCTAssertGreaterThanOrEqual(distance, previousDistance,
                                       "Stations should be sorted by distance")
            previousDistance = distance
        }
    }

    func testStationsWithinZeroRadius() {
        let location = CLLocation(latitude: 25.0478, longitude: 121.5170)
        let stations = database.stations(within: 0, of: location)

        // Should only find stations exactly at this location (unlikely but possible)
        for station in stations {
            let distance = station.distance(from: location)
            XCTAssertLessThanOrEqual(distance, 1) // Allow 1 meter tolerance for floating point
        }
    }

    func testStationsWithinLargeRadius() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)
        let stations = database.stations(within: 1_000_000, of: location) // 1000km

        // Should find all stations in Taiwan
        XCTAssertEqual(stations.count, database.totalCount)
    }

    // MARK: - Stations Containing Location Tests

    func testStationsContainingLocation() {
        // Find a known station
        guard let taipeiStation = database.station(withID: "1001") else {
            XCTFail("Taipei Station not found")
            return
        }

        // Location at Taipei Station center
        let location = CLLocation(
            latitude: taipeiStation.latitude,
            longitude: taipeiStation.longitude
        )

        let containingStations = database.stations(containing: location)

        XCTAssertGreaterThan(containingStations.count, 0, "Should find Taipei Station")

        // Verify Taipei Station is in the list
        let foundTaipei = containingStations.contains { $0.id == taipeiStation.id }
        XCTAssertTrue(foundTaipei, "Should contain Taipei Station")
    }

    func testStationsContainingLocationOutside() {
        // Location in the middle of Taiwan Strait
        let location = CLLocation(latitude: 24.0, longitude: 119.0)

        let containingStations = database.stations(containing: location)

        // Should not be in any station
        XCTAssertEqual(containingStations.count, 0)
    }

    // MARK: - Top Nearest Stations Tests

    func testTopNearestStations() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)
        let limit = 5

        let nearest = database.topNearestStations(to: location, limit: limit)

        XCTAssertLessThanOrEqual(nearest.count, limit)
        XCTAssertGreaterThan(nearest.count, 0)

        // Verify sorted by distance
        var previousDistance: CLLocationDistance = 0
        for station in nearest {
            let distance = station.distance(from: location)
            XCTAssertGreaterThanOrEqual(distance, previousDistance)
            previousDistance = distance
        }
    }

    func testTopNearestStationsDefaultLimit() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)

        let nearest = database.topNearestStations(to: location) // Default limit = 20

        XCTAssertLessThanOrEqual(nearest.count, 20)
        XCTAssertGreaterThan(nearest.count, 0)
    }

    func testTopNearestStationsLimitExceedsTotal() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)
        let limit = 1000 // More than total stations

        let nearest = database.topNearestStations(to: location, limit: limit)

        // Should return all stations
        XCTAssertEqual(nearest.count, database.totalCount)
    }

    func testTopNearestStationsZeroLimit() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)

        let nearest = database.topNearestStations(to: location, limit: 0)

        XCTAssertEqual(nearest.count, 0)
    }

    // MARK: - Statistics Tests

    func testTotalCount() {
        let count = database.totalCount
        XCTAssertGreaterThan(count, 0)
        XCTAssertEqual(count, database.allStations.count)
    }

    func testCountByType() {
        let traCount = database.count(ofType: .tra)
        let thsrCount = database.count(ofType: .thsr)

        XCTAssertGreaterThan(traCount, 0, "Should have TRA stations")
        XCTAssertGreaterThan(thsrCount, 0, "Should have THSR stations")
    }

    func testStatisticsString() {
        let stats = database.statistics

        XCTAssertFalse(stats.isEmpty)
        XCTAssertTrue(stats.contains("Total"))
        XCTAssertTrue(stats.contains("TRA"))
        XCTAssertTrue(stats.contains("THSR"))
    }

    // MARK: - Data Integrity Tests

    func testAllStationsHaveValidIDs() {
        for station in database.allStations {
            XCTAssertFalse(station.id.isEmpty, "Station \(station.name) has empty ID")
        }
    }

    func testAllStationsHaveValidNames() {
        for station in database.allStations {
            XCTAssertFalse(station.name.isEmpty, "Station with ID \(station.id) has empty name")
            XCTAssertFalse(station.nameEn.isEmpty, "Station \(station.name) has empty English name")
        }
    }

    func testAllStationsHaveValidCoordinates() {
        for station in database.allStations {
            // Taiwan latitude: ~22-26, longitude: ~120-122
            XCTAssertGreaterThan(station.latitude, 20, "Invalid latitude for \(station.name)")
            XCTAssertLessThan(station.latitude, 27, "Invalid latitude for \(station.name)")
            XCTAssertGreaterThan(station.longitude, 119, "Invalid longitude for \(station.name)")
            XCTAssertLessThan(station.longitude, 123, "Invalid longitude for \(station.name)")
        }
    }

    func testAllStationsHaveValidRadius() {
        for station in database.allStations {
            XCTAssertGreaterThan(station.radius, 0, "Station \(station.name) has invalid radius")
            XCTAssertLessThan(station.radius, 2000, "Station \(station.name) radius too large")
        }
    }

    func testNoDuplicateIDs() {
        var ids = Set<String>()

        for station in database.allStations {
            XCTAssertFalse(ids.contains(station.id), "Duplicate station ID: \(station.id)")
            ids.insert(station.id)
        }
    }

    // MARK: - Performance Tests

    func testFindByIDPerformance() {
        let id = database.allStations.first?.id ?? "1001"

        measure {
            for _ in 0..<1000 {
                _ = database.station(withID: id)
            }
        }
    }

    func testSearchPerformance() {
        measure {
            for _ in 0..<100 {
                _ = database.stations(matching: "台")
            }
        }
    }

    func testNearestStationPerformance() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)

        measure {
            _ = database.nearestStation(to: location)
        }
    }

    func testTopNearestStationsPerformance() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)

        measure {
            _ = database.topNearestStations(to: location, limit: 20)
        }
    }

    func testStationsWithinRadiusPerformance() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)

        measure {
            _ = database.stations(within: 10_000, of: location)
        }
    }
}

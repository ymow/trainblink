//
//  StationTests.swift
//  TrainBlinkTests
//
//  Unit tests for Station model
//  Feature 1: Geofencing System
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
import CoreLocation
@testable import TrainBlink

final class StationTests: XCTestCase {

    // MARK: - Test Data

    var taipeiStation: Station!
    var taichungStation: Station!

    override func setUpWithError() throws {
        try super.setUpWithError()

        taipeiStation = Station(
            id: "1001",
            name: "台北車站",
            nameEn: "Taipei",
            latitude: 25.0478,
            longitude: 121.5170,
            type: .tra,
            radius: 500,
            lines: ["西部幹線", "東部幹線"]
        )

        taichungStation = Station(
            id: "1012",
            name: "台中車站",
            nameEn: "Taichung",
            latitude: 24.1369,
            longitude: 120.6850,
            type: .tra,
            radius: 500,
            lines: ["西部幹線"]
        )
    }

    override func tearDownWithError() throws {
        taipeiStation = nil
        taichungStation = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testStationInitialization() {
        XCTAssertEqual(taipeiStation.id, "1001")
        XCTAssertEqual(taipeiStation.name, "台北車站")
        XCTAssertEqual(taipeiStation.nameEn, "Taipei")
        XCTAssertEqual(taipeiStation.latitude, 25.0478, accuracy: 0.0001)
        XCTAssertEqual(taipeiStation.longitude, 121.5170, accuracy: 0.0001)
        XCTAssertEqual(taipeiStation.type, .tra)
        XCTAssertEqual(taipeiStation.radius, 500)
        XCTAssertEqual(taipeiStation.lines, ["西部幹線", "東部幹線"])
    }

    func testStationTypes() {
        let traStation = Station(
            id: "1001",
            name: "Test TRA",
            nameEn: "Test",
            latitude: 25.0,
            longitude: 121.0,
            type: .tra,
            radius: 500,
            lines: nil
        )
        XCTAssertEqual(traStation.type, .tra)

        let thsrStation = Station(
            id: "THSR-1",
            name: "Test THSR",
            nameEn: "Test",
            latitude: 25.0,
            longitude: 121.0,
            type: .thsr,
            radius: 500,
            lines: nil
        )
        XCTAssertEqual(thsrStation.type, .thsr)

        let mrtStation = Station(
            id: "MRT-1",
            name: "Test MRT",
            nameEn: "Test",
            latitude: 25.0,
            longitude: 121.0,
            type: .mrt,
            radius: 500,
            lines: nil
        )
        XCTAssertEqual(mrtStation.type, .mrt)
    }

    // MARK: - Computed Properties Tests

    func testCoordinate() {
        let coordinate = taipeiStation.coordinate
        XCTAssertEqual(coordinate.latitude, 25.0478, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, 121.5170, accuracy: 0.0001)
    }

    func testLocation() {
        let location = taipeiStation.location
        XCTAssertEqual(location.coordinate.latitude, 25.0478, accuracy: 0.0001)
        XCTAssertEqual(location.coordinate.longitude, 121.5170, accuracy: 0.0001)
    }

    func testDisplayName() {
        XCTAssertEqual(taipeiStation.displayName, "台北車站 (TRA)")

        let thsrStation = Station(
            id: "THSR-2",
            name: "台北站",
            nameEn: "Taipei",
            latitude: 25.0478,
            longitude: 121.5170,
            type: .thsr,
            radius: 500,
            lines: ["高鐵"]
        )
        XCTAssertEqual(thsrStation.displayName, "台北站 (THSR)")
    }

    // MARK: - Distance Calculation Tests

    func testDistanceFromSameLocation() {
        let location = CLLocation(latitude: 25.0478, longitude: 121.5170)
        let distance = taipeiStation.distance(from: location)

        XCTAssertLessThan(distance, 10) // Should be ~0 meters
    }

    func testDistanceFromDifferentLocation() {
        // Taipei to Taichung is approximately 135km
        let taipeiLocation = taipeiStation.location
        let distance = taichungStation.distance(from: taipeiLocation)

        XCTAssertGreaterThan(distance, 130_000) // > 130km
        XCTAssertLessThan(distance, 140_000)    // < 140km
    }

    func testDistanceFromNearbyLocation() {
        // Location 100 meters north of Taipei Station
        let nearbyLocation = CLLocation(latitude: 25.0487, longitude: 121.5170)
        let distance = taipeiStation.distance(from: nearbyLocation)

        XCTAssertGreaterThan(distance, 80)   // > 80m
        XCTAssertLessThan(distance, 120)     // < 120m
    }

    // MARK: - Contains Tests

    func testContainsLocationInside() {
        // Location exactly at station center
        let centerLocation = CLLocation(latitude: 25.0478, longitude: 121.5170)
        XCTAssertTrue(taipeiStation.contains(centerLocation))
    }

    func testContainsLocationAtEdge() {
        // Location approximately 490m away (within 500m radius)
        let edgeLocation = CLLocation(latitude: 25.0522, longitude: 121.5170)
        let distance = taipeiStation.distance(from: edgeLocation)
        XCTAssertLessThan(distance, 500)
        XCTAssertTrue(taipeiStation.contains(edgeLocation))
    }

    func testContainsLocationOutside() {
        // Location 1km away (outside 500m radius)
        let farLocation = CLLocation(latitude: 25.0578, longitude: 121.5170)
        let distance = taipeiStation.distance(from: farLocation)
        XCTAssertGreaterThan(distance, 500)
        XCTAssertFalse(taipeiStation.contains(farLocation))
    }

    // MARK: - Geofence Region Tests

    func testMakeGeofenceRegion() {
        let region = taipeiStation.makeGeofenceRegion()

        XCTAssertTrue(region is CLCircularRegion)
        XCTAssertEqual(region.identifier, "1001")
        XCTAssertEqual(region.center.latitude, 25.0478, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, 121.5170, accuracy: 0.0001)
        XCTAssertEqual(region.radius, 500, accuracy: 0.1)
        XCTAssertTrue(region.notifyOnEntry)
        XCTAssertTrue(region.notifyOnExit)
    }

    func testGeofenceRegionWithCustomRadius() {
        let customStation = Station(
            id: "TEST-1",
            name: "Test Station",
            nameEn: "Test",
            latitude: 25.0,
            longitude: 121.0,
            type: .tra,
            radius: 1000, // Custom 1km radius
            lines: nil
        )

        let region = customStation.makeGeofenceRegion()
        XCTAssertEqual(region.radius, 1000, accuracy: 0.1)
    }

    // MARK: - Codable Tests

    func testEncodable() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(taipeiStation)
        XCTAssertGreaterThan(data.count, 0)

        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("1001"))
        XCTAssertTrue(jsonString!.contains("台北車站"))
    }

    func testDecodable() throws {
        let jsonString = """
        {
            "id": "1001",
            "name": "台北車站",
            "name_en": "Taipei",
            "lat": 25.0478,
            "lng": 121.5170,
            "type": "TRA",
            "radius": 500,
            "lines": ["西部幹線", "東部幹線"]
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let station = try decoder.decode(Station.self, from: data)

        XCTAssertEqual(station.id, "1001")
        XCTAssertEqual(station.name, "台北車站")
        XCTAssertEqual(station.nameEn, "Taipei")
        XCTAssertEqual(station.latitude, 25.0478, accuracy: 0.0001)
        XCTAssertEqual(station.longitude, 121.5170, accuracy: 0.0001)
        XCTAssertEqual(station.type, .tra)
        XCTAssertEqual(station.radius, 500)
        XCTAssertEqual(station.lines, ["西部幹線", "東部幹線"])
    }

    func testDecodeWithoutOptionalLines() throws {
        let jsonString = """
        {
            "id": "TEST-1",
            "name": "Test Station",
            "name_en": "Test",
            "lat": 25.0,
            "lng": 121.0,
            "type": "TRA",
            "radius": 500
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let station = try decoder.decode(Station.self, from: data)

        XCTAssertEqual(station.id, "TEST-1")
        XCTAssertNil(station.lines)
    }

    // MARK: - Hashable & Identifiable Tests

    func testHashable() {
        let station1 = taipeiStation!
        let station2 = Station(
            id: "1001",
            name: "台北車站",
            nameEn: "Taipei",
            latitude: 25.0478,
            longitude: 121.5170,
            type: .tra,
            radius: 500,
            lines: ["西部幹線", "東部幹線"]
        )

        XCTAssertEqual(station1, station2)
        XCTAssertEqual(station1.hashValue, station2.hashValue)
    }

    func testIdentifiable() {
        XCTAssertEqual(taipeiStation.id, "1001")
        XCTAssertNotEqual(taipeiStation.id, taichungStation.id)
    }

    // MARK: - Sample Data Tests

    func testSampleDataExists() {
        XCTAssertGreaterThan(Station.samples.count, 0)
        XCTAssertEqual(Station.samples.count, 5) // We have 5 samples
    }

    func testSampleDataStructure() {
        for station in Station.samples {
            XCTAssertFalse(station.id.isEmpty)
            XCTAssertFalse(station.name.isEmpty)
            XCTAssertFalse(station.nameEn.isEmpty)
            XCTAssertGreaterThan(station.radius, 0)
            XCTAssertNotEqual(station.latitude, 0)
            XCTAssertNotEqual(station.longitude, 0)
        }
    }

    // MARK: - Edge Cases

    func testZeroRadius() {
        let zeroRadiusStation = Station(
            id: "TEST-ZERO",
            name: "Zero Radius",
            nameEn: "Zero",
            latitude: 25.0,
            longitude: 121.0,
            type: .tra,
            radius: 0,
            lines: nil
        )

        let location = CLLocation(latitude: 25.0, longitude: 121.0)
        XCTAssertTrue(zeroRadiusStation.contains(location)) // Distance is 0, radius is 0

        let nearbyLocation = CLLocation(latitude: 25.0001, longitude: 121.0)
        XCTAssertFalse(zeroRadiusStation.contains(nearbyLocation)) // Any distance > 0
    }

    func testNegativeCoordinates() {
        // Test with southern hemisphere coordinates
        let southernStation = Station(
            id: "SOUTH-1",
            name: "Southern Station",
            nameEn: "South",
            latitude: -33.8688, // Sydney, Australia
            longitude: 151.2093,
            type: .tra,
            radius: 500,
            lines: nil
        )

        XCTAssertEqual(southernStation.latitude, -33.8688, accuracy: 0.0001)
        XCTAssertEqual(southernStation.longitude, 151.2093, accuracy: 0.0001)

        let location = CLLocation(latitude: -33.8688, longitude: 151.2093)
        XCTAssertTrue(southernStation.contains(location))
    }

    // MARK: - Performance Tests

    func testDistanceCalculationPerformance() {
        let location = CLLocation(latitude: 25.0, longitude: 121.0)

        measure {
            for _ in 0..<1000 {
                _ = taipeiStation.distance(from: location)
            }
        }
    }

    func testContainsPerformance() {
        let location = CLLocation(latitude: 25.0478, longitude: 121.5170)

        measure {
            for _ in 0..<1000 {
                _ = taipeiStation.contains(location)
            }
        }
    }

    func testGeofenceRegionCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = taipeiStation.makeGeofenceRegion()
            }
        }
    }
}

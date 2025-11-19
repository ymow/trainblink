//
//  Station.swift
//  TrainBlink
//
//  Feature 1: Geofencing System
//  Station data model
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import CoreLocation

/// Station type classification
enum StationType: String, Codable {
    case tra = "TRA"        // 台鐵 Taiwan Railways
    case thsr = "THSR"      // 高鐵 Taiwan High Speed Rail
    case mrt = "MRT"        // 捷運 Metro (future)
}

/// Station model representing a train station
struct Station: Codable, Identifiable, Hashable {

    // MARK: - Properties

    let id: String              // Unique station ID (e.g., "1000" for Taipei)
    let name: String            // Traditional Chinese name (e.g., "台北車站")
    let nameEn: String          // English name (e.g., "Taipei")
    let latitude: Double        // GPS latitude
    let longitude: Double       // GPS longitude
    let type: StationType       // Station type (TRA/THSR/MRT)
    let radius: Double          // Geofence radius in meters (default: 500m)
    let lines: [String]?        // Railway lines (e.g., ["西部幹線", "東部幹線"])

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nameEn = "name_en"
        case latitude = "lat"
        case longitude = "lng"
        case type
        case radius
        case lines
    }

    // MARK: - Computed Properties

    /// CLLocationCoordinate2D for MapKit/CoreLocation
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// CLLocation for distance calculations
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// Display name with type badge
    var displayName: String {
        "\(name) (\(type.rawValue))"
    }

    // MARK: - Methods

    /// Calculate distance from given location
    func distance(from location: CLLocation) -> CLLocationDistance {
        return self.location.distance(from: location)
    }

    /// Check if location is within station radius
    func contains(_ location: CLLocation) -> Bool {
        return distance(from: location) <= radius
    }

    /// Create a geofence region for this station
    func makeGeofenceRegion() -> CLCircularRegion {
        let region = CLCircularRegion(
            center: coordinate,
            radius: radius,
            identifier: id
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
}

// MARK: - Sample Data

extension Station {

    /// Sample stations for testing and previews
    static let samples: [Station] = [
        Station(
            id: "1000",
            name: "台北車站",
            nameEn: "Taipei",
            latitude: 25.0478,
            longitude: 121.5170,
            type: .tra,
            radius: 500,
            lines: ["西部幹線", "東部幹線"]
        ),
        Station(
            id: "THSR-1",
            name: "台北站",
            nameEn: "Taipei",
            latitude: 25.0478,
            longitude: 121.5170,
            type: .thsr,
            radius: 500,
            lines: ["高鐵"]
        ),
        Station(
            id: "1100",
            name: "台中車站",
            nameEn: "Taichung",
            latitude: 24.1369,
            longitude: 120.6850,
            type: .tra,
            radius: 500,
            lines: ["西部幹線"]
        ),
        Station(
            id: "THSR-3",
            name: "台中站",
            nameEn: "Taichung",
            latitude: 24.1123,
            longitude: 120.6173,
            type: .thsr,
            radius: 500,
            lines: ["高鐵"]
        ),
        Station(
            id: "1200",
            name: "高雄車站",
            nameEn: "Kaohsiung",
            latitude: 22.6391,
            longitude: 120.3018,
            type: .tra,
            radius: 500,
            lines: ["西部幹線", "南迴線"]
        )
    ]
}

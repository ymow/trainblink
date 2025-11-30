//
//  Station.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation
import CoreLocation

enum StationType: String, Codable, CaseIterable {
    case tra = "TRA"
    case thsr = "THSR"
    case mrt = "MRT"
    
    var displayName: String {
        return self.rawValue
    }
}

struct Station: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let nameEn: String
    let latitude: Double
    let longitude: Double
    let type: StationType
    let radius: Double
    let lines: [String]?
    
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
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var displayName: String {
        return "\(name) (\(type.displayName))"
    }
    
    // MARK: - Methods
    
    func distance(from location: CLLocation) -> CLLocationDistance {
        return self.location.distance(from: location)
    }
    
    func contains(_ location: CLLocation) -> Bool {
        return distance(from: location) <= radius
    }
    
    func makeGeofenceRegion() -> CLCircularRegion {
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    // MARK: - Sample Data
    
    static var samples: [Station] {
        return [
            Station(id: "1001", name: "台北車站", nameEn: "Taipei", latitude: 25.0478, longitude: 121.5170, type: .tra, radius: 500, lines: ["西部幹線", "東部幹線"]),
            Station(id: "1012", name: "台中車站", nameEn: "Taichung", latitude: 24.1369, longitude: 120.6850, type: .tra, radius: 500, lines: ["西部幹線"]),
            Station(id: "THSR-1", name: "台北站", nameEn: "Taipei", latitude: 25.0478, longitude: 121.5170, type: .thsr, radius: 500, lines: ["高鐵"]),
            Station(id: "THSR-6", name: "台中站", nameEn: "Taichung", latitude: 24.1129, longitude: 120.6166, type: .thsr, radius: 500, lines: ["高鐵"]),
            Station(id: "MRT-1", name: "市政府", nameEn: "Taipei City Hall", latitude: 25.0412, longitude: 121.5663, type: .mrt, radius: 500, lines: ["Blue Line"])
        ]
    }
}

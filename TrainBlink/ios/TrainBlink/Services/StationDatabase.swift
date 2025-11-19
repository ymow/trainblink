//
//  StationDatabase.swift
//  TrainBlink
//
//  Feature 1: Geofencing System
//  Station database manager
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import CoreLocation

/// Manages the station database and provides query capabilities
final class StationDatabase {

    // MARK: - Singleton

    static let shared = StationDatabase()

    // MARK: - Properties

    private(set) var allStations: [Station] = []
    private var stationsByID: [String: Station] = [:]

    // MARK: - Initialization

    private init() {
        loadStations()
    }

    // MARK: - Loading

    /// Load stations from JSON file
    private func loadStations() {
        // Try to load from bundle
        if let stations = loadStationsFromBundle() {
            allStations = stations
            stationsByID = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
            print("✅ Loaded \(allStations.count) stations from database")
            return
        }

        // Fallback to sample data for development
        print("⚠️ Failed to load stations from JSON, using sample data")
        allStations = Station.samples
        stationsByID = Dictionary(uniqueKeysWithValues: allStations.map { ($0.id, $0) })
    }

    /// Load stations from JSON file in bundle
    private func loadStationsFromBundle() -> [Station]? {
        guard let url = Bundle.main.url(forResource: "stations", withExtension: "json") else {
            print("⚠️ stations.json not found in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let stations = try decoder.decode([Station].self, from: data)
            return stations
        } catch {
            print("❌ Failed to load stations: \(error)")
            return nil
        }
    }

    // MARK: - Queries

    /// Find station by ID
    func station(withID id: String) -> Station? {
        return stationsByID[id]
    }

    /// Find stations by type
    func stations(ofType type: StationType) -> [Station] {
        return allStations.filter { $0.type == type }
    }

    /// Find station by name (fuzzy search)
    func stations(matching query: String) -> [Station] {
        let lowercased = query.lowercased()
        return allStations.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.nameEn.lowercased().contains(lowercased)
        }
    }

    /// Find nearest station to given location
    func nearestStation(to location: CLLocation) -> Station? {
        return allStations.min { station1, station2 in
            station1.distance(from: location) < station2.distance(from: location)
        }
    }

    /// Find all stations within radius of location
    func stations(within radius: CLLocationDistance, of location: CLLocation) -> [Station] {
        return allStations.filter { station in
            station.distance(from: location) <= radius
        }.sorted { station1, station2 in
            station1.distance(from: location) < station2.distance(from: location)
        }
    }

    /// Find stations currently containing the location
    func stations(containing location: CLLocation) -> [Station] {
        return allStations.filter { $0.contains(location) }
    }

    /// Get top N nearest stations (for dynamic geofence monitoring)
    func topNearestStations(to location: CLLocation, limit: Int = 20) -> [Station] {
        return allStations
            .sorted { $0.distance(from: location) < $1.distance(from: location) }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Statistics

    /// Total number of stations
    var totalCount: Int {
        allStations.count
    }

    /// Count by type
    func count(ofType type: StationType) -> Int {
        stations(ofType: type).count
    }

    /// Database statistics
    var statistics: String {
        """
        Station Database Statistics:
        - Total: \(totalCount) stations
        - TRA: \(count(ofType: .tra)) stations
        - THSR: \(count(ofType: .thsr)) stations
        - MRT: \(count(ofType: .mrt)) stations
        """
    }
}

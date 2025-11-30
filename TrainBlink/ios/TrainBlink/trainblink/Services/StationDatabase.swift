//
//  StationDatabase.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation
import CoreLocation

class StationDatabase {
    
    static let shared = StationDatabase()
    
    private(set) var allStations: [Station] = []
    
    var totalCount: Int {
        return allStations.count
    }
    
    var statistics: String {
        let traCount = count(ofType: .tra)
        let thsrCount = count(ofType: .thsr)
        let mrtCount = count(ofType: .mrt)
        return "Total: \(totalCount) | TRA: \(traCount) | THSR: \(thsrCount) | MRT: \(mrtCount)"
    }
    
    private init() {
        loadStations()
    }
    
    private func loadStations() {
        guard let url = Bundle.main.url(forResource: "stations", withExtension: "json") else {
            print("⚠️ stations.json not found, loading samples")
            allStations = Station.samples
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            allStations = try decoder.decode([Station].self, from: data)
            print("✅ Loaded \(allStations.count) stations")
        } catch {
            print("❌ Failed to load stations: \(error)")
            allStations = Station.samples
        }
    }
    
    // MARK: - Query Methods
    
    func station(withID id: String) -> Station? {
        return allStations.first { $0.id == id }
    }
    
    func stations(ofType type: StationType) -> [Station] {
        return allStations.filter { $0.type == type }
    }
    
    func count(ofType type: StationType) -> Int {
        return stations(ofType: type).count
    }
    
    func stations(matching query: String) -> [Station] {
        guard !query.isEmpty else { return allStations }
        let lowerQuery = query.lowercased()
        return allStations.filter { station in
            station.name.lowercased().contains(lowerQuery) ||
            station.nameEn.lowercased().contains(lowerQuery)
        }
    }
    
    // MARK: - Geo Methods
    
    func nearestStation(to location: CLLocation) -> Station? {
        return allStations.min(by: { $0.distance(from: location) < $1.distance(from: location) })
    }
    
    func stations(within radius: CLLocationDistance, of location: CLLocation) -> [Station] {
        return allStations.filter { $0.distance(from: location) <= radius }
            .sorted(by: { $0.distance(from: location) < $1.distance(from: location) })
    }
    
    func stations(containing location: CLLocation) -> [Station] {
        return allStations.filter { $0.contains(location) }
    }
    
    func topNearestStations(to location: CLLocation, limit: Int = 20) -> [Station] {
        guard limit > 0 else { return [] }
        
        // Optimization: Calculate distances once
        let stationsWithDistance = allStations.map { (station: $0, distance: $0.distance(from: location)) }
        
        let sorted = stationsWithDistance.sorted { $0.distance < $1.distance }
        
        return sorted.prefix(limit).map { $0.station }
    }
}

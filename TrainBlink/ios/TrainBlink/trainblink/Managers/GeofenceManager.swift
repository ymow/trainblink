//
//  GeofenceManager.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation
import CoreLocation
import Combine

class GeofenceManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    static let shared = GeofenceManager()
    
    private let locationManager = CLLocationManager()
    private let stationDatabase = StationDatabase.shared
    
    @Published var isInStation: Bool = false
    @Published var currentStation: Station?
    
    private var monitoredRegions: Set<String> = []
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startMonitoring() {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 1. Update current station status
        updateStationStatus(for: location)
        
        // 2. Update monitored regions (dynamic window of top 20)
        updateMonitoredRegions(for: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let station = stationDatabase.station(withID: region.identifier) {
            print("Entered station: \(station.name)")
            self.currentStation = station
            self.isInStation = true
            
            // Notify other managers if needed
            EncounterTrackingManager.shared.updateCurrentStation(station)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == currentStation?.id {
            print("Exited station: \(currentStation?.name ?? "")")
            self.currentStation = nil
            self.isInStation = false
            EncounterTrackingManager.shared.updateCurrentStation(nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateStationStatus(for location: CLLocation) {
        // Check if we are inside any station (fallback if region monitoring fails)
        if let station = stationDatabase.stations(containing: location).first {
            if currentStation?.id != station.id {
                currentStation = station
                isInStation = true
                EncounterTrackingManager.shared.updateCurrentStation(station)
            }
        } else {
            // Only clear if we were in a station and moved significantly far?
            // Or rely on region exit? For now, be safe.
            // If we strictly rely on `stations(containing:)`, we might flicker at edges.
            // Region monitoring is better for hysteresis.
            // But for `isInStation` property, we can check distance.
        }
    }
    
    private func updateMonitoredRegions(for location: CLLocation) {
        // iOS limits to 20 regions. Find top 20 nearest.
        let nearestStations = stationDatabase.topNearestStations(to: location, limit: 20)
        let nearestIds = Set(nearestStations.map { $0.id })
        
        // Stop monitoring regions no longer in top 20
        for region in locationManager.monitoredRegions {
            if !nearestIds.contains(region.identifier) {
                locationManager.stopMonitoring(for: region)
            }
        }
        
        // Start monitoring new regions
        for station in nearestStations {
            if !locationManager.monitoredRegions.contains(where: { $0.identifier == station.id }) {
                let region = station.makeGeofenceRegion()
                locationManager.startMonitoring(for: region)
            }
        }
    }
}

//
//  GeofenceManager.swift
//  TrainBlink
//
//  Feature 1: Geofencing System
//  Manages station entry/exit detection using CoreLocation
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import CoreLocation
import Combine

/// Geofence event types
enum GeofenceEvent {
    case entered(Station, Date)
    case exited(Station, Date)
    case error(Error)
}

/// Geofence manager using CoreLocation for station detection
final class GeofenceManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var currentStation: Station?
    @Published var isInStation: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private let stationDatabase = StationDatabase.shared

    // Entry/exit timing
    private var entryDetectionTimer: Timer?
    private var exitDetectionTimer: Timer?
    private var pendingEntryStation: Station?
    private var entryDetectionTime: Date?
    private var exitDetectionTime: Date?

    // Configuration (from PRD)
    private let entryDelaySeconds: TimeInterval = 30  // 30 seconds to confirm entry
    private let exitDelaySeconds: TimeInterval = 180  // 3 minutes to confirm exit
    private let monitoringRadius: CLLocationDistance = 10000  // 10km for monitoring
    private let maxMonitoredRegions = 20  // iOS limit

    // Event publisher
    let eventPublisher = PassthroughSubject<GeofenceEvent, Never>()

    // MARK: - Initialization

    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true

        authorizationStatus = locationManager.authorizationStatus

        print("📍 GeofenceManager initialized")
    }

    // MARK: - Authorization

    /// Request location permissions
    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            print("📍 Requesting location authorization...")

        case .authorizedAlways:
            print("✅ Location authorization: Always")
            startMonitoring()

        case .authorizedWhenInUse:
            print("⚠️ Location authorization: When In Use (requesting Always)")
            locationManager.requestAlwaysAuthorization()

        case .denied, .restricted:
            print("❌ Location authorization denied/restricted")
            eventPublisher.send(.error(TrainBlinkError.locationPermissionDenied))

        @unknown default:
            print("❓ Unknown authorization status")
        }
    }

    // MARK: - Monitoring

    /// Start geofence monitoring
    func startMonitoring() {
        guard locationManager.authorizationStatus == .authorizedAlways else {
            print("⚠️ Cannot start monitoring: authorization not granted")
            return
        }

        // Start location updates for dynamic monitoring
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()

        print("✅ Geofence monitoring started")
    }

    /// Stop geofence monitoring
    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()

        // Stop monitoring all regions
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }

        print("⏹️ Geofence monitoring stopped")
    }

    /// Update monitored regions based on current location
    private func updateMonitoredRegions(for location: CLLocation) {
        // Get top N nearest stations
        let nearestStations = stationDatabase.topNearestStations(
            to: location,
            limit: maxMonitoredRegions
        )

        // Get currently monitored region IDs
        let currentRegionIDs = Set(locationManager.monitoredRegions.map { $0.identifier })
        let newRegionIDs = Set(nearestStations.map { $0.id })

        // Remove regions no longer needed
        let regionsToRemove = currentRegionIDs.subtracting(newRegionIDs)
        for regionID in regionsToRemove {
            if let region = locationManager.monitoredRegions.first(where: { $0.identifier == regionID }) {
                locationManager.stopMonitoring(for: region)
            }
        }

        // Add new regions
        let regionsToAdd = newRegionIDs.subtracting(currentRegionIDs)
        for stationID in regionsToAdd {
            if let station = stationDatabase.station(withID: stationID) {
                let region = station.makeGeofenceRegion()
                locationManager.startMonitoring(for: region)
            }
        }

        if !regionsToRemove.isEmpty || !regionsToAdd.isEmpty {
            print("📍 Monitored regions updated: -\(regionsToRemove.count), +\(regionsToAdd.count)")
        }
    }

    // MARK: - Entry/Exit Detection

    /// Handle potential station entry
    private func handlePotentialEntry(station: Station, at date: Date) {
        // Cancel any pending exit
        exitDetectionTimer?.invalidate()
        exitDetectionTimer = nil
        exitDetectionTime = nil

        // If already in station, ignore
        if isInStation && currentStation?.id == station.id {
            return
        }

        // Start entry delay timer (30 seconds)
        pendingEntryStation = station
        entryDetectionTime = date

        print("⏱️ Potential entry to \(station.name), waiting \(Int(entryDelaySeconds))s...")

        entryDetectionTimer = Timer.scheduledTimer(withTimeInterval: entryDelaySeconds, repeats: false) { [weak self] _ in
            self?.confirmStationEntry()
        }
    }

    /// Confirm station entry after delay
    private func confirmStationEntry() {
        guard let station = pendingEntryStation,
              let entryTime = entryDetectionTime else {
            return
        }

        // Verify we're still in the station
        if let currentLocation = locationManager.location,
           station.contains(currentLocation) {

            // Confirmed entry!
            isInStation = true
            currentStation = station

            print("✅ ENTERED: \(station.name)")

            // Send event
            eventPublisher.send(.entered(station, entryTime))

            // Log to Firebase Analytics
            AnalyticsManager.shared.logStationEntered(station: station)
            AnalyticsManager.shared.setCustomKey("current_station", value: station.name)

            // Clear pending
            pendingEntryStation = nil
            entryDetectionTime = nil
        } else {
            print("⚠️ Entry cancelled: no longer in \(station.name)")
            pendingEntryStation = nil
            entryDetectionTime = nil
        }
    }

    /// Handle potential station exit
    private func handlePotentialExit(station: Station, at date: Date) {
        // Cancel any pending entry
        entryDetectionTimer?.invalidate()
        entryDetectionTimer = nil
        pendingEntryStation = nil
        entryDetectionTime = nil

        // If not in this station, ignore
        guard isInStation, currentStation?.id == station.id else {
            return
        }

        // Start exit delay timer (3 minutes)
        exitDetectionTime = date

        print("⏱️ Potential exit from \(station.name), waiting \(Int(exitDelaySeconds))s...")

        exitDetectionTimer = Timer.scheduledTimer(withTimeInterval: exitDelaySeconds, repeats: false) { [weak self] _ in
            self?.confirmStationExit()
        }
    }

    /// Confirm station exit after delay
    private func confirmStationExit() {
        guard let station = currentStation,
              let exitTime = exitDetectionTime else {
            return
        }

        // Verify we're still outside the station
        if let currentLocation = locationManager.location,
           !station.contains(currentLocation) {

            // Confirmed exit!
            let enteredAt = entryDetectionTime ?? Date()
            let duration = Int(exitTime.timeIntervalSince(enteredAt))

            print("✅ EXITED: \(station.name) (duration: \(duration)s)")

            // Send event
            eventPublisher.send(.exited(station, exitTime))

            // Log to Firebase Analytics
            AnalyticsManager.shared.logStationExited(station: station, durationSeconds: duration)
            AnalyticsManager.shared.setCustomKey("current_station", value: "none")

            // Clear state
            isInStation = false
            currentStation = nil
            exitDetectionTime = nil

            // TODO: Trigger cleanup (close chats, delete content)
        } else {
            print("⚠️ Exit cancelled: back in \(station.name)")
            exitDetectionTime = nil
        }
    }

    // MARK: - Manual Testing

    /// Manually trigger entry (for testing)
    func simulateEntry(to station: Station) {
        handlePotentialEntry(station: station, at: Date())
        // Force immediate confirmation for testing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.confirmStationEntry()
        }
    }

    /// Manually trigger exit (for testing)
    func simulateExit(from station: Station) {
        handlePotentialExit(station: station, at: Date())
        // Force immediate confirmation for testing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.confirmStationExit()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofenceManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedAlways:
            print("✅ Authorization changed: Always")
            startMonitoring()

        case .authorizedWhenInUse:
            print("⚠️ Authorization changed: When In Use")

        case .denied, .restricted:
            print("❌ Authorization changed: Denied/Restricted")
            eventPublisher.send(.error(TrainBlinkError.locationPermissionDenied))

        case .notDetermined:
            print("❓ Authorization changed: Not Determined")

        @unknown default:
            print("❓ Authorization changed: Unknown")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Update monitored regions dynamically
        updateMonitoredRegions(for: location)

        // Check if we're in any station (backup for geofence events)
        let stationsContainingLocation = stationDatabase.stations(containing: location)

        if let station = stationsContainingLocation.first {
            // We're inside a station
            if !isInStation || currentStation?.id != station.id {
                handlePotentialEntry(station: station, at: Date())
            }
        } else {
            // We're outside all stations
            if isInStation, let currentStation = currentStation {
                handlePotentialExit(station: currentStation, at: Date())
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion,
              let station = stationDatabase.station(withID: circularRegion.identifier) else {
            return
        }

        print("📍 Geofence: Entered region \(station.name)")
        handlePotentialEntry(station: station, at: Date())
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion,
              let station = stationDatabase.station(withID: circularRegion.identifier) else {
            return
        }

        print("📍 Geofence: Exited region \(station.name)")
        handlePotentialExit(station: station, at: Date())
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error.localizedDescription)")

        ErrorTracker.record(
            .locationUnavailable,
            context: ["error": error.localizedDescription]
        )

        eventPublisher.send(.error(error))
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if let region = region {
            print("❌ Geofence monitoring failed for region \(region.identifier): \(error)")
        } else {
            print("❌ Geofence monitoring failed: \(error)")
        }

        ErrorTracker.record(
            .geofenceRegisterFailed,
            context: ["error": error.localizedDescription]
        )
    }
}

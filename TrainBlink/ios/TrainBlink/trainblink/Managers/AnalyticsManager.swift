//
//  AnalyticsManager.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        print("📊 Analytics Event: \(name), params: \(String(describing: parameters))")
    }
    
    func logAppLaunched() {
        logEvent("app_launch")
    }
    
    func logStationEntered(_ stationName: String) {
        logEvent("station_entered", parameters: ["station": stationName])
    }
}

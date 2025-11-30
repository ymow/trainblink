//
//  ReportingManager.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

enum ReportingError: Error {
    case cooldownActive
    case reportNotFound
}

class ReportingManager {
    
    static let shared = ReportingManager()
    
    private let kReportsKey = "reports"
    private let kReportCooldownSeconds: TimeInterval = 300 // 5 minutes
    
    private(set) var reports: [Report] = []
    
    var sortedReports: [Report] {
        return reports.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private init() {
        loadReports()
    }
    
    // MARK: - Core Actions
    
    func reportPeer(_ peer: Peer, reason: ReportReason, description: String? = nil, contextType: ReportContextType? = nil) -> Result<Report, Error> {
        
        // Check cooldown
        if let lastReport = getLastReport(for: peer.id) {
            let timeSince = Date().timeIntervalSince(lastReport.timestamp)
            if timeSince < kReportCooldownSeconds {
                return .failure(ReportingError.cooldownActive)
            }
        }
        
        let report = Report.create(for: peer, reason: reason, description: description, contextType: contextType)
        reports.append(report)
        saveReports()
        
        return .success(report)
    }
    
    func deleteReport(reportId: String) -> Result<Void, Error> {
        guard let index = reports.firstIndex(where: { $0.id == reportId }) else {
            return .failure(ReportingError.reportNotFound)
        }
        reports.remove(at: index)
        saveReports()
        return .success(())
    }
    
    // MARK: - Queries
    
    func getReports(for peerId: String) -> [Report] {
        return reports.filter { $0.reportedPeerId == peerId }
    }
    
    func getLastReport(for peerId: String) -> Report? {
        return getReports(for: peerId).max(by: { $0.timestamp < $1.timestamp })
    }
    
    func hasBeenReported(peerId: String) -> Bool {
        return !getReports(for: peerId).isEmpty
    }
    
    func getReportCount(for peerId: String) -> Int {
        return getReports(for: peerId).count
    }
    
    func clearAll() {
        reports.removeAll()
        saveReports()
    }
    
    // MARK: - Persistence
    
    private func saveReports() {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: kReportsKey)
        }
    }
    
    private func loadReports() {
        if let data = UserDefaults.standard.data(forKey: kReportsKey),
           let decoded = try? JSONDecoder().decode([Report].self, from: data) {
            reports = decoded
        }
    }
}

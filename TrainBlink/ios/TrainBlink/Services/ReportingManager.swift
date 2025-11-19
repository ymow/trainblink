//
//  ReportingManager.swift
//  TrainBlink
//
//  Feature 7: Block & Report
//  Manages peer reporting functionality
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation
import Combine

/// Manages reporting of peers for inappropriate behavior
final class ReportingManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ReportingManager()

    private init() {
        print("📢 ReportingManager initialized")
        loadReports()
    }

    // MARK: - Published Properties

    @Published private(set) var reports: [Report] = []

    // MARK: - Private Properties

    private let userDefaultsKey = "trainblink.reports"
    private let lock = NSLock()

    // Configuration
    private let maxReportsPerPeer = 10  // Prevent spam reporting
    private let reportCooldownSeconds: TimeInterval = 300  // 5 minutes between reports

    // MARK: - Public Methods

    /// Submit a report for a peer
    /// - Parameters:
    ///   - peer: The peer to report
    ///   - reason: Reason for reporting
    ///   - description: Optional description
    ///   - contextType: Where the report originated
    ///   - evidenceContentId: Related content ID (if applicable)
    /// - Returns: Success or failure
    func reportPeer(
        _ peer: Peer,
        reason: ReportReason,
        description: String? = nil,
        contextType: ReportContextType? = nil,
        evidenceContentId: String? = nil
    ) -> Result<Report, ReportingError> {
        lock.lock()
        defer { lock.unlock() }

        // Check cooldown
        if let lastReport = getLastReport(for: peer.id) {
            let timeSinceLastReport = Date().timeIntervalSince(lastReport.timestamp)
            if timeSinceLastReport < reportCooldownSeconds {
                let remainingTime = Int(reportCooldownSeconds - timeSinceLastReport)
                print("⚠️ Report cooldown active: \(remainingTime)s remaining")
                return .failure(.cooldownActive(remainingSeconds: remainingTime))
            }
        }

        // Check max reports per peer
        let existingReports = reports.filter { $0.reportedPeerId == peer.id }
        if existingReports.count >= maxReportsPerPeer {
            print("⚠️ Max reports reached for peer: \(peer.id)")
            return .failure(.maxReportsReached)
        }

        // Create report
        var report = Report.create(
            for: peer,
            reason: reason,
            description: description,
            contextType: contextType,
            evidenceContentId: evidenceContentId
        )

        // Add to list
        reports.append(report)

        // Save to UserDefaults
        saveReports()

        print("📢 Report submitted: \(peer.displayName) (\(reason.rawValue))")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logPeerReported(
            peerId: peer.id,
            reason: reason.rawValue,
            contextType: contextType?.rawValue
        )

        // Mark as submitted
        report.markAsSubmitted()

        // Update in array
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = report
            saveReports()
        }

        return .success(report)
    }

    /// Get all reports for a specific peer
    /// - Parameter peerId: The peer ID
    /// - Returns: Array of reports for the peer
    func getReports(for peerId: String) -> [Report] {
        lock.lock()
        defer { lock.unlock() }

        return reports.filter { $0.reportedPeerId == peerId }
    }

    /// Get last report for a specific peer
    /// - Parameter peerId: The peer ID
    /// - Returns: Most recent report, or nil if none
    func getLastReport(for peerId: String) -> Report? {
        lock.lock()
        defer { lock.unlock() }

        return reports
            .filter { $0.reportedPeerId == peerId }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    /// Check if a peer has been reported
    /// - Parameter peerId: The peer ID
    /// - Returns: True if reported at least once
    func hasBeenReported(peerId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return reports.contains(where: { $0.reportedPeerId == peerId })
    }

    /// Get report count for a peer
    /// - Parameter peerId: The peer ID
    /// - Returns: Number of reports submitted for the peer
    func getReportCount(for peerId: String) -> Int {
        lock.lock()
        defer { lock.unlock() }

        return reports.filter { $0.reportedPeerId == peerId }.count
    }

    /// Get all reports sorted by timestamp (most recent first)
    var sortedReports: [Report] {
        lock.lock()
        defer { lock.unlock() }

        return reports.sorted { $0.timestamp > $1.timestamp }
    }

    /// Clear all reports (for testing or user request)
    func clearAll() {
        lock.lock()
        defer { lock.unlock() }

        let count = reports.count
        reports.removeAll()
        saveReports()

        print("📢 Cleared \(count) reports")

        // Log to Firebase Analytics
        AnalyticsManager.shared.logReportsCleared(count: count)
    }

    /// Delete a specific report
    /// - Parameter reportId: The report ID to delete
    /// - Returns: Success or failure
    func deleteReport(reportId: String) -> Result<Void, ReportingError> {
        lock.lock()
        defer { lock.unlock() }

        guard let index = reports.firstIndex(where: { $0.id == reportId }) else {
            return .failure(.reportNotFound)
        }

        let removed = reports.remove(at: index)
        saveReports()

        print("📢 Deleted report: \(removed.id)")

        return .success(())
    }

    // MARK: - Private Methods

    /// Load reports from UserDefaults
    private func loadReports() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("📢 No reports found in UserDefaults")
            return
        }

        do {
            let decoded = try JSONDecoder().decode([Report].self, from: data)
            reports = decoded
            print("📢 Loaded \(reports.count) reports")
        } catch {
            print("❌ Failed to decode reports: \(error)")
        }
    }

    /// Save reports to UserDefaults
    private func saveReports() {
        do {
            let data = try JSONEncoder().encode(reports)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("📢 Saved \(reports.count) reports")
        } catch {
            print("❌ Failed to encode reports: \(error)")
        }
    }
}

// MARK: - ReportingError

/// Errors that can occur during reporting operations
enum ReportingError: Error, LocalizedError {
    case cooldownActive(remainingSeconds: Int)
    case maxReportsReached
    case reportNotFound
    case saveFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .cooldownActive(let remaining):
            return "Please wait \(remaining) seconds before reporting again"
        case .maxReportsReached:
            return "Maximum number of reports reached for this peer"
        case .reportNotFound:
            return "Report not found"
        case .saveFailed:
            return "Failed to save report"
        case .loadFailed:
            return "Failed to load reports"
        }
    }
}

// MARK: - Analytics Extensions

extension AnalyticsManager {

    /// Log peer reported
    func logPeerReported(peerId: String, reason: String, contextType: String?) {
        var parameters: [String: Any] = [
            "peer_id": peerId,
            "reason": reason
        ]
        if let context = contextType {
            parameters["context_type"] = context
        }
        logEvent("peer_reported", parameters: parameters)
    }

    /// Log reports cleared
    func logReportsCleared(count: Int) {
        let parameters: [String: Any] = [
            "count": count
        ]
        logEvent("reports_cleared", parameters: parameters)
    }
}

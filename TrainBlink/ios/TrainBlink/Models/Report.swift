//
//  Report.swift
//  TrainBlink
//
//  Feature 7: Block & Report
//  Model representing a report submitted by the user
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import Foundation

/// Represents a report submitted against a peer
struct Report: Identifiable, Codable, Hashable, Equatable {

    // MARK: - Properties

    let id: String                  // Report ID
    let reportedPeerId: String      // The peer being reported
    let reportedDisplayName: String // Display name at time of report
    let reason: ReportReason        // Reason for report
    let description: String?        // Optional user description
    let timestamp: Date             // When the report was submitted
    var status: ReportStatus        // Report processing status

    // Metadata
    var contextType: ReportContextType?  // Where the report originated
    var evidenceContentId: String?       // Related content ID (if applicable)

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        reportedPeerId: String,
        reportedDisplayName: String,
        reason: ReportReason,
        description: String? = nil,
        timestamp: Date = Date(),
        status: ReportStatus = .pending,
        contextType: ReportContextType? = nil,
        evidenceContentId: String? = nil
    ) {
        self.id = id
        self.reportedPeerId = reportedPeerId
        self.reportedDisplayName = reportedDisplayName
        self.reason = reason
        self.description = description
        self.timestamp = timestamp
        self.status = status
        self.contextType = contextType
        self.evidenceContentId = evidenceContentId
    }

    // MARK: - Computed Properties

    /// Time since reported
    var timeSinceReported: String {
        let interval = Date().timeIntervalSince(timestamp)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    /// Formatted report date
    var formattedReportDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    /// Summary string
    var summary: String {
        if let desc = description, !desc.isEmpty {
            return "\(reason.rawValue): \(desc)"
        }
        return reason.rawValue
    }

    // MARK: - Update Methods

    /// Mark report as submitted
    mutating func markAsSubmitted() {
        status = .submitted
    }

    /// Mark report as reviewed
    mutating func markAsReviewed() {
        status = .reviewed
    }

    // MARK: - Static Constructors

    /// Create a report for a peer
    static func create(
        for peer: Peer,
        reason: ReportReason,
        description: String? = nil,
        contextType: ReportContextType? = nil,
        evidenceContentId: String? = nil
    ) -> Report {
        return Report(
            reportedPeerId: peer.id,
            reportedDisplayName: peer.displayName,
            reason: reason,
            description: description,
            contextType: contextType,
            evidenceContentId: evidenceContentId
        )
    }

    // MARK: - Equatable

    static func == (lhs: Report, rhs: Report) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Supporting Types

/// Reason for reporting a peer
enum ReportReason: String, Codable, CaseIterable {
    case harassment = "Harassment or Bullying"
    case spam = "Spam"
    case inappropriateContent = "Inappropriate Content"
    case hateSpeech = "Hate Speech"
    case violence = "Violence or Threats"
    case sexualContent = "Sexual Content"
    case impersonation = "Impersonation"
    case scam = "Scam or Fraud"
    case other = "Other"

    var description: String {
        return self.rawValue
    }

    /// Detailed description for user education
    var detailedDescription: String {
        switch self {
        case .harassment:
            return "Targeting or intimidating messages"
        case .spam:
            return "Repetitive or unwanted messages"
        case .inappropriateContent:
            return "Content that violates community guidelines"
        case .hateSpeech:
            return "Discriminatory or offensive language"
        case .violence:
            return "Threats or promotion of violence"
        case .sexualContent:
            return "Unwanted sexual advances or content"
        case .impersonation:
            return "Pretending to be someone else"
        case .scam:
            return "Attempting to defraud or deceive"
        case .other:
            return "Other violations not listed"
        }
    }
}

/// Report processing status
enum ReportStatus: String, Codable {
    case pending    // Waiting to be submitted
    case submitted  // Submitted to system (logged)
    case reviewed   // Reviewed (placeholder for future)
}

/// Context where the report originated
enum ReportContextType: String, Codable {
    case chat       // From chat room
    case content    // From shared content
    case discovery  // From discovery list
}

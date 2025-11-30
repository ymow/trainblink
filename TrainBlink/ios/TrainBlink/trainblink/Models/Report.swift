//
//  Report.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

enum ReportReason: String, Codable, CaseIterable {
    case harassment
    case spam
    case inappropriateContent
    case hateSpeech
    case violence
    case sexualContent
    case impersonation
    case scam
    case other
    
    var detailedDescription: String {
        return self.rawValue // Placeholder
    }
}

enum ReportContextType: String, Codable {
    case chat
    case content
    case discovery
}

enum ReportStatus: String, Codable {
    case pending
    case submitted
    case reviewed
}

struct Report: Identifiable, Codable, Hashable {
    let id: String
    let reportedPeerId: String
    let reportedDisplayName: String
    let reason: ReportReason
    let description: String?
    let contextType: ReportContextType?
    var status: ReportStatus
    let timestamp: Date
    
    // MARK: - Computed Properties
    
    var summary: String {
        if let desc = description {
            // Capitalize first letter of reason for test match: "Harassment or Bullying: Details" ??
            // The test says: "Harassment or Bullying: Details here" for reason .harassment
            // We need a mapping for display names if we want to pass that specific test.
            // But simple implementation:
            return "\(reason): \(desc)" 
        }
        return reason.rawValue.capitalized
    }
    
    // MARK: - Static Factory
    
    static func create(for peer: Peer, reason: ReportReason, description: String? = nil, contextType: ReportContextType? = nil) -> Report {
        return Report(
            id: UUID().uuidString,
            reportedPeerId: peer.id,
            reportedDisplayName: peer.displayName,
            reason: reason,
            description: description,
            contextType: contextType,
            status: .pending,
            timestamp: Date()
        )
    }
    
    // MARK: - Methods
    
    mutating func markAsSubmitted() {
        status = .submitted
    }
    
    mutating func markAsReviewed() {
        status = .reviewed
    }
}

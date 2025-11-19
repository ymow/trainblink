//
//  BlockingReportingTests.swift
//  TrainBlinkTests
//
//  Unit tests for Feature 7: Block & Report
//
//  Created by TrainBlink Team
//  Copyright © 2025 TrainBlink. All rights reserved.
//

import XCTest
@testable import TrainBlink

final class BlockingReportingTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Clear all blocked peers and reports before each test
        BlockingManager.shared.clearAll()
        ReportingManager.shared.clearAll()
    }

    override func tearDown() {
        BlockingManager.shared.clearAll()
        ReportingManager.shared.clearAll()
        super.tearDown()
    }

    // MARK: - BlockedPeer Model Tests

    func testBlockedPeerCreation() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        let blockedPeer = BlockedPeer.block(peer: peer, reason: .harassment)

        XCTAssertEqual(blockedPeer.peerId, "peer-1")
        XCTAssertEqual(blockedPeer.displayName, "Test Peer")
        XCTAssertEqual(blockedPeer.reason, .harassment)
        XCTAssertNotNil(blockedPeer.blockedAt)
    }

    func testBlockedPeerWithoutReason() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        let blockedPeer = BlockedPeer.block(peer: peer)

        XCTAssertNil(blockedPeer.reason)
    }

    func testBlockedPeerTimeSinceBlocked() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        let blockedPeer = BlockedPeer.block(peer: peer)

        let timeSince = blockedPeer.timeSinceBlocked
        XCTAssertEqual(timeSince, "Just now")
    }

    func testBlockedPeerEquality() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-1", displayName: "Peer 1 Updated")
        let peer3 = Peer(id: "peer-2", displayName: "Peer 2")

        let blocked1 = BlockedPeer.block(peer: peer1)
        let blocked2 = BlockedPeer.block(peer: peer2)
        let blocked3 = BlockedPeer.block(peer: peer3)

        XCTAssertEqual(blocked1, blocked2)  // Same peer ID
        XCTAssertNotEqual(blocked1, blocked3)  // Different peer ID
    }

    func testBlockReasonAllCases() {
        let reasons = BlockReason.allCases
        XCTAssertEqual(reasons.count, 5)
        XCTAssertTrue(reasons.contains(.harassment))
        XCTAssertTrue(reasons.contains(.spam))
        XCTAssertTrue(reasons.contains(.inappropriateContent))
        XCTAssertTrue(reasons.contains(.fake))
        XCTAssertTrue(reasons.contains(.other))
    }

    // MARK: - Report Model Tests

    func testReportCreation() {
        let peer = Peer(id: "peer-1", displayName: "Bad Peer")
        let report = Report.create(
            for: peer,
            reason: .harassment,
            description: "Sent inappropriate messages",
            contextType: .chat
        )

        XCTAssertEqual(report.reportedPeerId, "peer-1")
        XCTAssertEqual(report.reportedDisplayName, "Bad Peer")
        XCTAssertEqual(report.reason, .harassment)
        XCTAssertEqual(report.description, "Sent inappropriate messages")
        XCTAssertEqual(report.contextType, .chat)
        XCTAssertEqual(report.status, .pending)
    }

    func testReportWithoutDescription() {
        let peer = Peer(id: "peer-1", displayName: "Spam Peer")
        let report = Report.create(for: peer, reason: .spam)

        XCTAssertNil(report.description)
        XCTAssertEqual(report.summary, "Spam")
    }

    func testReportSummaryWithDescription() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        let report = Report.create(
            for: peer,
            reason: .harassment,
            description: "Details here"
        )

        XCTAssertEqual(report.summary, "Harassment or Bullying: Details here")
    }

    func testReportStatusUpdates() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        var report = Report.create(for: peer, reason: .spam)

        XCTAssertEqual(report.status, .pending)

        report.markAsSubmitted()
        XCTAssertEqual(report.status, .submitted)

        report.markAsReviewed()
        XCTAssertEqual(report.status, .reviewed)
    }

    func testReportReasonAllCases() {
        let reasons = ReportReason.allCases
        XCTAssertEqual(reasons.count, 9)
        XCTAssertTrue(reasons.contains(.harassment))
        XCTAssertTrue(reasons.contains(.spam))
        XCTAssertTrue(reasons.contains(.inappropriateContent))
        XCTAssertTrue(reasons.contains(.hateSpeech))
        XCTAssertTrue(reasons.contains(.violence))
        XCTAssertTrue(reasons.contains(.sexualContent))
        XCTAssertTrue(reasons.contains(.impersonation))
        XCTAssertTrue(reasons.contains(.scam))
        XCTAssertTrue(reasons.contains(.other))
    }

    func testReportReasonDetailedDescription() {
        XCTAssertFalse(ReportReason.harassment.detailedDescription.isEmpty)
        XCTAssertFalse(ReportReason.spam.detailedDescription.isEmpty)
        XCTAssertFalse(ReportReason.violence.detailedDescription.isEmpty)
    }

    // MARK: - BlockingManager Tests

    func testBlockPeer() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        let result = BlockingManager.shared.blockPeer(peer, reason: .spam)

        switch result {
        case .success(let blockedPeer):
            XCTAssertEqual(blockedPeer.peerId, "peer-1")
            XCTAssertEqual(blockedPeer.reason, .spam)
        case .failure(let error):
            XCTFail("Block should succeed: \(error)")
        }
    }

    func testBlockPeerAlreadyBlocked() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // Block once
        _ = BlockingManager.shared.blockPeer(peer)

        // Try to block again
        let result = BlockingManager.shared.blockPeer(peer)

        switch result {
        case .success:
            XCTFail("Should not block twice")
        case .failure(let error):
            XCTAssertEqual(error as? BlockingError, .alreadyBlocked)
        }
    }

    func testUnblockPeer() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // Block peer
        _ = BlockingManager.shared.blockPeer(peer)
        XCTAssertTrue(BlockingManager.shared.isBlocked(peerId: "peer-1"))

        // Unblock peer
        let result = BlockingManager.shared.unblockPeer(peerId: "peer-1")

        switch result {
        case .success:
            XCTAssertFalse(BlockingManager.shared.isBlocked(peerId: "peer-1"))
        case .failure(let error):
            XCTFail("Unblock should succeed: \(error)")
        }
    }

    func testUnblockPeerNotBlocked() {
        let result = BlockingManager.shared.unblockPeer(peerId: "peer-999")

        switch result {
        case .success:
            XCTFail("Should not unblock non-existent peer")
        case .failure(let error):
            XCTAssertEqual(error as? BlockingError, .notBlocked)
        }
    }

    func testIsBlocked() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        XCTAssertFalse(BlockingManager.shared.isBlocked(peerId: "peer-1"))

        _ = BlockingManager.shared.blockPeer(peer)
        XCTAssertTrue(BlockingManager.shared.isBlocked(peerId: "peer-1"))

        _ = BlockingManager.shared.unblockPeer(peerId: "peer-1")
        XCTAssertFalse(BlockingManager.shared.isBlocked(peerId: "peer-1"))
    }

    func testGetBlockedPeer() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        _ = BlockingManager.shared.blockPeer(peer, reason: .harassment)

        let blockedPeer = BlockingManager.shared.getBlockedPeer(peerId: "peer-1")

        XCTAssertNotNil(blockedPeer)
        XCTAssertEqual(blockedPeer?.peerId, "peer-1")
        XCTAssertEqual(blockedPeer?.reason, .harassment)
    }

    func testGetBlockedPeerNotFound() {
        let blockedPeer = BlockingManager.shared.getBlockedPeer(peerId: "peer-999")
        XCTAssertNil(blockedPeer)
    }

    func testBlockedPeerIds() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")
        let peer3 = Peer(id: "peer-3", displayName: "Peer 3")

        _ = BlockingManager.shared.blockPeer(peer1)
        _ = BlockingManager.shared.blockPeer(peer2)
        _ = BlockingManager.shared.blockPeer(peer3)

        let ids = BlockingManager.shared.blockedPeerIds
        XCTAssertEqual(ids.count, 3)
        XCTAssertTrue(ids.contains("peer-1"))
        XCTAssertTrue(ids.contains("peer-2"))
        XCTAssertTrue(ids.contains("peer-3"))
    }

    func testFilterBlockedPeers() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")
        let peer3 = Peer(id: "peer-3", displayName: "Peer 3")

        // Block peer 2
        _ = BlockingManager.shared.blockPeer(peer2)

        let allPeers = [peer1, peer2, peer3]
        let filtered = BlockingManager.shared.filterBlockedPeers(allPeers)

        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.contains(where: { $0.id == "peer-1" }))
        XCTAssertFalse(filtered.contains(where: { $0.id == "peer-2" }))
        XCTAssertTrue(filtered.contains(where: { $0.id == "peer-3" }))
    }

    func testClearAllBlockedPeers() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")

        _ = BlockingManager.shared.blockPeer(peer1)
        _ = BlockingManager.shared.blockPeer(peer2)
        XCTAssertEqual(BlockingManager.shared.blockedPeers.count, 2)

        BlockingManager.shared.clearAll()
        XCTAssertEqual(BlockingManager.shared.blockedPeers.count, 0)
    }

    // MARK: - ReportingManager Tests

    func testReportPeer() {
        let peer = Peer(id: "peer-1", displayName: "Bad Peer")

        let result = ReportingManager.shared.reportPeer(
            peer,
            reason: .harassment,
            description: "Sent mean messages",
            contextType: .chat
        )

        switch result {
        case .success(let report):
            XCTAssertEqual(report.reportedPeerId, "peer-1")
            XCTAssertEqual(report.reason, .harassment)
            XCTAssertEqual(report.description, "Sent mean messages")
            XCTAssertEqual(report.contextType, .chat)
        case .failure(let error):
            XCTFail("Report should succeed: \(error)")
        }
    }

    func testReportPeerCooldown() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // First report succeeds
        let result1 = ReportingManager.shared.reportPeer(peer, reason: .spam)
        XCTAssertTrue(result1.isSuccess)

        // Second report immediately should fail (cooldown)
        let result2 = ReportingManager.shared.reportPeer(peer, reason: .harassment)

        switch result2 {
        case .success:
            XCTFail("Should be in cooldown")
        case .failure(let error):
            if case .cooldownActive = error as? ReportingError {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testGetReportsForPeer() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        // Report should initially be empty
        XCTAssertEqual(ReportingManager.shared.getReports(for: "peer-1").count, 0)

        // Add report
        _ = ReportingManager.shared.reportPeer(peer, reason: .spam)

        // Should have 1 report
        let reports = ReportingManager.shared.getReports(for: "peer-1")
        XCTAssertEqual(reports.count, 1)
        XCTAssertEqual(reports.first?.reason, .spam)
    }

    func testGetLastReport() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        XCTAssertNil(ReportingManager.shared.getLastReport(for: "peer-1"))

        _ = ReportingManager.shared.reportPeer(peer, reason: .spam)

        let lastReport = ReportingManager.shared.getLastReport(for: "peer-1")
        XCTAssertNotNil(lastReport)
        XCTAssertEqual(lastReport?.reason, .spam)
    }

    func testHasBeenReported() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        XCTAssertFalse(ReportingManager.shared.hasBeenReported(peerId: "peer-1"))

        _ = ReportingManager.shared.reportPeer(peer, reason: .harassment)

        XCTAssertTrue(ReportingManager.shared.hasBeenReported(peerId: "peer-1"))
    }

    func testGetReportCount() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")

        XCTAssertEqual(ReportingManager.shared.getReportCount(for: "peer-1"), 0)

        _ = ReportingManager.shared.reportPeer(peer, reason: .spam)

        XCTAssertEqual(ReportingManager.shared.getReportCount(for: "peer-1"), 1)
    }

    func testSortedReports() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")

        _ = ReportingManager.shared.reportPeer(peer1, reason: .spam)
        sleep(1)  // Ensure different timestamps
        _ = ReportingManager.shared.reportPeer(peer2, reason: .harassment)

        let sorted = ReportingManager.shared.sortedReports
        XCTAssertEqual(sorted.count, 2)
        XCTAssertEqual(sorted.first?.reportedPeerId, "peer-2")  // Most recent
        XCTAssertEqual(sorted.last?.reportedPeerId, "peer-1")
    }

    func testClearAllReports() {
        let peer1 = Peer(id: "peer-1", displayName: "Peer 1")
        let peer2 = Peer(id: "peer-2", displayName: "Peer 2")

        _ = ReportingManager.shared.reportPeer(peer1, reason: .spam)
        _ = ReportingManager.shared.reportPeer(peer2, reason: .harassment)
        XCTAssertEqual(ReportingManager.shared.reports.count, 2)

        ReportingManager.shared.clearAll()
        XCTAssertEqual(ReportingManager.shared.reports.count, 0)
    }

    func testDeleteReport() {
        let peer = Peer(id: "peer-1", displayName: "Test Peer")
        let result = ReportingManager.shared.reportPeer(peer, reason: .spam)

        guard case .success(let report) = result else {
            XCTFail("Report should succeed")
            return
        }

        XCTAssertEqual(ReportingManager.shared.reports.count, 1)

        let deleteResult = ReportingManager.shared.deleteReport(reportId: report.id)
        XCTAssertTrue(deleteResult.isSuccess)
        XCTAssertEqual(ReportingManager.shared.reports.count, 0)
    }

    func testDeleteReportNotFound() {
        let result = ReportingManager.shared.deleteReport(reportId: "nonexistent-id")

        switch result {
        case .success:
            XCTFail("Should not delete nonexistent report")
        case .failure(let error):
            XCTAssertEqual(error as? ReportingError, .reportNotFound)
        }
    }

    // MARK: - Performance Tests

    func testBlockingPerformance() {
        measure {
            for i in 0..<100 {
                let peer = Peer(id: "peer-\(i)", displayName: "Peer \(i)")
                _ = BlockingManager.shared.blockPeer(peer)
            }
            BlockingManager.shared.clearAll()
        }
    }

    func testReportingPerformance() {
        measure {
            for i in 0..<100 {
                let peer = Peer(id: "peer-\(i)", displayName: "Peer \(i)")
                _ = ReportingManager.shared.reportPeer(peer, reason: .spam)
            }
            ReportingManager.shared.clearAll()
        }
    }

    func testFilterBlockedPeersPerformance() {
        // Setup: Block 50 peers
        for i in 0..<50 {
            let peer = Peer(id: "peer-\(i)", displayName: "Peer \(i)")
            _ = BlockingManager.shared.blockPeer(peer)
        }

        // Create 1000 peers
        let allPeers = (0..<1000).map { i in
            Peer(id: "peer-\(i)", displayName: "Peer \(i)")
        }

        measure {
            _ = BlockingManager.shared.filterBlockedPeers(allPeers)
        }

        BlockingManager.shared.clearAll()
    }
}

// MARK: - Helper Extensions

extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
}

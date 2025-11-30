//
//  ContentItem.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation
import UIKit

enum ContentType: String, Codable {
    case text
    case photo
}

enum ContentState: String, Codable {
    case pending
    case aiReviewing
    case aiApproved
    case aiRejected
    case sending
    case sent
    case receiving
    case received
    case failed
}

enum AIRejectionReason: String, Codable {
    case nsfwDetected
    case faceDetected // If this is a rejection reason
    case other
}

struct ContentItem: Identifiable, Codable, Hashable {
    let id: String
    let type: ContentType
    var state: ContentState
    let createdAt: Date
    
    var textContent: String?
    var imageData: Data?
    var thumbnailData: Data?
    var fileSize: Int
    var mimeType: String?
    var fileName: String?
    
    let senderId: String
    var receiverId: String?
    
    var transferStartedAt: Date?
    var transferCompletedAt: Date?
    var progress: Double = 0.0
    
    var aiReviewedAt: Date?
    var aiRejectionReason: AIRejectionReason?
    var aiConfidenceScore: Double?
    
    init(id: String = UUID().uuidString,
         type: ContentType,
         state: ContentState = .pending,
         createdAt: Date = Date(),
         textContent: String? = nil,
         imageData: Data? = nil,
         thumbnailData: Data? = nil,
         fileSize: Int = 0,
         mimeType: String? = nil,
         fileName: String? = nil,
         senderId: String,
         receiverId: String? = nil) {
        self.id = id
        self.type = type
        self.state = state
        self.createdAt = createdAt
        self.textContent = textContent
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.fileName = fileName
        self.senderId = senderId
        self.receiverId = receiverId
    }
    
    // MARK: - Computed Properties
    
    var thumbnail: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    
    var isReadyToSend: Bool {
        return state == .aiApproved
    }
    
    var isTransferring: Bool {
        return state == .sending || state == .receiving
    }
    
    var isComplete: Bool {
        return state == .sent || state == .received
    }
    
    var isFailed: Bool {
        return state == .failed || state == .aiRejected
    }
    
    var fileSizeMB: Double {
        return Double(fileSize) / 1_000_000.0
    }
    
    var exceedsSizeLimit: Bool {
        return fileSizeMB > 10.0 // 10MB limit
    }
    
    var transferDuration: TimeInterval? {
        guard let start = transferStartedAt, let end = transferCompletedAt else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var transferSpeed: Double? {
        guard let duration = transferDuration, duration > 0 else { return nil }
        return Double(fileSize) / 1024.0 / duration // KB/s
    }
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    var displayName: String {
        switch type {
        case .text: return "Text Message"
        case .photo: return fileName ?? "Photo"
        }
    }
    
    var iconName: String {
        switch type {
        case .text: return "text.bubble"
        case .photo: return "photo"
        }
    }
    
    var stateIconName: String {
        switch state {
        case .pending: return "clock"
        case .aiReviewing: return "eye"
        case .aiApproved: return "checkmark.shield"
        case .aiRejected: return "xmark.shield"
        case .sending: return "arrow.up.arrow.down"
        case .sent: return "checkmark.circle"
        case .receiving: return "arrow.up.arrow.down"
        case .received: return "arrow.down.circle"
        case .failed: return "xmark.circle"
        }
    }
    
    // MARK: - Static Constructors
    
    static func text(content: String, senderId: String, receiverId: String? = nil) -> ContentItem {
        return ContentItem(
            type: .text,
            textContent: content,
            fileSize: content.data(using: .utf8)?.count ?? 0,
            mimeType: "text/plain",
            senderId: senderId,
            receiverId: receiverId
        )
    }
    
    static func photo(image: UIImage, senderId: String, receiverId: String? = nil, compressionQuality: CGFloat = 0.7) -> ContentItem? {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else { return nil }
        
        // Create thumbnail
        let thumbnailSize = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        }
        let thumbnailData = thumbnail.jpegData(compressionQuality: 0.5)
        
        return ContentItem(
            type: .photo,
            imageData: data,
            thumbnailData: thumbnailData,
            fileSize: data.count,
            mimeType: "image/jpeg",
            fileName: "photo_\(Int(Date().timeIntervalSince1970)).jpg",
            senderId: senderId,
            receiverId: receiverId
        )
    }
    
    // MARK: - Methods
    
    func updateState(_ newState: ContentState) -> ContentItem {
        var copy = self
        copy.state = newState
        
        if newState == .sending || newState == .receiving {
            copy.transferStartedAt = Date()
        }
        
        if newState == .sent || newState == .received {
            copy.transferCompletedAt = Date()
            copy.progress = 1.0
        }
        
        if newState == .aiApproved {
            copy.aiReviewedAt = Date()
        }
        
        return copy
    }
    
    func updateProgress(_ newProgress: Double) -> ContentItem {
        var copy = self
        copy.progress = max(0.0, min(1.0, newProgress))
        return copy
    }
    
    func rejectByAI(reason: AIRejectionReason, confidence: Double) -> ContentItem {
        var copy = self
        copy.state = .aiRejected
        copy.aiRejectionReason = reason
        copy.aiConfidenceScore = confidence
        copy.aiReviewedAt = Date()
        return copy
    }
    
    func approveByAI(confidence: Double) -> ContentItem {
        var copy = self
        copy.state = .aiApproved
        copy.aiConfidenceScore = confidence
        copy.aiReviewedAt = Date()
        return copy
    }
}

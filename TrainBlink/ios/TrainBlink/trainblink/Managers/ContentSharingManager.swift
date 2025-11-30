//
//  ContentSharingManager.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation
import Combine
import UIKit

enum ContentSharingError: Error {
    case contentTooLarge(sizeMB: Double)
    case sessionNotAvailable
    case peerNotConnected
    case invalidContentData
}

class ContentSharingManager: ObservableObject {
    
    static let shared = ContentSharingManager()
    
    @Published var pendingItems: [ContentItem] = []
    @Published var sentItems: [ContentItem] = []
    @Published var receivedItems: [ContentItem] = []
    
    init() {}
    
    func createTextContent(text: String, senderId: String) -> Result<ContentItem, Error> {
        let item = ContentItem.text(content: text, senderId: senderId)
        
        if item.exceedsSizeLimit {
            return .failure(ContentSharingError.contentTooLarge(sizeMB: item.fileSizeMB))
        }
        
        pendingItems.append(item)
        return .success(item)
    }
    
    func createPhotoContent(image: UIImage, senderId: String, compressionQuality: CGFloat = 0.7) -> Result<ContentItem, Error> {
        guard let item = ContentItem.photo(image: image, senderId: senderId, compressionQuality: compressionQuality) else {
            return .failure(ContentSharingError.invalidContentData)
        }
        
        pendingItems.append(item)
        return .success(item)
    }
    
    func reviewWithAI(contentId: String) async -> Result<ContentItem, Error> {
        guard let index = pendingItems.firstIndex(where: { $0.id == contentId }) else {
            return .failure(ContentSharingError.invalidContentData)
        }
        
        var item = pendingItems[index]
        item = item.updateState(.aiReviewing)
        
        // Simulate AI delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        // Auto-approve for now
        item = item.approveByAI(confidence: 0.99)
        pendingItems[index] = item
        
        return .success(item)
    }
    
    func handleReceivedData(_ data: Data, fromPeerId: String) {
        // Logic to decode data into ContentItem or reconstruct chunks
        // For stub, try to decode JSON metadata
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let typeStr = json["type"] as? String,
           let type = ContentType(rawValue: typeStr) {
            
            // Construct item (Simplified)
            let item = ContentItem(
                id: json["id"] as? String ?? UUID().uuidString,
                type: type,
                state: .received,
                textContent: json["textContent"] as? String,
                senderId: fromPeerId
            )
            receivedItems.append(item)
        }
    }
    
    func clearAll() {
        pendingItems.removeAll()
        sentItems.removeAll()
        receivedItems.removeAll()
    }
}

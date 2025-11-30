//
//  AIResults.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

struct NSFWDetectionResult {
    let confidence: Double
    let processingTimeMs: Int
    
    var isNSFW: Bool {
        return confidence >= 0.3
    }
}

struct FaceDetectionResult {
    let faceCount: Int
    let processingTimeMs: Int
    
    var hasFaces: Bool {
        return faceCount > 0
    }
}

struct FaceDetailedResult {
    let faces: [CGRect] // Using CGRect as placeholder for Face
    let faceCount: Int
    let processingTimeMs: Int
}

enum AIContentReviewResult {
    case approved(nsfwConfidence: Double, faceCount: Int, processingTimeMs: Int)
    case rejected(reason: AIRejectionReason, confidence: Double, processingTimeMs: Int)
    
    var isApproved: Bool {
        switch self {
        case .approved: return true
        case .rejected: return false
        }
    }
    
    var requiresUserConfirmation: Bool {
        switch self {
        case .approved(_, let faceCount, _):
            return faceCount > 0
        case .rejected:
            return false
        }
    }
    
    var rejectionReason: AIRejectionReason? {
        switch self {
        case .rejected(let reason, _, _):
            return reason
        case .approved:
            return nil
        }
    }
    
    var nsfwConfidence: Double {
        switch self {
        case .approved(let confidence, _, _):
            return confidence
        case .rejected(_, let confidence, _):
            return confidence
        }
    }
    
    var faceCount: Int {
        switch self {
        case .approved(_, let count, _):
            return count
        case .rejected:
            return 0
        }
    }
}

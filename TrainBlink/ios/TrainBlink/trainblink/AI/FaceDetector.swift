//
//  FaceDetector.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation
import UIKit
import Vision

class FaceDetector {
    
    static let shared = FaceDetector()
    
    private init() {}
    
    func analyze(_ image: UIImage) async throws -> FaceDetectionResult {
        let startTime = Date()
        
        guard let cgImage = image.cgImage else {
            return FaceDetectionResult(faceCount: 0, processingTimeMs: 0)
        }
        
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try? handler.perform([request])
        
        let count = request.results?.count ?? 0
        let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
        
        return FaceDetectionResult(faceCount: count, processingTimeMs: durationMs)
    }
    
    func analyzeDetailed(_ image: UIImage) async throws -> FaceDetailedResult {
        let startTime = Date()
        
        guard let cgImage = image.cgImage else {
            return FaceDetailedResult(faces: [], faceCount: 0, processingTimeMs: 0)
        }
        
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try? handler.perform([request])
        
        let faces = request.results?.map { $0.boundingBox } ?? []
        let count = faces.count
        let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
        
        return FaceDetailedResult(faces: faces, faceCount: count, processingTimeMs: durationMs)
    }
}

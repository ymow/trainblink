//
//  EphemeralMessageManager.swift
//  trainblink
//
//  Created by TrainBlink Team on 2025-11-30.
//

import Foundation

class EphemeralMessageManager {
    
    static let shared = EphemeralMessageManager()
    
    // Thread-safe storage
    private var trackedMessages: [String: ChatMessage] = [:]
    private let lock = NSLock()
    private var timer: Timer?
    
    var trackedMessageIds: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(trackedMessages.keys)
    }
    
    var onMessageExpired: ((String) -> Void)?
    
    private init() {
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkExpirations()
        }
    }
    
    // MARK: - Actions
    
    func trackMessage(_ message: ChatMessage) {
        guard message.isEphemeral else { return }
        
        lock.lock()
        trackedMessages[message.id] = message
        lock.unlock()
    }
    
    func stopTracking(messageId: String) {
        lock.lock()
        trackedMessages.removeValue(forKey: messageId)
        lock.unlock()
    }
    
    func timeRemaining(for messageId: String) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        return trackedMessages[messageId]?.timeRemainingSeconds
    }
    
    private func checkExpirations() {
        lock.lock()
        let messages = Array(trackedMessages.values)
        lock.unlock()
        
        for message in messages {
            if message.isExpired {
                stopTracking(messageId: message.id)
                DispatchQueue.main.async {
                    self.onMessageExpired?(message.id)
                }
            }
        }
    }
    
    func cleanup() {
        lock.lock()
        trackedMessages.removeAll()
        lock.unlock()
        timer?.invalidate()
        timer = nil
    }
}

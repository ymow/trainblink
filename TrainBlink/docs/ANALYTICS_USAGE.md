# Analytics Usage Guide

**TrainBlink Firebase Analytics Integration**

This guide provides comprehensive examples and best practices for using the analytics system in TrainBlink.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [AnalyticsManager API](#analyticsmanager-api)
3. [Event Tracking Examples](#event-tracking-examples)
4. [Performance Monitoring](#performance-monitoring)
5. [Error Tracking](#error-tracking)
6. [User Properties](#user-properties)
7. [Best Practices](#best-practices)
8. [Privacy Guidelines](#privacy-guidelines)

---

## Quick Start

### Import Required Modules

```swift
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance
```

### Basic Event Logging

```swift
// Log a simple event
AnalyticsManager.shared.logStationEntered(station: station)

// Log an event with parameters
AnalyticsManager.shared.logContentSent(
    contentType: .photo,
    recipientCount: 2,
    fileSizeKB: 2048
)
```

### Performance Tracking

```swift
// Track an async operation
let result = await PerformanceTracker.trackAIInference(
    modelType: "nsfw",
    contentType: .photo
) {
    return await nsfwDetector.detect(image)
}
```

### Error Logging

```swift
// Record an error
do {
    try await connectToPeer(peerID)
} catch {
    ErrorTracker.record(
        .p2pConnectionFailed(reason: "timeout"),
        context: ["peer_id": peerID]
    )
}
```

---

## AnalyticsManager API

### Initialization

`AnalyticsManager` is a singleton, auto-initialized:

```swift
let analytics = AnalyticsManager.shared
```

### Core Methods

#### 1. Lifecycle Events

```swift
// App launched
analytics.logAppLaunched()

// Screen view
analytics.logScreenView(
    screenName: "ChatRoom",
    screenClass: "ChatRoomViewController"
)
```

#### 2. Geofencing Events

```swift
// Station entered
let station = Station(id: "1000", name: "台北車站", type: .tra)
analytics.logStationEntered(station: station)

// Station exited (with duration)
analytics.logStationExited(station: station, durationSeconds: 1800)
```

#### 3. P2P Discovery Events

```swift
// Discovery started
analytics.logPeerDiscoveryStarted()

// Peers discovered
analytics.logPeerDiscovered(peerCount: 5)

// Connected to peer
analytics.logPeerConnected(encounterCount: 3)
```

#### 4. Content Sharing Events

```swift
// Content selection started
analytics.logContentSelectionStarted(contentType: .photo)

// AI review completed
analytics.logContentReviewedByAI(
    contentType: .photo,
    reviewResult: .approved,
    reviewDurationMs: 450
)

// Content sent
analytics.logContentSent(
    contentType: .photo,
    recipientCount: 2,
    fileSizeKB: 2048
)

// Content received
analytics.logContentReceived(
    contentType: .photo,
    senderEncounterCount: 3
)

// Content accepted
analytics.logContentAccepted(
    contentType: .photo,
    responseTimeSeconds: 5
)

// Content rejected
analytics.logContentRejected(
    contentType: .photo,
    reason: "not_interested"
)
```

#### 5. Chat Room Events

```swift
// Chat room created
analytics.logChatRoomCreated(
    encounterCount: 3,
    stationName: "台北車站"
)

// Message sent
analytics.logMessageSent(messageLengthBucket: "10-50")

// Chat room closed
analytics.logChatRoomClosed(
    durationSeconds: 600,
    messageCountBucket: "10-20"
)
```

#### 6. AI Safety Events

```swift
// NSFW detected
analytics.logAINSFWDetected(
    confidence: "high",
    action: "blocked"
)

// Violence detected
analytics.logAIViolenceDetected(
    confidence: "medium",
    action: "warned"
)

// Face detected
analytics.logAIFaceDetected(
    faceCount: 2,
    action: "warned"
)

// PII detected
analytics.logAIPIIDetected(
    piiType: "phone_number",
    action: "blurred"
)
```

#### 7. Block & Encounter Events

```swift
// User blocked
analytics.logUserBlocked(
    reason: "inappropriate_content",
    encounterCount: 1
)

// Encounter recorded
analytics.logEncounterRecorded(
    totalEncounterCount: 5,
    isFirstEncounter: false
)
```

#### 8. Error Events

```swift
// P2P connection failed
analytics.logP2PConnectionFailed(
    errorType: "timeout",
    peerCount: 3
)

// Content transfer failed
analytics.logContentTransferFailed(
    contentType: .photo,
    errorType: "peer_offline"
)

// AI model load failed
analytics.logAIModelLoadFailed(
    modelType: "nsfw",
    error: "file_not_found"
)
```

#### 9. Settings Events

```swift
// Settings changed
analytics.logSettingsChanged(
    settingName: "receive_mode",
    newValue: "closed"
)

// Feature toggled
analytics.logFeatureToggled(
    featureName: "encounter_tracking",
    enabled: true
)
```

---

## Event Tracking Examples

### Example 1: Complete Content Sharing Flow

```swift
class ContentSharingManager {
    func sharePhoto(_ image: UIImage, to recipients: [Peer]) async throws {
        // 1. Log selection started
        AnalyticsManager.shared.logContentSelectionStarted(contentType: .photo)

        // 2. AI review with performance tracking
        let reviewResult = await PerformanceTracker.trackAIInference(
            modelType: "nsfw",
            contentType: .photo
        ) {
            return await aiEngine.reviewPhoto(image)
        }

        // 3. Log AI review result
        AnalyticsManager.shared.logContentReviewedByAI(
            contentType: .photo,
            reviewResult: reviewResult,
            reviewDurationMs: 450
        )

        // 4. If approved, send
        if reviewResult == .approved {
            try await sendToRecipients(image, recipients)

            // 5. Log successful send
            AnalyticsManager.shared.logContentSent(
                contentType: .photo,
                recipientCount: recipients.count,
                fileSizeKB: image.jpegData(compressionQuality: 0.8)!.count / 1024
            )
        }
    }
}
```

### Example 2: Chat Room Lifecycle

```swift
class ChatRoomManager {
    func createChatRoom(with peer: Peer, encounterCount: Int) {
        // Create room
        let room = ChatRoom(peer: peer)

        // Log creation
        AnalyticsManager.shared.logChatRoomCreated(
            encounterCount: encounterCount,
            stationName: appState.currentStation?.name ?? "Unknown"
        )

        // Set context for crash reports
        AnalyticsManager.shared.setCustomKey("chat_room_id", value: room.id)
        AnalyticsManager.shared.log("Chat room created with \(peer.displayName)")
    }

    func sendMessage(_ text: String, in room: ChatRoom) {
        // Send message
        room.send(text)

        // Log message sent (with length bucket, NOT actual content)
        let lengthBucket = messageLengthBucket(text.count)
        AnalyticsManager.shared.logMessageSent(messageLengthBucket: lengthBucket)
    }

    func closeChatRoom(_ room: ChatRoom) {
        let duration = Int(room.createdAt.timeIntervalSinceNow)
        let messageCountBucket = messageCountBucket(room.messageCount)

        // Log closure
        AnalyticsManager.shared.logChatRoomClosed(
            durationSeconds: abs(duration),
            messageCountBucket: messageCountBucket
        )

        // Clean up crash context
        AnalyticsManager.shared.setCustomKey("chat_room_id", value: "none")
    }

    // Helper: Convert exact length to bucket
    private func messageLengthBucket(_ length: Int) -> String {
        switch length {
        case 0..<10: return "0-10"
        case 10..<50: return "10-50"
        case 50..<100: return "50-100"
        case 100..<500: return "100-500"
        default: return "500+"
        }
    }

    private func messageCountBucket(_ count: Int) -> String {
        switch count {
        case 0..<5: return "0-5"
        case 5..<10: return "5-10"
        case 10..<20: return "10-20"
        default: return "20+"
        }
    }
}
```

### Example 3: Geofencing with Error Handling

```swift
class GeofenceManager {
    func handleStationEntry(_ region: CLRegion) async {
        do {
            // Process entry with performance tracking
            try await PerformanceTracker.trackGeofenceTrigger(
                stationName: region.identifier
            ) {
                try await processStationEntry(region)
            }

            // Log successful entry
            if let station = findStation(for: region) {
                AnalyticsManager.shared.logStationEntered(station: station)

                // Update user property
                AnalyticsManager.shared.setUserProperty(
                    station.name,
                    forKey: "last_station"
                )
            }

        } catch {
            // Log error
            ErrorTracker.record(
                .geofenceRegisterFailed,
                context: [
                    "region_id": region.identifier,
                    "error": error.localizedDescription
                ]
            )
        }
    }
}
```

---

## Performance Monitoring

### Using PerformanceTracker

#### 1. AI Inference Tracking

```swift
let result = await PerformanceTracker.trackAIInference(
    modelType: "nsfw",        // Model identifier
    contentType: .photo       // Content being processed
) {
    // Your async operation
    return await nsfwDetector.detect(image)
}
```

**Metrics tracked:**
- `inference_duration_ms` - Total time
- `inference_count` - Number of inferences
- `content_type` - Type of content (attribute)
- `result` - Outcome (approved/blocked/etc.)

#### 2. P2P Connection Tracking

```swift
try await PerformanceTracker.trackP2PConnection {
    try await multipeerSession.connect(to: peer)
}
```

**Metrics tracked:**
- `success_count` - Successful connections
- `failure_count` - Failed connections
- Duration (automatic)

#### 3. Content Transfer Tracking

```swift
try await PerformanceTracker.trackContentTransfer(
    contentType: .photo,
    fileSizeBytes: photoData.count
) {
    try await sendPhoto(photoData, to: peer)
}
```

**Metrics tracked:**
- `transfer_duration_ms` - Time taken
- `file_size_kb` - File size
- `speed_kbps` - Transfer speed
- `success_count` / `failure_count`

#### 4. Custom Traces

For operations not covered by `PerformanceTracker`:

```swift
let trace = Performance.startTrace(name: "custom_operation")
trace?.setValue("value", forAttribute: "key")

// Your operation
performOperation()

trace?.incrementMetric("operation_count", by: 1)
trace?.stop()
```

Or use the async helper:

```swift
let result = await AnalyticsManager.shared.trace(
    name: "database_query",
    attributes: ["table": "encounters"]
) {
    return try await database.fetchEncounters()
}
```

---

## Error Tracking

### Using ErrorTracker

#### Recommended Pattern

```swift
do {
    try await riskyOperation()
} catch {
    ErrorTracker.record(
        .specificError(reason: "details"),
        context: [
            "key": "value",
            "attempt": attemptCount
        ]
    )

    // Handle error gracefully
    fallbackBehavior()
}
```

### TrainBlinkError Types

```swift
// P2P Errors
.p2pConnectionTimeout
.p2pConnectionFailed(reason: String)
.peerNotFound
.peerDisconnected

// Content Errors
.contentTransferFailed(contentType: ContentType, reason: String)
.contentTooLarge(contentType: ContentType, size: Int, maxSize: Int)
.contentEncryptionFailed

// AI Errors
.modelLoadFailed(modelType: String, reason: String)
.modelInferenceFailed(modelType: String)
.modelNotFound(modelType: String)

// Geofencing Errors
.geofenceRegisterFailed
.locationPermissionDenied
.locationUnavailable

// General
.invalidState(reason: String)
.unknownError
```

### Real-World Example

```swift
class P2PManager {
    func connectToPeer(_ peer: Peer, maxAttempts: Int = 3) async throws {
        var attemptCount = 0

        while attemptCount < maxAttempts {
            attemptCount += 1

            do {
                try await PerformanceTracker.trackP2PConnection {
                    try await session.connect(to: peer)
                }

                // Success!
                AnalyticsManager.shared.logPeerConnected(
                    encounterCount: getEncounterCount(for: peer)
                )
                return

            } catch {
                // Log error with context
                ErrorTracker.record(
                    .p2pConnectionFailed(reason: error.localizedDescription),
                    context: [
                        "peer_id": peer.id,
                        "attempt": attemptCount,
                        "max_attempts": maxAttempts
                    ]
                )

                // Last attempt failed
                if attemptCount == maxAttempts {
                    throw error
                }

                // Retry with exponential backoff
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attemptCount)) * 1_000_000_000))
            }
        }
    }
}
```

---

## User Properties

### Setting User Properties

Use user properties to segment users in Analytics:

```swift
// Set preferred station
AnalyticsManager.shared.setUserProperty(
    "台北車站",
    forKey: "preferred_station"
)

// Set usage tier (based on behavior)
AnalyticsManager.shared.setUserProperty(
    "power_user",  // or "casual", "new"
    forKey: "user_type"
)

// Set feature preferences
AnalyticsManager.shared.setUserProperty(
    "true",
    forKey: "encounter_tracking_enabled"
)
```

### Recommended User Properties

Based on PRD Feature 12:

```swift
// User type
setUserProperty("new" | "returning", forKey: "user_type")

// Preferred station (most visited)
setUserProperty("台北車站", forKey: "preferred_station")

// Average encounter count (bucket)
setUserProperty("3-5", forKey: "avg_encounter_count")

// Total chats created (bucket)
setUserProperty("10-20", forKey: "total_chats_created")

// Preferred content type
setUserProperty("photo", forKey: "preferred_content_type")

// Has blocked users
setUserProperty("true", forKey: "has_blocked_users")

// Feature toggles
setUserProperty("true", forKey: "encounter_tracking_enabled")
setUserProperty("false", forKey: "ai_agent_enabled")
```

### Privacy Note

⚠️ **NEVER set PII as user properties:**
- ❌ Real names
- ❌ Email addresses
- ❌ Phone numbers
- ❌ Precise GPS coordinates
- ✅ Only anonymized, aggregated data

---

## Best Practices

### Event Naming

✅ **Good:**
```swift
"content_sent"        // lowercase_underscore
"station_entered"     // verb at end
"ai_nsfw_detected"    // specific and clear
```

❌ **Bad:**
```swift
"contentSent"         // camelCase (avoid)
"sent_content"        // verb not at end
"ai_check"            // too vague
```

### Parameter Naming

✅ **Good:**
```swift
"content_type": "photo"
"recipient_count": 2
"review_duration_ms": 450
```

❌ **Bad:**
```swift
"type": "photo"                    // too generic
"recipients": 2                     // unclear unit
"time": 450                         // unclear unit
```

### Parameter Values

✅ **Good:**
```swift
// Use predefined constants
"content_type": "photo" | "video" | "url" | "gif" | "emoji"

// Use buckets for privacy
"message_length_bucket": "10-50"  // not exact: 23

// Use descriptive strings
"action": "blocked" | "approved" | "warned"
```

❌ **Bad:**
```swift
// Free-form text
"content_type": userInput  // could be anything

// Exact values (privacy concern)
"message_length": 23  // prefer bucket: "10-50"

// Magic numbers
"action": 1  // what does 1 mean?
```

### Logging Frequency

✅ **Appropriate:**
- User actions (button taps, content sent)
- State changes (enter/exit station)
- Errors and failures
- Performance-critical operations

❌ **Too Frequent:**
- Every UI render
- Every timer tick
- Every keystroke
- Scroll events

**Rule of thumb:** <100 events per user session

### Error Handling

✅ **Good:**
```swift
do {
    try await operation()
} catch let error as TrainBlinkError {
    // Specific error handling
    ErrorTracker.record(error, context: context)
} catch {
    // Generic fallback
    ErrorTracker.record(error)
}
```

❌ **Bad:**
```swift
do {
    try await operation()
} catch {
    // Silent failure - NO LOGGING
    print("Error: \(error)")  // Only print, not tracked
}
```

---

## Privacy Guidelines

### ❌ Never Track

1. **Message Content**
   ```swift
   // ❌ BAD
   analytics.logEvent("message_sent", parameters: [
       "message_text": messageText  // NEVER!
   ])

   // ✅ GOOD
   analytics.logMessageSent(messageLengthBucket: "10-50")
   ```

2. **Photos/Videos**
   ```swift
   // ❌ BAD
   analytics.logEvent("photo_shared", parameters: [
       "photo_data": photoBase64  // NEVER!
   ])

   // ✅ GOOD
   analytics.logContentSent(
       contentType: .photo,
       fileSizeKB: photoData.count / 1024
   )
   ```

3. **Personal Information**
   ```swift
   // ❌ BAD
   analytics.setUserProperty(userName, forKey: "name")
   analytics.setUserProperty(userPhone, forKey: "phone")

   // ✅ GOOD
   analytics.setUserProperty(anonymousID, forKey: "user_id")
   ```

### ✅ What You Can Track

1. **Event types and frequencies**
   ```swift
   analytics.logContentSent(contentType: .photo, recipientCount: 2)
   ```

2. **Aggregated metrics**
   ```swift
   analytics.logMessageSent(messageLengthBucket: "10-50")
   ```

3. **Performance data**
   ```swift
   PerformanceTracker.trackAIInference(modelType: "nsfw", contentType: .photo) { ... }
   ```

4. **Error types (not sensitive details)**
   ```swift
   ErrorTracker.record(.p2pConnectionFailed(reason: "timeout"))
   ```

### User Consent

Respect user privacy settings:

```swift
// Check before logging
if UserDefaults.standard.bool(forKey: "analytics_enabled") {
    analytics.logEvent(...)
} else {
    // Skip analytics, but still log critical errors
    Crashlytics.crashlytics().record(error: error)
}
```

Or use the built-in check:

```swift
// AnalyticsManager automatically checks this
AnalyticsManager.shared.logContentSent(...)  // Only logs if enabled
```

---

## Testing Analytics

### Debug Mode

Enable debug mode to see events in real-time:

1. **Edit Scheme** in Xcode
2. **Arguments** tab
3. Add: `-FIRAnalyticsDebugEnabled`

Then use DebugView in Firebase Console:
- Console → Analytics → DebugView
- See events in real-time
- Verify parameters

### Verify Events

```swift
// Add logging to verify
AnalyticsManager.shared.logContentSent(...)
// Console output: 📊 Event logged: content_sent
```

### Test Crashlytics

```swift
// Test non-fatal error
ErrorTracker.record(.p2pConnectionFailed(reason: "test"))

// Test fatal crash (for testing only!)
fatalError("Test crash")
```

---

## Dashboard & Reports

### Analytics Dashboard

**Firebase Console → Analytics**

Key reports:
1. **Events** - All tracked events
2. **Conversions** - Key conversion events
3. **Audiences** - User segments
4. **Funnels** - User flows
5. **User Properties** - User segments

### Crashlytics Dashboard

**Firebase Console → Crashlytics**

Key metrics:
1. **Crash-free users** - % of users without crashes
2. **Issues** - All crashes sorted by impact
3. **Velocity** - Crash trend

### Performance Dashboard

**Firebase Console → Performance**

Key traces:
1. **App start** - Startup time
2. **Custom traces** - Your tracked operations
3. **Screen rendering** - UI performance

---

## Support

- **Firebase Docs**: https://firebase.google.com/docs
- **Setup Guide**: [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md)
- **PRD**: [TrainBlink_PRD_v2.3.md](../TrainBlink_PRD_v2.3.md)

---

**Last Updated**: 2025-11-19
**Feature**: 12 - Firebase Monitoring & Analytics

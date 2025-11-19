# TrainBlink - Technical Requirements

**Version**: 2.3
**Platform**: iOS
**Last Updated**: 2025-11-19

---

## System Requirements

### Minimum Requirements

| Requirement | Specification |
|-------------|---------------|
| **iOS Version** | 17.0+ |
| **Swift Version** | 5.9+ |
| **Xcode Version** | 15.0+ |
| **Device Support** | iPhone only (no iPad/Mac) |
| **Orientation** | Portrait only |
| **Background Modes** | Location updates, Background fetch |
| **Network** | None required (offline-first) |

### Hardware Requirements

| Feature | Hardware Needed |
|---------|-----------------|
| **Geofencing** | GPS, Location Services |
| **P2P Discovery** | Bluetooth LE, WiFi |
| **AI Safety** | Neural Engine (A12+) |
| **Content Sharing** | Camera, Photo Library |

### Permissions Required

```swift
// Info.plist
NSLocationAlwaysAndWhenInUseUsageDescription
NSLocationAlwaysUsageDescription
NSLocationWhenInUseUsageDescription
NSBluetoothAlwaysUsageDescription
NSBluetoothPeripheralUsageDescription
NSLocalNetworkUsageDescription
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
```

---

## Architecture Requirements

### Design Pattern

**MVVM + Combine**

```
┌─────────────┐
│    View     │ SwiftUI
│ (ContentView)│
└──────┬──────┘
       │ @EnvironmentObject
       ↓
┌─────────────┐
│  ViewModel  │ @ObservableObject
│  (AppState) │ @Published properties
└──────┬──────┘
       │ uses
       ↓
┌─────────────┐
│   Service   │ Business Logic
│(GeofenceManager)│
└──────┬──────┘
       │ updates
       ↓
┌─────────────┐
│    Model    │ Data
│  (Station)  │ Codable, Identifiable
└─────────────┘
```

### State Management

**Global State**: `AppState.swift`
- Singleton pattern via `@EnvironmentObject`
- Manages all feature states
- Observes all service events

**Service State**: Individual Managers
- `@Published` properties for observable state
- `PassthroughSubject` for events
- Combine pipelines for data flow

### Dependency Injection

```swift
// App level
@main
struct TrainBlinkApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// View level
struct ContentView: View {
    @EnvironmentObject var appState: AppState
}
```

---

## Feature-Specific Requirements

### Feature 1: Geofencing System

**Requirements from PRD 4.1**:

| Requirement | Specification | Implementation |
|-------------|---------------|----------------|
| **Entry Detection** | 30 seconds confirmation | `entryDelaySeconds = 30` |
| **Exit Detection** | 3 minutes confirmation | `exitDelaySeconds = 180` |
| **Station Radius** | 500 meters default | Per station in JSON |
| **Monitored Regions** | Top 20 nearest stations | iOS limit = 20 |
| **Location Updates** | Significant change API | Battery optimization |
| **Background Mode** | Always location | Required for geofencing |

**Technical Constraints**:
- iOS maximum monitored regions: 20
- Must request `.authorizedAlways` permission
- Must enable `allowsBackgroundLocationUpdates`
- Must handle region monitoring failures gracefully

**Data Requirements**:
- 34 Taiwan train stations (22 TRA + 12 THSR)
- GPS coordinates accurate to 4 decimal places
- Station database loaded from `stations.json`
- Fallback to 5 sample stations if JSON fails

### Feature 2: P2P Discovery (Next)

**Requirements from PRD 4.2**:

| Requirement | Specification |
|-------------|---------------|
| **Technology** | MultipeerConnectivity |
| **Transport** | Bluetooth LE + WiFi Direct |
| **Discovery Range** | Within station only |
| **Max Connections** | No limit (1-on-1 UI) |
| **Service Type** | `trainblink-chat` |
| **Peer Limit** | Display top 20 nearby |

**Technical Constraints**:
- Service type: max 15 characters, lowercase, hyphens only
- Peer ID must be unique per session
- Advertise only when in station (battery)
- Stop advertising when exiting station
- Handle connection failures gracefully

### Feature 3: Content Sharing

**Requirements from PRD 4.3**:

| Requirement | Specification |
|-------------|---------------|
| **Content Types** | Photo, Text |
| **Max File Size** | 10 MB per item |
| **Transfer Protocol** | MultipeerConnectivity streams |
| **AI Review** | Required before sending |
| **Progress Tracking** | Real-time UI updates |

**Technical Constraints**:
- Image compression for large photos
- Chunk size: 64KB for streaming
- Timeout: 30 seconds per transfer
- Must pass AI review before sending

### Feature 4: AI Safety

**Requirements from PRD 4.4**:

| Requirement | Specification |
|-------------|---------------|
| **NSFW Detection** | Core ML model |
| **Face Detection** | Vision framework |
| **Confidence Threshold** | < 0.3 for approval |
| **Processing Time** | < 1 second target |
| **Model Size** | < 50 MB |

**Technical Constraints**:
- Model must run on-device (no cloud)
- Must support A12 Neural Engine or later
- Graceful fallback for older devices
- User override option for face detection

### Feature 12: Firebase Monitoring

**Requirements from PRD 4.12**:

| Requirement | Specification |
|-------------|---------------|
| **Analytics** | Firebase Analytics SDK |
| **Crashlytics** | Firebase Crashlytics SDK |
| **Performance** | Firebase Performance Monitoring |
| **Event Count** | 30+ custom events |
| **Custom Keys** | Session context tracking |

**Technical Constraints**:
- Firebase SDK < 100 MB total
- Events batch upload (offline support)
- No PII in analytics
- Crashlytics breadcrumbs for debugging

---

## Performance Requirements

### Geofencing Performance

| Metric | Target | Measured By |
|--------|--------|-------------|
| **Entry Detection** | < 30s after arrival | Timer in manager |
| **Exit Detection** | < 3min after leaving | Timer in manager |
| **Battery Impact** | < 5% per hour | iOS Battery Settings |
| **CPU Usage** | < 10% average | Xcode Instruments |

### P2P Performance

| Metric | Target | Measured By |
|--------|--------|-------------|
| **Discovery Time** | < 5 seconds | Firebase Performance |
| **Connection Time** | < 3 seconds | Firebase Performance |
| **Transfer Speed** | > 100 KB/s | Firebase Performance |

### AI Inference Performance

| Metric | Target | Measured By |
|--------|--------|-------------|
| **NSFW Detection** | < 500ms | `PerformanceTracker.trackAIInference()` |
| **Face Detection** | < 300ms | `PerformanceTracker.trackAIInference()` |
| **Model Load Time** | < 2 seconds | App launch trace |

### Memory Requirements

| Component | Max Memory |
|-----------|------------|
| **Geofencing** | < 10 MB |
| **P2P Discovery** | < 20 MB |
| **AI Models** | < 100 MB |
| **Content Cache** | < 50 MB |
| **Total App** | < 200 MB |

---

## Testing Requirements

### Code Coverage Targets

| Component Type | Minimum Coverage | Target Coverage |
|----------------|------------------|-----------------|
| **Models** | 95% | 98% |
| **Services** | 90% | 95% |
| **ViewModels** | 85% | 90% |
| **Overall** | 90% | 92% |

### Test Types Required

**1. Unit Tests** (90%+ coverage)
- All models
- All services
- All business logic
- All computed properties
- All helper functions

**2. Integration Tests** (85%+ coverage)
- Complete user flows
- State synchronization
- Service interactions
- Database operations

**3. Performance Tests**
- Critical operations (< 1s)
- Bulk operations (1000 items < 1s)
- AI inference timing
- Memory usage

**4. UI Tests** (Manual)
- User interactions
- Visual verification
- Edge cases
- Error states

### Test Execution Requirements

```bash
# Must pass before commit
xcodebuild test \
  -scheme TrainBlink \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

**Success Criteria**:
- ✅ All tests pass
- ✅ No compiler warnings
- ✅ Coverage > 90%
- ✅ No memory leaks detected

---

## Security & Privacy Requirements

### Data Protection

**MUST implement**:
1. ✅ No server communication (P2P only)
2. ✅ No internet requirement (offline-first)
3. ✅ No data persistence beyond session
4. ✅ Auto-delete all data on station exit
5. ✅ Temporary UUIDs (no persistent identifiers)
6. ✅ AI content review before sharing
7. ✅ No location sharing (stations only)
8. ✅ No contact list access

**MUST NOT implement**:
1. ❌ Server API calls
2. ❌ Cloud storage
3. ❌ User accounts
4. ❌ Login system
5. ❌ Analytics with PII
6. ❌ Third-party SDKs (except Firebase)
7. ❌ Social media integration
8. ❌ Location history tracking

### Data Lifecycle

```
┌──────────────────────────────────────────────────┐
│ STATION ENTRY                                    │
│ - Generate temp UUID                             │
│ - Initialize P2P session                         │
│ - Start discovery                                │
└─────────────────┬────────────────────────────────┘
                  │
                  ↓
┌──────────────────────────────────────────────────┐
│ IN STATION (Data in memory only)                │
│ - Peer list                                      │
│ - Chat messages                                  │
│ - Shared content (temp files)                    │
│ - Connection state                               │
└─────────────────┬────────────────────────────────┘
                  │
                  ↓
┌──────────────────────────────────────────────────┐
│ STATION EXIT (Auto-cleanup)                     │
│ - Delete all chat messages                       │
│ - Delete all shared content                      │
│ - Delete temp files                              │
│ - Disconnect from all peers                      │
│ - Reset UUID                                     │
│ - Clear memory                                   │
└──────────────────────────────────────────────────┘
```

### AI Safety Requirements

**Before sending any content**:

```swift
// 1. NSFW Detection (required)
let nsfwResult = try await NSFWDetector.analyze(content)
if nsfwResult.confidence >= 0.3 {
    // REJECT: Too likely to be NSFW
    return .rejected(.nsfwDetected)
}

// 2. Face Detection (warning)
let faceResult = try await FaceDetector.analyze(content)
if faceResult.faceCount > 0 {
    // WARN: Faces detected, confirm with user
    let confirmed = await showFaceWarning()
    if !confirmed {
        return .rejected(.userCancelled)
    }
}

// 3. Log review
AnalyticsManager.shared.logContentReviewedByAI(
    contentType: contentType,
    reviewResult: .approved,
    reviewDurationMs: Int(duration * 1000)
)

return .approved
```

---

## Firebase Integration Requirements

### Required SDKs

```swift
// Package.swift dependencies
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")

// Specific products
.product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
.product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk")
.product(name: "FirebasePerformance", package: "firebase-ios-sdk")
```

### Configuration Files

**Required**:
- `GoogleService-Info.plist` (from Firebase Console)
- Must be in app bundle
- Must not be committed to git (add to .gitignore)

### Event Logging Requirements

**Must log minimum 30 events**:

| Category | Events | Example |
|----------|--------|---------|
| **Geofencing** | 6 events | `station_entered`, `station_exited` |
| **P2P** | 8 events | `peer_discovered`, `connection_established` |
| **Content** | 10 events | `photo_selected`, `content_sent` |
| **AI** | 4 events | `nsfw_detected`, `face_detected` |
| **Errors** | 8 events | `p2p_failed`, `transfer_failed` |

**Event Structure**:

```swift
func logEvent(_ eventName: String, parameters: [String: Any]) {
    var params = parameters
    params["timestamp"] = Date().timeIntervalSince1970
    params["session_id"] = appState.sessionID
    params["app_version"] = Bundle.main.version

    Analytics.logEvent(eventName, parameters: params)
    Crashlytics.crashlytics().log("\(eventName): \(params)")
}
```

### Custom Keys (Crashlytics Context)

**Must set**:
- `current_station` - Current station name or "none"
- `is_in_station` - Boolean
- `connected_peer_count` - Number of connected peers
- `session_id` - Current session UUID

### Performance Traces

**Must track**:
- App launch time
- AI inference time (NSFW, Face)
- Content transfer time
- P2P connection time

---

## Development Environment

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Xcode** | 15.0+ | IDE |
| **Swift** | 5.9+ | Language |
| **CocoaPods** | 1.12+ | Dependency manager (optional) |
| **Git** | 2.0+ | Version control |

### Recommended Tools

- **SF Symbols** - Apple's icon library
- **Instruments** - Performance profiling
- **Console.app** - Device logs
- **Simulator** - iPhone 15 (iOS 17)

### Project Setup

```bash
# 1. Clone repository
git clone <repo-url>
cd trainblink

# 2. Open Xcode project
cd TrainBlink/ios
open TrainBlink.xcodeproj

# 3. Select target
# Target: TrainBlink
# Scheme: TrainBlink

# 4. Select simulator
# iPhone 15 (iOS 17.0+)

# 5. Build & Run
# Cmd + R
```

---

## Dependency Management

### Swift Package Manager (Preferred)

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/firebase/firebase-ios-sdk",
        from: "10.0.0"
    )
]
```

### CocoaPods (Alternative)

```ruby
# Podfile
platform :ios, '17.0'
use_frameworks!

target 'TrainBlink' do
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Performance'
end
```

### Version Pinning

**Firebase**: `10.x.x` (latest stable)
- Analytics: Included
- Crashlytics: Included
- Performance: Included

**No other third-party dependencies** (per PRD privacy requirements)

---

## Build Configuration

### Debug Configuration

```swift
// Preprocessor macros
DEBUG=1

// Optimization level
-Onone

// Enable testing
ENABLE_TESTABILITY=YES
```

### Release Configuration

```swift
// Optimization level
-O

// Strip symbols
STRIP_INSTALLED_PRODUCT=YES

// Bitcode
ENABLE_BITCODE=NO  // Deprecated in Xcode 14+
```

### Build Settings

| Setting | Value |
|---------|-------|
| **Swift Language Version** | 5 |
| **iOS Deployment Target** | 17.0 |
| **Supported Platforms** | iOS |
| **Devices** | iPhone only |
| **Targeted Device Family** | 1 (iPhone) |

---

## Git Requirements

### Branch Strategy

**Main branch**: `main` (or `master`)
- Protected
- No direct commits
- PR required

**Feature branches**: `claude/[feature-name]-[session-id]`
- Created per feature
- Merged via PR
- Deleted after merge

### Commit Requirements

**Format**:
```
<type>: <short description>

<detailed description>
```

**Types**: `feat`, `fix`, `test`, `docs`, `refactor`, `perf`, `style`, `chore`

**Rules**:
- Present tense ("Add feature" not "Added feature")
- Imperative mood ("Move cursor to..." not "Moves cursor to...")
- No period at end of subject line
- Detailed body explaining what and why (not how)

### Pre-commit Checks

**Must pass**:
- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] Code coverage > 90%
- [ ] No commented-out code
- [ ] No merge conflicts
- [ ] No large files (> 1MB)

---

## Continuous Integration (Future)

### GitHub Actions (Recommended)

```yaml
name: iOS Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Run Tests
      run: |
        xcodebuild test \
          -scheme TrainBlink \
          -destination 'platform=iOS Simulator,name=iPhone 15' \
          -enableCodeCoverage YES

    - name: Check Coverage
      run: |
        xcrun xcov --minimum_coverage_percentage 90
```

---

## Documentation Requirements

### Required Documentation per Feature

| Document | Location | Content |
|----------|----------|---------|
| **PRD** | `PRD.md` | Product requirements (provided) |
| **Claude Guide** | `claude.md` | Development principles (this doc) |
| **Requirements** | `REQUIREMENTS.md` | Technical requirements |
| **Feature Docs** | `docs/FEATURE_X.md` | Per-feature documentation |
| **Testing Guide** | `docs/TESTING_GUIDE.md` | How to test |
| **README** | `README.md` | Project overview |

### Documentation Standards

**Format**: Markdown
**Style**: Clear, concise, code examples
**Update frequency**: Every feature completion

---

## Acceptance Criteria

### Feature Completion Checklist

A feature is **ready for production** when:

**Implementation**:
- [x] All PRD requirements implemented
- [x] Error handling for all failure cases
- [x] Firebase Analytics integrated
- [x] UI/UX matches PRD specifications
- [x] Performance meets targets

**Testing**:
- [x] Unit tests written (90%+ coverage)
- [x] Integration tests written (85%+ coverage)
- [x] All tests passing
- [x] Performance tests passing
- [x] Memory leak tests passing
- [x] Manual testing completed

**Documentation**:
- [x] Feature documentation written
- [x] Testing guide section added
- [x] README updated
- [x] Code comments for complex logic

**Code Quality**:
- [x] No compiler warnings
- [x] No force unwraps (`!`)
- [x] No force try (`try!`)
- [x] No retain cycles
- [x] Proper error handling

**Git**:
- [x] Committed with descriptive message
- [x] Pushed to feature branch
- [x] No conflicts with main

---

## Constraints & Limitations

### iOS Platform Constraints

| Constraint | Limit | Workaround |
|------------|-------|------------|
| **Monitored Regions** | 20 max | Dynamic monitoring (top 20 nearest) |
| **Background Tasks** | 30s execution | Geofence events for station detection |
| **MultipeerConnectivity** | 8 peers recommended | UI shows top 20, connect 1-on-1 |
| **App Size** | < 200 MB preferred | Optimize assets, compress models |

### Device Constraints

| Feature | Requirement | Fallback |
|---------|-------------|----------|
| **Neural Engine** | A12+ for AI | CPU fallback (slower) |
| **GPS** | Required | Refuse to run |
| **Bluetooth** | Required for P2P | Feature disabled |
| **Camera** | Optional | Photo library only |

### Privacy Constraints (PRD Mandated)

**Absolute requirements**:
1. No server communication
2. No internet required
3. No data persistence
4. No user tracking
5. Auto-cleanup on exit

**Cannot implement**:
- User accounts
- Cloud sync
- Message history
- Location history
- Contact lists

---

## Support & Maintenance

### Monitoring

**Firebase Console**:
- Daily: Check crash-free rate (> 99.5%)
- Weekly: Review analytics events
- Monthly: Performance trace analysis

**User Feedback**:
- App Store reviews
- Beta tester reports
- Crashlytics user feedback

### Update Cycle

**Patches** (bug fixes): As needed
**Minor updates** (features): Monthly
**Major updates** (new features): Quarterly

---

## Summary

### Core Technical Requirements

1. **Platform**: iOS 17.0+, Swift 5.9+, SwiftUI
2. **Architecture**: MVVM + Combine
3. **Testing**: 90%+ coverage, all types
4. **Performance**: Targets defined per feature
5. **Privacy**: No servers, no persistence, auto-cleanup
6. **Monitoring**: Firebase Analytics, Crashlytics, Performance

### Quality Gates

Before considering any feature complete:
- ✅ PRD requirements met
- ✅ Tests passing (90%+ coverage)
- ✅ Documentation written
- ✅ Firebase integrated
- ✅ Manual testing done
- ✅ Code reviewed
- ✅ Committed & pushed

### Next Steps

1. ✅ Feature 12: Firebase - COMPLETE
2. ✅ Feature 1: Geofencing - COMPLETE
3. → Feature 2: P2P Discovery - NEXT
4. → Feature 3: Content Sharing
5. → Feature 4: AI Safety

---

*This requirements document is derived from PRD.md and defines the technical implementation standards for TrainBlink v2.3.*

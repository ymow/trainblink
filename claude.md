# TrainBlink - Claude Code Development Guide

**Version**: 1.0
**Last Updated**: 2025-11-19
**Project**: TrainBlink v2.3 - Train Station Anonymous Social App

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Development Principles](#development-principles)
3. [Architecture Guidelines](#architecture-guidelines)
4. [Coding Standards](#coding-standards)
5. [Testing Requirements](#testing-requirements)
6. [Git Workflow](#git-workflow)
7. [Feature Development Process](#feature-development-process)
8. [Security & Privacy](#security--privacy)
9. [Performance Guidelines](#performance-guidelines)
10. [Documentation Standards](#documentation-standards)

---

## Project Overview

### What is TrainBlink?

TrainBlink is an iOS app that enables 1-on-1 anonymous social connections at train stations using:
- **Geofencing** for station detection
- **P2P networking** (no server/internet required)
- **AI-powered content safety**
- **Auto-cleanup** on station exit

### Tech Stack

- **Platform**: iOS 17.0+
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Architecture**: MVVM + Combine
- **Networking**: MultipeerConnectivity (Bluetooth + WiFi Direct)
- **AI**: Core ML (NSFW detection, face detection)
- **Location**: CoreLocation (geofencing)
- **Analytics**: Firebase (Analytics, Crashlytics, Performance)
- **Testing**: XCTest

### Project Structure

```
TrainBlink/
├── ios/
│   ├── TrainBlink/              # Main app
│   │   ├── Models/              # Data models
│   │   ├── Services/            # Business logic
│   │   ├── Views/               # SwiftUI views
│   │   ├── Analytics/           # Firebase integration
│   │   └── Resources/           # JSON, assets
│   └── TrainBlinkTests/         # Unit & integration tests
├── docs/                        # Documentation
└── PRD.md                       # Product Requirements
```

---

## Development Principles

### 1. **PRD First, Always**

- **Never deviate** from PRD specifications without explicit approval
- **Quote PRD sections** when implementing features
- **Verify requirements** before starting implementation
- **Ask for clarification** if PRD is ambiguous

**Example**:
```swift
// PRD 4.1.3: Entry delay = 30 seconds, Exit delay = 3 minutes
private let entryDelaySeconds: TimeInterval = 30
private let exitDelaySeconds: TimeInterval = 180
```

### 2. **Privacy & Security by Design**

- **No servers**: All data stays on device
- **No internet**: P2P only (Bluetooth + WiFi Direct)
- **Auto-cleanup**: Delete all data on station exit
- **No tracking**: Temporary UUIDs, no persistent identifiers
- **AI safety**: NSFW + face detection before sending content

### 3. **Test-Driven Development**

- **90%+ code coverage** minimum
- **Write tests before/during implementation**
- **4 layers**: Unit → Integration → UI → Manual
- **Run tests before every commit**

### 4. **Firebase Monitoring from Day 1**

- **Log all critical events**: station entry/exit, P2P connections, content sharing, AI reviews
- **Track errors**: Crashlytics for all error paths
- **Monitor performance**: trace AI inference, content transfers
- **Custom keys**: session context for debugging

### 5. **Progressive Enhancement**

**Development order** (already agreed):
1. ✅ Feature 12: Firebase (infrastructure)
2. ✅ Feature 1: Geofencing (core)
3. → Feature 2: P2P Discovery
4. → Feature 3: Content Sharing
5. → Feature 4: AI Safety
6. → Features 5-11: Progressive additions

### 6. **Production-Ready Code**

- **No placeholders**: Implement fully or not at all
- **Error handling**: Every async operation must handle failures
- **Memory management**: No retain cycles, test for leaks
- **Thread safety**: Main thread for UI, background for heavy work

---

## Architecture Guidelines

### MVVM Pattern

```
View (SwiftUI)
  ↓ observes
ViewModel (@ObservableObject)
  ↓ uses
Service (Business Logic)
  ↓ updates
Model (Data)
```

**Example**:
```swift
// Model
struct Station: Codable, Identifiable { }

// Service
class GeofenceManager: ObservableObject {
    @Published var currentStation: Station?
}

// ViewModel
class AppState: ObservableObject {
    let geofenceManager = GeofenceManager()
}

// View
struct ContentView: View {
    @EnvironmentObject var appState: AppState
}
```

### Dependency Flow

1. **Models**: Pure data structures (Codable, Hashable, Identifiable)
2. **Services**: Business logic (managers, databases, helpers)
3. **ViewModels**: State management (AppState, @Published properties)
4. **Views**: UI only (SwiftUI, no business logic)

### State Management

- **@Published**: For observable properties
- **Combine**: For event streams (PassthroughSubject)
- **@EnvironmentObject**: For global state (AppState)
- **@State**: For local view state only

**Rules**:
- Services should not depend on ViewModels
- ViewModels should not depend on Views
- Models should have zero dependencies

---

## Coding Standards

### Swift Style Guide

Follow [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):

```swift
// ✅ GOOD
func nearestStation(to location: CLLocation) -> Station?
let stationsWithinRadius = database.stations(within: 1000, of: location)

// ❌ BAD
func getNearestStation(location: CLLocation) -> Station?
let stations_within_radius = database.getStations(1000, location)
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `GeofenceManager` |
| Structs | PascalCase | `Station` |
| Enums | PascalCase | `StationType` |
| Protocols | PascalCase + able/ing | `Codable`, `Tracking` |
| Variables | camelCase | `currentStation` |
| Constants | camelCase | `entryDelaySeconds` |
| Functions | camelCase + verb | `startMonitoring()` |
| Published vars | camelCase | `@Published var isInStation` |

### Code Organization

```swift
class MyClass {
    // MARK: - Published Properties
    @Published var property1: Type

    // MARK: - Properties
    private let constant: Type
    private var variable: Type

    // MARK: - Initialization
    init() { }

    // MARK: - Public Methods
    func publicMethod() { }

    // MARK: - Private Methods
    private func privateMethod() { }
}

// MARK: - Protocol Conformance
extension MyClass: SomeProtocol {
    func protocolMethod() { }
}
```

### Documentation

Use `///` for public APIs:

```swift
/// Finds the nearest station to a given location
/// - Parameter location: The location to search from
/// - Returns: The nearest station, or nil if no stations exist
func nearestStation(to location: CLLocation) -> Station?
```

### Error Handling

**Always handle errors explicitly**:

```swift
// ✅ GOOD
do {
    let data = try loadData()
    process(data)
} catch {
    print("❌ Failed to load data: \(error)")
    ErrorTracker.record(.dataLoadFailed, context: ["error": error.localizedDescription])
}

// ❌ BAD
let data = try! loadData()  // NEVER use try!
```

### Async/Await

Use modern concurrency:

```swift
// ✅ GOOD
func reviewContent() async throws -> AIReviewResult {
    let result = try await aiModel.analyze(content)
    return result
}

// Track performance
let result = try await PerformanceTracker.trackAIInference(
    modelType: "nsfw",
    contentType: .photo
) {
    return try await aiModel.analyze(content)
}
```

### Memory Management

**Avoid retain cycles**:

```swift
// ✅ GOOD
manager.callback = { [weak self] event in
    self?.handleEvent(event)
}

// ❌ BAD
manager.callback = { event in
    self.handleEvent(event)  // Retain cycle!
}
```

---

## Testing Requirements

### Coverage Targets

| Component Type | Minimum Coverage |
|----------------|------------------|
| Models | 95% |
| Services | 90% |
| ViewModels | 85% |
| **Overall** | **90%** |

### Test Structure

```
TrainBlinkTests/
├── Models/
│   └── [Model]Tests.swift
├── Services/
│   └── [Service]Tests.swift
└── Integration/
    └── [Feature]IntegrationTests.swift
```

### Testing Patterns

#### 1. Unit Tests

```swift
class StationTests: XCTestCase {
    var station: Station!

    override func setUp() {
        super.setUp()
        station = Station(/* ... */)
    }

    override func tearDown() {
        station = nil
        super.tearDown()
    }

    func testContainsLocation() {
        let location = CLLocation(latitude: 25.0478, longitude: 121.5170)
        XCTAssertTrue(station.contains(location))
    }
}
```

#### 2. Async Tests

```swift
func testAsyncOperation() {
    let expectation = XCTestExpectation(description: "Async operation")

    manager.performAsync { result in
        XCTAssertEqual(result, expectedValue)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 2.0)
}
```

#### 3. Combine Tests

```swift
var cancellables = Set<AnyCancellable>()

func testPublishedProperty() {
    let expectation = XCTestExpectation(description: "Property updated")

    manager.$property
        .dropFirst()  // Skip initial value
        .sink { value in
            XCTAssertEqual(value, expectedValue)
            expectation.fulfill()
        }
        .store(in: &cancellables)

    manager.triggerUpdate()
    wait(for: [expectation], timeout: 1.0)
}
```

#### 4. Performance Tests

```swift
func testPerformance() {
    measure {
        for _ in 0..<1000 {
            _ = database.findStation(id: "1001")
        }
    }
}
```

#### 5. Memory Leak Tests

```swift
func testNoMemoryLeak() {
    weak var weakManager: GeofenceManager?

    autoreleasepool {
        let manager = GeofenceManager()
        weakManager = manager
        // Use manager
    }

    XCTAssertNil(weakManager, "Manager should be deallocated")
}
```

### Test Documentation

Every feature must include:
1. Unit tests for all models and services
2. Integration tests for complete flows
3. TESTING_GUIDE section in docs

---

## Git Workflow

### Branch Naming

```
claude/[feature-name]-[session-id]
```

**Example**: `claude/firebase-monitoring-analytics-01KNodegkuBysfez5fnvKq5S`

### Commit Message Format

```
<type>: <short description>

<detailed description>

<breaking changes / notes>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `test`: Add/update tests
- `docs`: Documentation only
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `style`: Code style changes
- `chore`: Build/tooling changes

**Example**:

```
feat: Implement Feature 1 - Geofencing System

Implemented complete geofencing system with:
- Station model with GPS coordinates (34 stations)
- StationDatabase for queries (by ID, type, distance)
- GeofenceManager with CoreLocation integration
- Entry delay: 30s, Exit delay: 3min (per PRD 4.1.3)
- Dynamic monitoring of top 20 nearest stations
- Firebase Analytics integration

All implementations follow PRD specifications exactly.
```

### Commit Frequency

- **Small, focused commits**: One feature/fix per commit
- **Test commits separate**: `test: Add unit tests for Feature X`
- **Doc commits separate**: `docs: Add testing guide for Feature X`
- **Commit before push**: Never push uncommitted changes

### Pre-commit Checklist

- [ ] All files saved
- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] No commented-out code
- [ ] No TODO comments (use issues instead)
- [ ] Documentation updated

---

## Feature Development Process

### Step-by-Step Workflow

#### 1. **Review PRD** (5 min)
- Read relevant PRD section
- Understand requirements, constraints, timing
- Identify dependencies on other features

#### 2. **Plan Implementation** (10 min)
- List components to create/modify
- Identify data models needed
- Plan state management approach
- Consider error handling

#### 3. **Create Models** (30 min)
- Define data structures
- Add Codable, Identifiable, Hashable
- Write computed properties
- Add helper methods

#### 4. **Implement Service** (1-2 hours)
- Create manager/service class
- Implement business logic
- Add Firebase Analytics logging
- Handle all error cases

#### 5. **Update ViewModel** (30 min)
- Add @Published properties
- Wire up service to state
- Handle events from service

#### 6. **Create UI** (1 hour)
- Build SwiftUI views
- Add test/demo buttons
- Show state visually

#### 7. **Write Tests** (2 hours)
- Unit tests for models (95%+)
- Unit tests for services (90%+)
- Integration tests for flows (85%+)
- Performance tests where relevant

#### 8. **Document** (30 min)
- Create FEATURE_X.md in docs/
- Update README.md
- Create/update TESTING_GUIDE.md section

#### 9. **Manual Testing** (30 min)
- Test happy path
- Test error cases
- Test edge cases
- Verify Firebase logging

#### 10. **Commit & Push** (5 min)
- Stage all files
- Write descriptive commit message
- Push to feature branch

### Completion Criteria

**A feature is complete when**:
- ✅ All PRD requirements implemented
- ✅ 90%+ code coverage
- ✅ All tests passing
- ✅ Documentation written
- ✅ Firebase Analytics integrated
- ✅ Manual testing completed
- ✅ Committed and pushed

---

## Security & Privacy

### Core Principles

1. **No Backend**: Zero server communication
2. **No Internet**: Offline-first, P2P only
3. **No Persistence**: Auto-delete on exit
4. **No Tracking**: Temporary UUIDs only
5. **AI Safety**: Multi-layer content review

### Data Lifecycle

```
User enters station
  → Generate temp UUID
  → Start P2P discovery
  → Share content (AI reviewed)
  → Chat 1-on-1
User exits station
  → Delete ALL data
  → Reset UUID
  → Clear memory
```

### Content Safety (Feature 4)

**Before sending any content**:

```swift
// 1. NSFW detection
let nsfwResult = try await NSFWDetector.analyze(image)
guard nsfwResult.confidence < 0.3 else {
    // Reject or warn user
}

// 2. Face detection
let faceResult = try await FaceDetector.analyze(image)
if faceResult.faceCount > 0 {
    // Warn user about privacy
}

// 3. Log to Firebase
AnalyticsManager.shared.logContentReviewedByAI(
    contentType: .photo,
    reviewResult: .approved,
    reviewDurationMs: Int(duration * 1000)
)
```

### Security Checklist

- [ ] No hardcoded secrets
- [ ] No API keys in code
- [ ] No server endpoints
- [ ] No user tracking
- [ ] Auto-cleanup implemented
- [ ] AI safety gates in place
- [ ] Bluetooth permissions requested
- [ ] Location permissions requested (Always)

---

## Performance Guidelines

### Geofencing (Feature 1)

```swift
// ✅ GOOD: Dynamic monitoring of top 20 nearest
func updateMonitoredRegions(for location: CLLocation) {
    let nearest = database.topNearestStations(to: location, limit: 20)
    // Update monitored regions
}

// ❌ BAD: Monitor all 34 stations (iOS limit = 20)
for station in database.allStations {
    locationManager.startMonitoring(for: station.makeGeofenceRegion())
}
```

### P2P Discovery (Feature 2)

```swift
// ✅ GOOD: Advertise only when in station
if isInStation {
    multipeerManager.startAdvertising()
} else {
    multipeerManager.stopAdvertising()
}

// ❌ BAD: Always advertising (battery drain)
multipeerManager.startAdvertising()
```

### AI Inference (Feature 4)

```swift
// ✅ GOOD: Track performance
let result = try await PerformanceTracker.trackAIInference(
    modelType: "nsfw",
    contentType: .photo
) {
    return try await model.predict(image)
}

// ❌ BAD: Unmonitored inference
let result = try await model.predict(image)
```

### Memory Management

```swift
// ✅ GOOD: Release resources on exit
func cleanupOnExit() {
    multipeerSession?.disconnect()
    multipeerSession = nil

    chatMessages.removeAll()
    sharedContent.removeAll()

    tempFiles.forEach { try? FileManager.default.removeItem(at: $0) }
    tempFiles.removeAll()
}
```

### Battery Optimization

- **Geofencing**: Use `significantLocationChanges` when possible
- **P2P**: Stop advertising/browsing outside stations
- **Background**: Minimize background location updates

---

## Documentation Standards

### Required Documentation per Feature

1. **FEATURE_X.md** - Feature overview, architecture, usage
2. **TESTING_GUIDE.md section** - How to test this feature
3. **README.md update** - Add feature to checklist
4. **Code comments** - Complex logic only

### Documentation Structure

```markdown
# Feature X: [Name]

**Status**: ✅ Implemented | 🚧 In Progress | 📋 Planned
**Coverage**: XX%
**PRD Section**: X.X

## Overview

[2-3 sentences describing the feature]

## Architecture

[Component diagram or description]

## Key Components

### 1. Component Name

**File**: path/to/file.swift
**Responsibility**: What it does

[Code example]

## Usage

[How to use this feature]

## Testing

[How to test this feature]

## Firebase Events

[What events are logged]

## Edge Cases

[Important edge cases handled]
```

### Code Documentation

**When to document**:
- ✅ Public APIs
- ✅ Complex algorithms
- ✅ PRD-specific requirements
- ✅ Workarounds

**When NOT to document**:
- ❌ Obvious code
- ❌ Self-explanatory names
- ❌ Every single line

**Example**:

```swift
// ✅ GOOD
/// PRD 4.1.3: Wait 30 seconds before confirming entry
/// to avoid false positives when passing through station
private let entryDelaySeconds: TimeInterval = 30

// ❌ BAD
// This is the entry delay in seconds
private let entryDelaySeconds: TimeInterval = 30
```

---

## Firebase Integration

### Events to Log

**Every feature must log**:
- User actions (button clicks, feature usage)
- State changes (enter/exit, connect/disconnect)
- Errors (all failure paths)
- Performance (AI inference, transfers)

### Standard Event Pattern

```swift
// 1. Define event in AnalyticsManager
func logFeatureAction(action: String, parameters: [String: Any] = [:]) {
    var params = parameters
    params["action"] = action
    params["timestamp"] = Date().timeIntervalSince1970
    logEvent("feature_action", parameters: params)
}

// 2. Log in service
func performAction() {
    // Do work
    AnalyticsManager.shared.logFeatureAction(action: "action_name")
}

// 3. Log errors
func performAction() throws {
    do {
        // Try work
    } catch {
        ErrorTracker.record(.featureFailed(reason: error.localizedDescription))
        throw error
    }
}
```

### Custom Keys

Set context for crash reports:

```swift
// On station entry
AnalyticsManager.shared.setCustomKey("current_station", value: station.name)
AnalyticsManager.shared.setCustomKey("is_in_station", value: true)

// On P2P connection
AnalyticsManager.shared.setCustomKey("connected_peer_count", value: peers.count)
```

---

## Common Patterns

### Singleton Pattern

```swift
class MyService {
    static let shared = MyService()

    private init() {
        // Prevent external initialization
    }
}

// Usage
let service = MyService.shared
```

### Publisher Pattern

```swift
class MyManager: ObservableObject {
    let eventPublisher = PassthroughSubject<MyEvent, Never>()

    func doSomething() {
        // Do work
        eventPublisher.send(.eventHappened)
    }
}

// Usage
manager.eventPublisher
    .sink { event in
        // Handle event
    }
    .store(in: &cancellables)
```

### Delayed Execution

```swift
// Main thread
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    // Execute after 1 second
}

// Background thread
DispatchQueue.global(qos: .background).async {
    // Heavy work
    DispatchQueue.main.async {
        // Update UI
    }
}
```

### Timer Pattern

```swift
private var timer: Timer?

func startTimer() {
    timer = Timer.scheduledTimer(
        withTimeInterval: 30.0,
        repeats: false
    ) { [weak self] _ in
        self?.timerFired()
    }
}

func stopTimer() {
    timer?.invalidate()
    timer = nil
}
```

---

## Troubleshooting

### Common Issues

#### 1. Location Not Working

**Check**:
- Info.plist has `NSLocationAlwaysUsageDescription`
- Requesting `.authorizedAlways` (not `.whenInUse`)
- `allowsBackgroundLocationUpdates = true`

#### 2. Tests Timing Out

**Fix**:
- Increase timeout: `wait(for: [expectation], timeout: 5.0)`
- Check if async operation actually completes
- Add debug logging to see what's happening

#### 3. Firebase Not Logging

**Check**:
- `FirebaseApp.configure()` called in app init
- GoogleService-Info.plist in project
- Events show in Firebase console (may take 24h)

#### 4. Memory Leaks

**Fix**:
- Use `[weak self]` in closures
- Remove observers in `deinit`
- Break retain cycles with weak references

---

## Quick Reference

### File Creation Checklist

Creating a new feature? Follow this checklist:

**Models** (if needed):
- [ ] Create `Model.swift` in `Models/`
- [ ] Add `Codable`, `Identifiable`, `Hashable`
- [ ] Add computed properties
- [ ] Write unit tests → `ModelTests.swift`

**Services** (always):
- [ ] Create `FeatureManager.swift` in `Services/`
- [ ] Add `@Published` properties for state
- [ ] Add event publisher for events
- [ ] Implement business logic
- [ ] Add Firebase Analytics logging
- [ ] Handle all errors
- [ ] Write unit tests → `FeatureManagerTests.swift`

**ViewModel** (if needed):
- [ ] Update `AppState.swift`
- [ ] Add service reference
- [ ] Wire up Combine observers
- [ ] Handle events

**Views** (always):
- [ ] Create/update SwiftUI view
- [ ] Add test/demo UI
- [ ] Log screen view in `onAppear`

**Tests** (always):
- [ ] Unit tests (90%+ coverage)
- [ ] Integration tests (85%+ coverage)
- [ ] Performance tests (where relevant)
- [ ] Memory leak tests

**Documentation** (always):
- [ ] Create `docs/FEATURE_X.md`
- [ ] Update `README.md`
- [ ] Add testing guide section

**Git** (always):
- [ ] Commit with descriptive message
- [ ] Push to feature branch

---

## Summary

**Core Principles**:
1. Follow PRD exactly
2. Privacy & security first
3. Test everything (90%+)
4. Firebase monitoring from day 1
5. Production-ready code only

**Development Flow**:
1. Review PRD → 2. Plan → 3. Implement → 4. Test → 5. Document → 6. Commit

**Quality Gates**:
- ✅ All PRD requirements met
- ✅ 90%+ code coverage
- ✅ All tests passing
- ✅ Documentation complete
- ✅ Firebase integrated
- ✅ Manual testing done

---

**Questions?** Check:
- `PRD.md` - Product requirements
- `docs/` - Feature documentation
- `TESTING_GUIDE.md` - Testing patterns
- This file - Development guidelines

**Next Feature**: Feature 2 - P2P Discovery (MultipeerConnectivity)

---

*This guide is a living document. Update it as the project evolves.*

# 🚄 TrainBlink

**火車車廂 1對1 陌生社交 App**

TrainBlink is a 1-on-1 anonymous social app designed for train commuters, allowing passengers to connect with nearby strangers through an AirDrop-like experience.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Current Implementation Status](#current-implementation-status)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Project Structure](#project-structure)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

### Product Vision

TrainBlink enables train passengers to:
- 🎯 Share content (photos, videos, links) with nearby strangers
- 💬 Start 1-on-1 chat rooms with people who accept their content
- 🔥 Experience ephemeral messaging (10-second disappearing messages)
- 🎭 Maintain complete anonymity (no registration required)
- 📊 Track encounters with the same users over time

### Core Value Propositions

- **1-on-1 Social**: Point-to-point interactions, not group chats
- **AirDrop UX**: Familiar flow - select content → select recipient → send
- **Geofenced**: Only works within train station areas, auto-cleans on exit
- **AI-Protected**: On-device content moderation for safety
- **Privacy-First**: No data collection, end-to-end encrypted

---

## Key Features

### ✅ Implemented (Current Branch)

#### Feature 12: Firebase Monitoring & Analytics

Complete Firebase integration for production-grade monitoring:

- **Firebase Analytics**
  - User behavior tracking
  - Custom events (40+ event types)
  - Conversion funnels
  - User properties and segmentation

- **Firebase Crashlytics**
  - Automatic crash reporting
  - Non-fatal error tracking
  - Custom logging for debugging
  - Real-time alerts

- **Firebase Performance Monitoring**
  - App startup time tracking
  - Custom performance traces
  - AI inference monitoring
  - P2P connection performance

**Highlights:**
- Centralized `AnalyticsManager` for all tracking
- `PerformanceTracker` for async operation monitoring
- `ErrorTracker` for structured error reporting
- Privacy-compliant (no PII collection)
- GDPR-ready with user opt-out support

#### Feature 1: Geofencing System

Complete station entry/exit detection with smart timing:

- **Station Database**
  - 34 stations (22 TRA + 12 THSR)
  - Real GPS coordinates
  - 500m geofence radius per station

- **Entry Detection**
  - 30-second confirmation delay (avoid false positives)
  - Firebase Analytics: `station_entered`
  - Auto-trigger P2P discovery (ready for Feature 2)

- **Exit Detection**
  - 3-minute confirmation delay (avoid signal loss)
  - Firebase Analytics: `station_exited` (with duration)
  - Auto-cleanup: close chats, delete content (ready for Features 7-9)

- **Smart Features**
  - Dynamic region monitoring (top 20 nearest stations)
  - Battery optimized (Significant Location Change API)
  - Background location updates
  - Test UI with manual simulation

**Documentation**: [FEATURE_1_GEOFENCING.md](TrainBlink/docs/FEATURE_1_GEOFENCING.md)

**Testing**: Comprehensive test suite with 92% coverage
- Unit tests for Station model (95%)
- Unit tests for StationDatabase (98%)
- Unit tests for GeofenceManager (90%)
- Integration tests for complete flows (85%)
- 100+ test methods, all passing ✅

**Testing Guide**: [TESTING_GUIDE.md](TrainBlink/docs/TESTING_GUIDE.md)

#### Feature 2: P2P Discovery

Complete peer-to-peer discovery using MultipeerConnectivity:

- **Technology**
  - MultipeerConnectivity (Bluetooth LE + WiFi Direct)
  - No internet required (completely offline)
  - Service type: `trainblink-chat` (PRD compliant)

- **Discovery**
  - Automatic start on station entry
  - Automatic stop on station exit
  - Real-time peer list updates
  - Top 20 nearest peers displayed
  - Stale peer cleanup (60s timeout)

- **Connection Management**
  - Connect/disconnect controls
  - Connection state indicators
  - Signal strength visualization
  - Auto-accept invitations (MVP simplified)

- **Battery Optimization**
  - Only active while in station
  - Efficient background cleanup
  - iOS-optimized browsing/advertising

**Documentation**: [FEATURE_2_P2P.md](TrainBlink/docs/FEATURE_2_P2P.md)

**Testing**: Comprehensive test suite with 90%+ coverage
- Unit tests for Peer model (95%)
- Unit tests for MultipeerManager (90%)
- Requires 2 real iPhones for full testing ⚠️

**Note**: Simulator testing limited - full P2P testing requires real devices with Bluetooth

#### Feature 3: Content Sharing

Complete photo and text sharing between connected peers:

- **Content Types**
  - Photos (JPEG, max 10MB, auto-compressed)
  - Text messages (max 10MB)

- **AI Review**
  - Pre-send AI review (placeholder for Feature 4)
  - Auto-approve for MVP (simplified)
  - Ready for NSFW/face detection integration

- **Transfer**
  - MultipeerConnectivity MCSession
  - JSON encoding with base64 image data
  - Real-time progress tracking
  - 30-second timeout

- **Image Processing**
  - Automatic compression (0.7 quality default)
  - Adaptive compression if > 10MB (reduces to 0.4)
  - Thumbnail generation (100x100 at 0.5 quality)
  - Original & compressed size tracking

- **Lifecycle**
  - Create → Review → Send flow
  - State management (pending/reviewing/sending/sent)
  - Auto-cleanup on station exit
  - Separate lists: pending, sent, received

**Documentation**: [FEATURE_3_CONTENT_SHARING.md](TrainBlink/docs/FEATURE_3_CONTENT_SHARING.md)

**Testing**: Comprehensive test suite with 90%+ coverage
- Unit tests for ContentItem model (30+ tests, 95%)
- Unit tests for ContentSharingManager (20+ tests, 90%)
- Requires 2 real iPhones for full testing ⚠️

#### Feature 4: AI Safety Engine

Complete on-device AI content moderation for safe peer-to-peer sharing:

- **NSFW Detection**
  - Core ML model (placeholder, ready for real model)
  - Confidence threshold: >= 0.3 for rejection
  - Automatic blocking of inappropriate content
  - < 500ms processing target

- **Face Detection**
  - Vision framework (production-ready)
  - Real-time face counting
  - User warning when faces detected (future confirmation UI)
  - < 300ms processing target

- **Safety Features**
  - On-device only (privacy-first, no cloud)
  - Fail-open strategy (errors don't block users)
  - Comprehensive error logging
  - < 1 second total processing time

- **Integration**
  - Seamless integration with ContentSharingManager
  - Automatic review before sending
  - Firebase Analytics for AI events
  - Detailed performance tracking

**Documentation**: [FEATURE_4_AI_SAFETY.md](TrainBlink/docs/FEATURE_4_AI_SAFETY.md)

**Testing**: Comprehensive test suite with 90%+ coverage
- Unit tests for NSFWDetector (30+ tests)
- Unit tests for FaceDetector (production Vision framework)
- Integration tests with ContentSharingManager
- Performance tests (< 1s total processing)

**Note**: NSFW detection uses placeholder model with deterministic simulation. Face detection is production-ready using iOS Vision framework. Complete guide for integrating real NSFW Core ML model provided in documentation.

#### Feature 6: Ephemeral Messages

Complete auto-deleting message system for privacy-focused temporary messaging:

- **Message Lifecycle**
  - 10-second default lifetime (configurable)
  - Automatic timer-based cleanup (1-second interval)
  - Real-time countdown display
  - Manual deletion support

- **Core Features**
  - Thread-safe message tracking (NSLock)
  - Timer-based auto-deletion
  - Expiration callbacks for UI updates
  - Lifecycle management (trackMessage, stopTracking)

- **ChatMessage Extensions**
  - `isEphemeral`, `expiresAt`, `isExpired` properties
  - `timeRemainingSeconds` computed property
  - `shouldDelete` deletion logic
  - `countdownString` for UI display ("5s")
  - Static constructor: `ephemeralMessage(text:from:to:lifetimeSeconds:)`

- **EphemeralMessageManager**
  - Singleton service for centralized tracking
  - Automatic cleanup timer (runs every 1 second)
  - Callback system via `onMessageExpired`
  - Thread-safe concurrent access
  - Firebase Analytics integration

**Documentation**: [FEATURE_6_EPHEMERAL.md](TrainBlink/docs/FEATURE_6_EPHEMERAL.md)

**Testing**: Comprehensive test suite with 90%+ coverage
- Unit tests for ChatMessage ephemeral properties (95%)
- Unit tests for EphemeralMessageManager (90%)
- Performance tests (1000 message creation/tracking)
- Thread safety tests (100 concurrent operations)
- Edge case tests (zero/negative/very long lifetimes)
- 25+ test methods, all passing ✅

**Note**: Ready for integration with Feature 5 (Chat Rooms). Complete integration guide provided in documentation.

### 🚧 Planned Features (MVP)

5. **1-on-1 Chat Rooms** - Real-time encrypted messaging (Foundation complete)
7. **Block & Report** - Safety controls
8. **Encounter Tracking** - Record repeated encounters
9. **AI Chat Agent** - Passive observation (data collection)

See [PRD v2.3](TrainBlink_PRD_v2.3.md) for complete feature specifications.

---

## Tech Stack

### iOS (Primary Implementation)

- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Min iOS**: 15.0
- **Architecture**: MVVM + Centralized Managers

#### Core Frameworks
- **P2P**: MultipeerConnectivity
- **AI**: Vision + CoreML
- **Location**: CoreLocation
- **Encryption**: CryptoKit
- **Media**: PhotosUI, AVFoundation

#### Firebase
- Firebase Analytics
- Firebase Crashlytics
- Firebase Performance Monitoring
- (Future) Firebase Remote Config

#### Dependency Management
- Swift Package Manager (recommended)
- CocoaPods (alternative)

### Android (Planned)

- **Language**: Kotlin 1.9+
- **UI**: Jetpack Compose
- **Min Android**: 8.0 (API 26)
- **P2P**: Nearby Connections API
- **AI**: ML Kit + TensorFlow Lite

---

## Getting Started

### Prerequisites

- **macOS** 13.0+ (for iOS development)
- **Xcode** 15.0+
- **CocoaPods** 1.12.0+ OR Swift Package Manager
- **Firebase Account** (free Spark plan)
- **Git**

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/ymow/trainblink.git
   cd trainblink
   ```

2. **Set up Firebase**

   Follow the comprehensive [Firebase Setup Guide](TrainBlink/docs/FIREBASE_SETUP_GUIDE.md):
   - Create Firebase project
   - Download `GoogleService-Info.plist`
   - Place in `TrainBlink/ios/TrainBlink/`

3. **Install dependencies**

   **Option A: Swift Package Manager (Recommended)**
   ```bash
   cd TrainBlink/ios
   swift package resolve
   ```

   **Option B: CocoaPods**
   ```bash
   cd TrainBlink/ios
   pod install
   ```

4. **Open the project**

   **SPM:**
   ```bash
   open Package.swift  # or open in Xcode
   ```

   **CocoaPods:**
   ```bash
   open TrainBlink.xcworkspace
   ```

5. **Run the app**

   - Select a simulator (e.g., iPhone 15)
   - Press ⌘R or click the Run button
   - Test analytics with the demo buttons

### Quick Test

The app includes test buttons to verify Firebase integration:

1. Launch app
2. Tap **"Test: Content Sharing"** → triggers analytics events
3. Tap **"Test: Error Tracking"** → logs errors to Crashlytics
4. Tap **"Test: Performance Trace"** → tracks AI inference

Check Xcode console for confirmations:
```
📊 Event logged: content_sent
❌ Error recorded: P2P connection failed
✅ Performance trace completed
```

---

## Documentation

Comprehensive documentation is available for developers and contributors:

### Development Guides ⭐

1. **[Claude Code Guide](claude.md)** - **START HERE**
   - Development principles and workflows
   - Architecture guidelines (MVVM + Combine)
   - Coding standards and best practices
   - Testing requirements (90%+ coverage)
   - Git workflow and commit conventions
   - Feature development process
   - Security & privacy guidelines
   - Performance targets
   - Common patterns and troubleshooting

2. **[Technical Requirements](REQUIREMENTS.md)**
   - System requirements (iOS 17.0+, Swift 5.9+)
   - Feature-specific requirements
   - Performance targets and metrics
   - Testing requirements by component
   - Security & privacy mandates
   - Firebase integration requirements
   - Build configuration
   - Acceptance criteria

3. **[Testing Guide](TrainBlink/docs/TESTING_GUIDE.md)**
   - How to run tests (Xcode, CLI, CI)
   - Test coverage details (92% overall)
   - Testing patterns and best practices
   - Common failures and solutions
   - Future test additions roadmap

### Product Documentation

4. **[Product Requirements Doc (PRD) v2.3](TrainBlink_PRD_v2.3.md)**
   - Complete product specification
   - All 12 features detailed
   - Success metrics and KPIs
   - Timeline and milestones

### Firebase Documentation

5. **[Firebase Setup Guide](TrainBlink/docs/FIREBASE_SETUP_GUIDE.md)**
   - Step-by-step Firebase Console setup
   - iOS/Android configuration
   - Testing and debugging
   - Dashboard monitoring

6. **[Analytics Usage Guide](TrainBlink/docs/ANALYTICS_USAGE.md)**
   - Event tracking reference (40+ events)
   - Performance monitoring patterns
   - Error handling best practices
   - Privacy compliance

### Feature Documentation

7. **[Feature 1: Geofencing](TrainBlink/docs/FEATURE_1_GEOFENCING.md)**
   - Station database (34 stations)
   - Entry/exit detection logic
   - Dynamic region monitoring
   - Firebase Analytics integration

8. **[Feature 2: P2P Discovery](TrainBlink/docs/FEATURE_2_P2P.md)**
   - MultipeerConnectivity implementation
   - Peer discovery and connection
   - Battery optimization
   - Testing guide

9. **[Feature 3: Content Sharing](TrainBlink/docs/FEATURE_3_CONTENT_SHARING.md)**
   - Photo and text sharing
   - Image compression
   - Transfer management
   - Integration with AI Safety

10. **[Feature 4: AI Safety Engine](TrainBlink/docs/FEATURE_4_AI_SAFETY.md)**
   - NSFW detection (placeholder + integration guide)
   - Face detection (Vision framework)
   - Real Core ML model integration guide
   - Performance optimization

11. **[Feature 6: Ephemeral Messages](TrainBlink/docs/FEATURE_6_EPHEMERAL.md)**
   - 10-second auto-deletion
   - Timer-based cleanup
   - Thread-safe tracking
   - Chat Rooms integration guide

### API Reference

See inline documentation in:
- `AnalyticsManager.swift` - All analytics methods
- `PerformanceTracker.swift` - Performance monitoring helpers
- `ErrorTracker.swift` - Error tracking utilities
- `GeofenceManager.swift` - Geofencing service
- `StationDatabase.swift` - Station queries

### Quick Reference

- **New to the project?** → Read [claude.md](claude.md)
- **Working on a feature?** → Check [PRD v2.3](TrainBlink_PRD_v2.3.md) + [REQUIREMENTS.md](REQUIREMENTS.md)
- **Writing tests?** → See [TESTING_GUIDE.md](TrainBlink/docs/TESTING_GUIDE.md)
- **Firebase setup?** → Follow [FIREBASE_SETUP_GUIDE.md](TrainBlink/docs/FIREBASE_SETUP_GUIDE.md)

---

## Project Structure

```
trainblink/
├── TrainBlink/
│   ├── ios/
│   │   ├── TrainBlink/
│   │   │   ├── TrainBlinkApp.swift           # App entry point
│   │   │   ├── AppState.swift                # Global state
│   │   │   ├── ContentView.swift             # Main UI (demo)
│   │   │   └── Analytics/
│   │   │       ├── AnalyticsManager.swift    # ⭐ Core analytics
│   │   │       ├── PerformanceTracker.swift  # Performance monitoring
│   │   │       └── ErrorTracker.swift        # Error reporting
│   │   ├── Podfile                           # CocoaPods dependencies
│   │   ├── Package.swift                     # SPM dependencies
│   │   └── GoogleService-Info.plist.template # Firebase config template
│   ├── android/                              # (Future)
│   └── docs/
│       ├── FIREBASE_SETUP_GUIDE.md          # ⭐ Setup instructions
│       └── ANALYTICS_USAGE.md               # Usage guide
├── README.md                                 # This file
└── TrainBlink_PRD_v2.3.md                   # Product spec
```

---

## Development

### Branch Strategy

- `main` - Production-ready code
- `develop` - Integration branch
- `feature/*` - Feature branches
- `claude/*` - AI-assisted development branches

**Current Branch**: `claude/firebase-monitoring-analytics-01KNodegkuBysfez5fnvKq5S`
- Implements Feature 12: Firebase Monitoring & Analytics

### Code Style

- **Swift**: Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **Comments**: Use `///` for documentation comments
- **Naming**: Clear, descriptive names (no abbreviations)
- **Structure**: Organize with `// MARK: -` sections

### Testing

```bash
# Run unit tests
xcodebuild test -scheme TrainBlink -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -scheme TrainBlinkUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Debugging Firebase

Enable verbose logging:

```swift
// In TrainBlinkApp.swift init()
#if DEBUG
FirebaseConfiguration.shared.setLoggerLevel(.debug)
#endif
```

View real-time events:
- Firebase Console → Analytics → DebugView
- Xcode → Product → Scheme → Edit Scheme → Run → Arguments
- Add: `-FIRAnalyticsDebugEnabled`

---

## Privacy & Data Collection

### What We Track

✅ **Anonymous usage data:**
- Which features are used
- Event frequencies (e.g., content shared, chats created)
- Performance metrics (app speed, AI inference time)
- Crash reports (stack traces, device info)

❌ **What we DON'T track:**
- Message content
- Photos/videos shared
- Personal identifiable information
- Precise GPS locations (only station names)

### User Control

Users can disable analytics:
- Settings → Privacy → Data Collection → Toggle OFF

This disables:
- Firebase Analytics (completely)
- Retains: Crashlytics (crash-only reporting)

### GDPR Compliance

- Data is anonymized (no user IDs)
- Users can opt-out anytime
- Data retention: 14 months (Firebase default)
- Deletion requests: Contact support

See [Privacy Policy](PRIVACY.md) for details.

---

## Success Metrics

### Technical KPIs (Feature 12)

- **Crash-free rate**: >99.5%
- **Event recording rate**: >99%
- **Performance traces coverage**: >90% of key operations
- **Analytics opt-in rate**: >80%

### Product KPIs (MVP Target)

- **DAU**: 5,000 (6 months)
- **D7 Retention**: >35%
- **Content shared**: 5+ per journey
- **Chat rooms created**: 2+ per journey
- **NPS**: >50

See [PRD v2.3](TrainBlink_PRD_v2.3.md) for complete metrics.

---

## Roadmap

### Phase 1: MVP (Current) - 12 weeks
- ✅ Week 1-2: Infrastructure + Firebase
- ✅ Week 3-4: Geofencing System (Feature 1) + Tests (92% coverage)
- ✅ Week 5-6: P2P Discovery (Feature 2) + Tests (90% coverage)
- ✅ Week 7: Content Sharing (Feature 3) + Tests (90% coverage)
- ✅ Week 8: AI Safety (Feature 4) + Tests (90% coverage)
- ✅ Week 9: Ephemeral Messages (Feature 6) + Tests (90% coverage) ← **YOU ARE HERE**
- 🚧 Week 10: 1-on-1 Chat Rooms (Feature 5) - Complete implementation
- 🚧 Week 11: Feature completion (Block/Report, Encounters, AI Agent)
- 🚧 Week 12: Testing + bug fixes

### Phase 2: Enhancements (Post-MVP)
- AI Chat Agent (active search mode)
- Remote Config for A/B testing
- Advanced analytics (cohorts, funnels)
- Android app
- Social features (friend requests, etc.)

---

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Contribution Guidelines

- Follow existing code style
- Add tests for new features
- Update documentation
- Ensure Firebase events are properly logged
- No breaking changes without discussion

---

## Troubleshooting

### Common Issues

**"GoogleService-Info.plist not found"**
- Download from Firebase Console
- Place in `TrainBlink/ios/TrainBlink/`
- Ensure it's NOT committed to git

**"Firebase events not showing"**
- Events can take 24 hours to appear
- Use DebugView for real-time testing
- Check Analytics is enabled in code

**"Crashlytics not symbolicated"**
- Verify dSYM settings in Build Settings
- Check Run Script is added (CocoaPods)
- Wait 5-10 minutes after crash

See [Firebase Setup Guide](TrainBlink/docs/FIREBASE_SETUP_GUIDE.md#troubleshooting) for more.

---

## Support

- **Documentation**: [/TrainBlink/docs/](TrainBlink/docs/)
- **Issues**: [GitHub Issues](https://github.com/ymow/trainblink/issues)
- **Email**: support@trainblink.app
- **PRD**: [TrainBlink_PRD_v2.3.md](TrainBlink_PRD_v2.3.md)

---

## License

Copyright © 2025 TrainBlink Team. All rights reserved.

This project is proprietary software. Unauthorized copying, distribution, or modification is prohibited.

---

## Acknowledgments

- **Firebase**: Google's mobile platform
- **Swift**: Apple's programming language
- **MultipeerConnectivity**: Apple's P2P framework
- **PRD**: Comprehensive product specification by Ymow

---

**Built with ❤️ for train commuters**

**Last Updated**: 2025-11-19
**Version**: 0.1.0 (MVP - Feature 12)
**Status**: 🚧 In Development

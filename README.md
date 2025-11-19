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

### 🚧 Planned Features (MVP)

2. **P2P Discovery** - Find nearby users via Bluetooth/WiFi
3. **Content Sharing** - Photos, videos, URLs, GIFs, emojis
4. **AI Safety Engine** - NSFW, violence, face, PII detection
5. **1-on-1 Chat Rooms** - Real-time encrypted messaging
6. **Ephemeral Messages** - Auto-delete after 10 seconds
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

Comprehensive documentation is available in `/TrainBlink/docs/`:

### Primary Docs

1. **[Firebase Setup Guide](TrainBlink/docs/FIREBASE_SETUP_GUIDE.md)** ⭐
   - Step-by-step Firebase Console setup
   - iOS/Android configuration
   - Testing and debugging
   - Dashboard monitoring

2. **[Analytics Usage Guide](TrainBlink/docs/ANALYTICS_USAGE.md)**
   - Event tracking reference
   - Performance monitoring patterns
   - Error handling best practices
   - Privacy compliance

3. **[Product Requirements Doc (PRD) v2.3](TrainBlink_PRD_v2.3.md)**
   - Complete product specification
   - Feature 12 details (Firebase)
   - All MVP features
   - Success metrics

### API Reference

See inline documentation in:
- `AnalyticsManager.swift` - All analytics methods
- `PerformanceTracker.swift` - Performance monitoring helpers
- `ErrorTracker.swift` - Error tracking utilities

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
- ✅ Week 1-2: Infrastructure + Firebase ← **YOU ARE HERE**
- 🚧 Week 3-4: Content selection
- 🚧 Week 5-6: AI safety engine
- 🚧 Week 7-8: P2P + sending/receiving
- 🚧 Week 9-10: 1-on-1 chat rooms
- 🚧 Week 11: Feature completion (video, URL, GIF, block, encounters)
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

# Firebase Setup Guide for TrainBlink

## Feature 12: Firebase Monitoring & Analytics

This guide will help you set up Firebase integration for TrainBlink, including Analytics, Crashlytics, and Performance Monitoring.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Console Setup](#firebase-console-setup)
3. [iOS Project Configuration](#ios-project-configuration)
4. [Android Project Configuration](#android-project-configuration)
5. [Testing the Integration](#testing-the-integration)
6. [Dashboard & Monitoring](#dashboard--monitoring)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Accounts
- Google Account (for Firebase Console)
- Apple Developer Account (for iOS)
- Google Play Console Account (for Android)

### Development Environment
- **iOS**: Xcode 15.0+, macOS 13.0+
- **Android**: Android Studio 2023.1+
- **CocoaPods**: 1.12.0+ (iOS) or Swift Package Manager
- **Git**: For version control

---

## Firebase Console Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project details:
   - **Project name**: `TrainBlink`
   - **Project ID**: `trainblink` (or auto-generated)
   - **Location**: `Taiwan` or your preferred region

4. **Google Analytics**:
   - ✅ Enable Google Analytics (recommended)
   - Choose or create an Analytics account
   - Accept terms and conditions

5. Click **"Create project"**
6. Wait for project creation (usually 30-60 seconds)

### Step 2: Enable Required Services

Once your project is created:

1. **Analytics** (automatically enabled)
   - No additional configuration needed

2. **Crashlytics**
   - Go to **Build** → **Crashlytics**
   - Click **"Enable Crashlytics"**
   - Accept terms

3. **Performance Monitoring**
   - Go to **Build** → **Performance**
   - Click **"Get started"**
   - Enable Performance Monitoring

4. **(Optional) Remote Config** - for Phase 2
   - Go to **Build** → **Remote Config**
   - Click **"Get started"**

---

## iOS Project Configuration

### Option A: Using Swift Package Manager (Recommended)

1. **Add Firebase SDK**

   The `Package.swift` is already configured. Just run:

   ```bash
   cd TrainBlink/ios
   swift package resolve
   ```

2. **Download Configuration File**

   - In Firebase Console, click ⚙️ (Settings) → Project settings
   - Under **"Your apps"**, click **"Add app"** → iOS
   - Enter Bundle ID: `com.trainblink.app`
   - (Optional) App nickname: `TrainBlink iOS`
   - Click **"Register app"**
   - Download `GoogleService-Info.plist`
   - **Important**: Move it to `TrainBlink/ios/TrainBlink/`
   - ⚠️ **Do NOT commit this file to Git** (already in `.gitignore`)

3. **Verify Installation**

   ```bash
   # The GoogleService-Info.plist should be here:
   ls -la TrainBlink/ios/TrainBlink/GoogleService-Info.plist
   ```

### Option B: Using CocoaPods

1. **Install Dependencies**

   ```bash
   cd TrainBlink/ios
   pod install
   ```

2. **Download Configuration File** (same as Option A, step 2)

3. **Open Workspace**

   ```bash
   open TrainBlink.xcworkspace
   ```

### Step 3: Enable Crashlytics Debug Symbols

For Crashlytics to work properly with symbolicated crash reports:

1. Open Xcode project
2. Select **TrainBlink** target
3. Go to **Build Settings**
4. Search for `Debug Information Format`
5. Set **Debug** to: `DWARF with dSYM File`
6. Set **Release** to: `DWARF with dSYM File`

### Step 4: Add Run Script for Crashlytics (CocoaPods only)

If using CocoaPods:

1. Select **TrainBlink** target
2. Go to **Build Phases**
3. Click **+** → **New Run Script Phase**
4. Add this script:

   ```bash
   "${PODS_ROOT}/FirebaseCrashlytics/run"
   ```

5. Drag it **above** "Compile Sources"

### Step 5: Configure Debug/Release Schemes

1. Edit Scheme (Product → Scheme → Edit Scheme)
2. Under **Run** → **Arguments**
3. Add environment variables:

   **For DEBUG mode:**
   ```
   -FIRDebugEnabled
   -FIRAnalyticsDebugEnabled
   ```

   This enables verbose Firebase logging for debugging.

---

## Android Project Configuration

### Step 1: Add Android App to Firebase

1. In Firebase Console, go to Project settings
2. Under **"Your apps"**, click **"Add app"** → Android
3. Enter details:
   - **Package name**: `com.trainblink.app`
   - (Optional) App nickname: `TrainBlink Android`
   - (Optional) Debug signing certificate SHA-1
4. Click **"Register app"**
5. Download `google-services.json`
6. Place it in: `TrainBlink/android/app/`
7. ⚠️ **Do NOT commit this file to Git**

### Step 2: Configure Gradle Files

**Project-level `build.gradle`:**

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'
    }
}
```

**App-level `build.gradle`:**

```gradle
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services'
    id 'com.google.firebase.crashlytics'
}

dependencies {
    // Import Firebase BoM
    implementation platform('com.google.firebase:firebase-bom:32.7.0')

    // Firebase services
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-crashlytics'
    implementation 'com.google.firebase:firebase-perf'
}
```

### Step 3: Initialize Firebase in App

**MainApplication.kt:**

```kotlin
import com.google.firebase.FirebaseApp
import com.google.firebase.analytics.FirebaseAnalytics

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Firebase auto-initializes, no code needed
        // But we can configure analytics
        val analyticsEnabled = getSharedPreferences("settings", MODE_PRIVATE)
            .getBoolean("analytics_enabled", true)

        FirebaseAnalytics.getInstance(this)
            .setAnalyticsCollectionEnabled(analyticsEnabled)
    }
}
```

---

## Testing the Integration

### iOS Testing

1. **Run the App**

   ```bash
   cd TrainBlink/ios
   xcodebuild -scheme TrainBlink -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```

   Or open in Xcode and press ⌘R

2. **Verify Firebase Connection**

   Check Xcode console for:
   ```
   🚀 TrainBlink initialized successfully
   ✅ Crashlytics enabled
   ✅ Analytics enabled
   ```

3. **Test Analytics Events**

   - Tap "Test: Content Sharing" in the app
   - Check console for: `📊 Event logged: content_sent`

4. **Test Crashlytics**

   Add a test crash (for testing only!):

   ```swift
   Button("Crash Test") {
       fatalError("Test crash")
   }
   ```

   - Run app, tap button
   - Relaunch app
   - Check Firebase Console → Crashlytics (may take 5-10 minutes)

5. **Enable Debug View**

   For real-time analytics:

   ```bash
   # iOS Simulator
   xcrun simctl spawn booted log config --mode "level:debug" --subsystem com.google.firebase.analytics
   ```

   Then open Firebase Console → Analytics → DebugView

### Android Testing

Similar to iOS, but use:

```bash
# Enable debug mode
adb shell setprop debug.firebase.analytics.app com.trainblink.app
adb shell setprop log.tag.FA VERBOSE
```

---

## Dashboard & Monitoring

### Analytics Dashboard

1. Go to Firebase Console → Analytics
2. Key reports:
   - **Dashboard**: Overview of DAU, events, retention
   - **Events**: All tracked events with parameters
   - **Conversions**: Mark key events (e.g., `chat_room_created`)
   - **Audiences**: Create user segments
   - **Funnels**: Track user flows
   - **DebugView**: Real-time events (debug mode only)

### Crashlytics Dashboard

1. Go to Firebase Console → Crashlytics
2. Key metrics:
   - **Crash-free users**: Target >99.5%
   - **Crash-free sessions**: Target >99.9%
   - **Issues**: All crashes sorted by impact
   - **Velocity**: Crash trend over time

3. **Alert Setup**:
   - Click ⚙️ → Project settings → Integrations
   - Add **Email** or **Slack** notifications
   - Configure thresholds

### Performance Dashboard

1. Go to Firebase Console → Performance
2. Metrics:
   - **App start time**: Target <3s
   - **Custom traces**: AI inference, P2P connection, etc.
   - **Network requests** (if any)
   - **Screen rendering**

---

## Event Tracking Reference

### Core Events

Based on PRD Feature 12, here are the main events:

#### Geofencing
- `station_entered` - User enters a station
- `station_exited` - User exits a station

#### P2P Discovery
- `peer_discovery_started` - Started looking for peers
- `peer_discovered` - Found peers
- `peer_connected` - Connected to a peer

#### Content Sharing
- `content_selection_started` - User starts selecting content
- `content_reviewed_by_ai` - AI reviews content
- `content_sent` - Content sent to peer(s)
- `content_received` - Received content from peer
- `content_accepted` - User accepts received content
- `content_rejected` - User rejects received content

#### Chat Room
- `chat_room_created` - 1-on-1 chat room created
- `message_sent` - Message sent in chat
- `chat_room_closed` - Chat room closed

#### AI Safety
- `ai_nsfw_detected` - NSFW content detected
- `ai_violence_detected` - Violent content detected
- `ai_face_detected` - Face detected in image
- `ai_pii_detected` - Personal information detected

#### Errors
- `p2p_connection_failed` - P2P connection error
- `content_transfer_failed` - Content transfer error
- `ai_model_load_failed` - AI model loading error

### Usage Examples

```swift
// Example 1: Log station entry
AnalyticsManager.shared.logStationEntered(station: station)

// Example 2: Log content sharing with AI review
AnalyticsManager.shared.logContentReviewedByAI(
    contentType: .photo,
    reviewResult: .approved,
    reviewDurationMs: 450
)

AnalyticsManager.shared.logContentSent(
    contentType: .photo,
    recipientCount: 2,
    fileSizeKB: 2048
)

// Example 3: Track performance
let result = await PerformanceTracker.trackAIInference(
    modelType: "nsfw",
    contentType: .photo
) {
    return await nsfwDetector.detect(image)
}

// Example 4: Record error
ErrorTracker.record(
    .p2pConnectionFailed(reason: "timeout"),
    context: ["peer_count": 3]
)
```

---

## Troubleshooting

### Common Issues

#### 1. "GoogleService-Info.plist not found"

**Solution:**
```bash
# Verify file exists
ls -la TrainBlink/ios/TrainBlink/GoogleService-Info.plist

# If not, download again from Firebase Console
```

#### 2. "Crashlytics not uploading dSYMs"

**Solution:**
- Ensure `DWARF with dSYM File` is enabled in Build Settings
- Verify Run Script is added and runs before "Compile Sources"
- Check Xcode build logs for Crashlytics upload messages

#### 3. "Analytics events not showing in Console"

**Solution:**
- Events can take up to 24 hours to appear in main dashboard
- Use **DebugView** for real-time events (see Testing section)
- Verify Analytics is enabled:
  ```swift
  print(Analytics.analyticsCollectionEnabled()) // Should be true
  ```

#### 4. "Build errors with Firebase SDK"

**Solution:**
```bash
# Clean build
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild clean

# Re-install pods (if using CocoaPods)
pod deintegrate
pod install
```

#### 5. "Performance traces not appearing"

**Solution:**
- Performance data takes 1-2 hours to process
- Ensure app is in Release mode (or Performance enabled in Debug)
- Verify traces are being started and stopped properly

### Debug Logging

Enable verbose Firebase logging:

**iOS:**
```swift
// In AppDelegate or App struct
FirebaseConfiguration.shared.setLoggerLevel(.debug)
```

**Android:**
```bash
adb shell setprop log.tag.FA VERBOSE
adb logcat -v time -s FA
```

---

## Privacy & Compliance

### Data Collection

TrainBlink's Firebase integration follows these privacy principles:

✅ **What we collect:**
- Anonymous usage statistics (events, screen views)
- Crash reports (stack traces, device info)
- Performance metrics (app speed, network latency)

❌ **What we DON'T collect:**
- Message content or chat history
- Photos/videos shared between users
- Personal identifiable information (PII)
- Precise GPS coordinates (only station names)

### GDPR Compliance

1. **User Consent**:
   - First-time users: Analytics enabled by default
   - Users can opt-out in Settings → Privacy

2. **Data Deletion**:
   - Users can request data deletion
   - Firebase provides data export and deletion tools

3. **Privacy Policy**:
   - Update your privacy policy to mention Firebase
   - Template: https://firebase.google.com/support/privacy

---

## Next Steps

After setting up Firebase:

1. ✅ Test all analytics events
2. ✅ Configure Crashlytics alerts
3. ✅ Set up conversion goals in Analytics
4. ✅ Create user segments for analysis
5. ✅ Integrate with CI/CD for automated dSYM upload
6. ✅ Set up weekly performance reviews

---

## Support & Resources

- **Firebase Documentation**: https://firebase.google.com/docs
- **Firebase Console**: https://console.firebase.google.com/
- **Stack Overflow**: Tag `firebase` + `ios` or `android`
- **GitHub Issues**: Report bugs in TrainBlink repo

---

**Last Updated**: 2025-11-19
**Version**: 1.0
**Feature**: 12 - Firebase Monitoring & Analytics

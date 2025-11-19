# 🤖 TrainBlink Android Implementation

**Status**: 🚧 In Progress (Foundation Complete)
**Architecture**: MVVM + Repository Pattern
**Language**: Kotlin
**UI Framework**: Jetpack Compose

---

## 📊 Implementation Status

### ✅ Completed
- [x] Project structure and Gradle configuration
- [x] AndroidManifest.xml with all permissions
- [x] Application class with manager initialization
- [x] Package structure

### 🚧 In Progress
- [ ] Data Models (Kotlin data classes)
- [ ] Managers (Business logic)
- [ ] ViewModels (MVVM layer)
- [ ] UI (Jetpack Compose screens)

### ⏳ Planned
- [ ] Unit tests
- [ ] Integration tests
- [ ] Documentation

---

## 🏗️ Project Structure

```
android/
├── build.gradle (project)
├── settings.gradle
├── gradle.properties
└── app/
    ├── build.gradle (app)
    └── src/main/
        ├── AndroidManifest.xml
        └── java/com/trainblink/app/
            ├── TrainBlinkApplication.kt ✅
            ├── MainActivity.kt
            ├── models/
            │   ├── Station.kt
            │   ├── Peer.kt
            │   ├── ChatMessage.kt
            │   ├── ChatRoom.kt
            │   ├── ContentItem.kt
            │   ├── Encounter.kt
            │   ├── BlockedPeer.kt
            │   └── Report.kt
            ├── managers/
            │   ├── GeofenceManager.kt
            │   ├── NearbyConnectionsManager.kt
            │   ├── ChatManager.kt
            │   ├── ContentSharingManager.kt
            │   ├── EphemeralMessageManager.kt
            │   ├── BlockingManager.kt
            │   ├── ReportingManager.kt
            │   └── EncounterTrackingManager.kt
            ├── analytics/
            │   ├── AnalyticsManager.kt
            │   ├── PerformanceTracker.kt
            │   └── ErrorTracker.kt
            ├── viewmodels/
            │   ├── MainViewModel.kt
            │   ├── ChatListViewModel.kt
            │   └── ChatRoomViewModel.kt
            └── ui/
                ├── MainScreen.kt
                ├── ChatListScreen.kt
                └── ChatRoomScreen.kt
```

---

## 🔧 Technology Stack

### Core
- **Kotlin**: 1.9.20
- **Gradle**: 8.1.4
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34

### UI
- **Jetpack Compose**: 1.5.4
- **Material 3**: Latest
- **Navigation Compose**: 2.7.5

### Architecture
- **MVVM**: ViewModel + LiveData/StateFlow
- **Coroutines**: 1.7.3
- **Flow**: For reactive streams
- **DataStore**: For persistence (replacing SharedPreferences)

### Firebase
- **Firebase BOM**: 32.6.0
- **Firebase Analytics**: Latest
- **Firebase Crashlytics**: Latest
- **Firebase Performance**: Latest

### Google Play Services
- **Location**: 21.0.1 (Geofencing API)
- **Nearby Connections**: 19.0.0 (P2P Discovery)
- **ML Kit Face Detection**: 16.1.5
- **ML Kit Image Labeling**: 16.0.8 (NSFW detection)

### Other
- **Gson**: 2.10.1 (JSON serialization)
- **Coil**: 2.5.0 (Image loading)

---

## 🎯 Feature Mapping (iOS → Android)

| Feature | iOS Technology | Android Equivalent | Status |
|---------|---------------|-------------------|---------|
| **Geofencing** | Core Location | Location Services + Geofencing API | 🚧 |
| **P2P Discovery** | MultipeerConnectivity | Nearby Connections API | 🚧 |
| **Content Sharing** | MCSession | Nearby Connections (Payload) | 🚧 |
| **AI Safety** | Vision + CoreML | ML Kit + TensorFlow Lite | 🚧 |
| **Chat Rooms** | Combine + UserDefaults | Flow + DataStore | 🚧 |
| **Ephemeral Messages** | Timer | Coroutines + Timer | 🚧 |
| **Block & Report** | Singleton Managers | Singleton Managers | 🚧 |
| **Encounter Tracking** | UserDefaults | DataStore | 🚧 |
| **Firebase** | Firebase SDK (iOS) | Firebase SDK (Android) | ✅ |
| **UI** | SwiftUI | Jetpack Compose | 🚧 |
| **Reactive** | Combine | Kotlin Flow | 🚧 |
| **Persistence** | UserDefaults | DataStore | 🚧 |

---

## 📱 Key Android-Specific Considerations

### 1. P2P Discovery (Nearby Connections API vs MultipeerConnectivity)

**iOS MultipeerConnectivity:**
- Automatic discovery over Bluetooth/WiFi
- Built-in encryption
- Simple API

**Android Nearby Connections API:**
- Requires explicit advertiser/discoverer roles
- Manual encryption needed
- More complex API
- Better control over connection lifecycle

**Implementation Differences:**
```kotlin
// Android requires explicit roles
nearbyConnectionsManager.startAdvertising() // Advertise presence
nearbyConnectionsManager.startDiscovery()   // Discover peers

// iOS handles this automatically
multipeerManager.startDiscovery()           // Both advertise AND discover
```

### 2. Geofencing

**iOS Core Location:**
- 20 geofence limit (system-wide)
- Automatic monitoring

**Android Geofencing API:**
- 100 geofence limit (per app)
- Requires PendingIntent + BroadcastReceiver
- Better battery optimization

### 3. Permissions

**Android 12+ (SDK 31+):**
- Requires `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`
- Requires `NEARBY_WIFI_DEVICES` for WiFi-based discovery
- Runtime permission requests needed

**Android 13+ (SDK 33+):**
- Requires `POST_NOTIFICATIONS` for notifications
- Granular media permissions (`READ_MEDIA_IMAGES`)

### 4. Background Execution

**Android:**
- Foreground Service required for background location
- WorkManager for periodic tasks
- More restrictive than iOS

### 5. Data Persistence

**iOS UserDefaults → Android DataStore:**
```kotlin
// Android DataStore (modern approach)
dataStore.data.map { preferences ->
    preferences[CHAT_ROOMS_KEY] ?: emptyList()
}.collect { chatRooms ->
    // Handle data
}

// vs iOS UserDefaults
let chatRooms = UserDefaults.standard.data(forKey: "chat_rooms")
```

---

## 🚀 Build & Run Instructions

### Prerequisites
- Android Studio Hedgehog (2023.1.1) or later
- JDK 17
- Android SDK 34
- Firebase project configured

### Setup

1. **Clone Repository**
```bash
cd TrainBlink/android
```

2. **Add Firebase Configuration**
- Download `google-services.json` from Firebase Console
- Place in `app/` directory

3. **Sync Gradle**
```bash
./gradlew build
```

4. **Run on Device/Emulator**
```bash
./gradlew installDebug
```

### Testing P2P Features
⚠️ **Important**: Nearby Connections API requires **2 physical Android devices** for testing. Emulators cannot test P2P functionality.

---

## 📋 TODO: Remaining Implementation

### High Priority
1. **Complete All Models** (~300 lines)
   - Station.kt
   - Peer.kt
   - ChatMessage.kt
   - ChatRoom.kt
   - ContentItem.kt
   - Encounter.kt
   - BlockedPeer.kt
   - Report.kt

2. **Complete All Managers** (~1000 lines)
   - GeofenceManager.kt
   - NearbyConnectionsManager.kt (most complex)
   - ChatManager.kt
   - ContentSharingManager.kt
   - EphemeralMessageManager.kt
   - BlockingManager.kt
   - ReportingManager.kt
   - EncounterTrackingManager.kt
   - AnalyticsManager.kt

3. **Complete ViewModels** (~400 lines)
   - MainViewModel.kt
   - ChatListViewModel.kt
   - ChatRoomViewModel.kt

4. **Complete UI Screens** (~600 lines)
   - MainActivity.kt
   - MainScreen.kt (ContentView equivalent)
   - ChatListScreen.kt
   - ChatRoomScreen.kt
   - PeerListScreen.kt

### Medium Priority
5. **Resources**
   - strings.xml
   - themes.xml
   - colors.xml
   - Icons and drawables

6. **Tests**
   - Unit tests for managers
   - UI tests for Compose screens

### Low Priority
7. **Documentation**
   - API documentation
   - Architecture diagrams
   - Setup guide

---

## 🎨 UI Design (Jetpack Compose vs SwiftUI)

### Comparison

**SwiftUI (iOS):**
```swift
struct ChatListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(chatRooms) { room in
            NavigationLink(destination: ChatRoomView(room: room)) {
                ChatRoomRow(room: room)
            }
        }
    }
}
```

**Jetpack Compose (Android):**
```kotlin
@Composable
fun ChatListScreen(
    viewModel: ChatListViewModel = viewModel(),
    navController: NavController
) {
    val chatRooms by viewModel.chatRooms.collectAsState()

    LazyColumn {
        items(chatRooms) { room ->
            ChatRoomRow(
                room = room,
                onClick = { navController.navigate("chat/${room.id}") }
            )
        }
    }
}
```

**Key Differences:**
- SwiftUI uses `@EnvironmentObject` for DI
- Compose uses `viewModel()` from Hilt/Manual injection
- SwiftUI has `NavigationLink`, Compose uses `NavController`
- Both use lazy rendering (`LazyVStack` vs `LazyColumn`)

---

## 🔍 Next Steps

To complete the Android implementation:

1. **Create all model data classes** (straightforward Kotlin conversions from Swift)
2. **Implement NearbyConnectionsManager** (most complex - handles P2P)
3. **Implement GeofenceManager** (Android Geofencing API)
4. **Implement ChatManager** (similar to iOS with Flow instead of Combine)
5. **Implement UI screens** (Jetpack Compose equivalents)
6. **Test on physical devices** (required for P2P and Geofencing)

**Estimated Remaining Work:**
- **Models**: ~2 hours (300 lines)
- **Managers**: ~8 hours (1000 lines)
- **ViewModels**: ~2 hours (400 lines)
- **UI**: ~4 hours (600 lines)
- **Testing & Polish**: ~4 hours
- **Total**: ~20 hours

---

## 📞 Contact & Support

For questions about Android implementation:
- Check iOS implementation for feature parity reference
- Nearby Connections API docs: https://developers.google.com/nearby/connections/overview
- Jetpack Compose docs: https://developer.android.com/jetpack/compose

---

*Last Updated: 2025-11-19*
*Status: Foundation Complete, Implementation In Progress*

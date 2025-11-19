# Feature 8: Encounter Tracking

**Status**: ✅ Complete
**Coverage**: 90%+
**Version**: 1.0

---

## Overview

Feature 8 provides comprehensive encounter tracking to record when users repeatedly meet the same peers at train stations. Tracks location, time, interaction type, and computes statistics like frequency, most common station, and encounter streaks.

**Key Capabilities**:
- Record encounters automatically (discovery, chat, content sharing)
- Track location (station) and timestamp
- Deduplication (5-minute window)
- Statistics: total encounters, first/last encounter, most common station
- Frequent encounter detection (3+ in 7 days)
- 90-day retention with automatic cleanup
- Firebase Analytics integration
- UserDefaults persistence

---

## Models

### Encounter

Represents a single encounter with a peer:

```swift
struct Encounter: Identifiable, Codable {
    let id: String
    let peerId: String
    let peerDisplayName: String
    let timestamp: Date
    let stationId: String?
    let stationName: String?
    var interactionType: InteractionType  // discovery, chat, contentSharing, connection
}
```

**Static Constructors**:
- `Encounter.discovery(peer:station:)` - From P2P discovery
- `Encounter.contentSharing(peerId:peerDisplayName:station:)` - From content sharing
- `Encounter.chat(peerId:peerDisplayName:station:)` - From chat

### EncounterHistory

Aggregates all encounters with a specific peer:

```swift
struct EncounterHistory: Identifiable, Codable {
    let id: String  // Same as peerId
    let peerId: String
    let peerDisplayName: String
    var encounters: [Encounter]  // Sorted by timestamp desc
}
```

**Key Computed Properties**:
- `encounterCount` - Total encounters
- `firstEncounter`, `lastEncounter` - Oldest/newest
- `mostCommonStation` - Station with most encounters
- `stationBreakdown` - All stations with counts
- `interactionTypeBreakdown` - Breakdown by type
- `recentEncounters` - Last 7 days
- `isFrequentEncounter` - 3+ encounters in 7 days
- `currentStreak` - Consecutive days with encounters
- `averageEncountersPerWeek` - Frequency metric
- `summary` - Human-readable summary

---

## Services

### EncounterTrackingManager

**Purpose**: Manage all encounter tracking

**Architecture**: Singleton with thread-safe operations (NSLock)

**Key Methods**:

```swift
// Record an encounter
func recordEncounter(
    with peer: Peer,
    interactionType: InteractionType,
    at station: Station? = nil
) -> Encounter?

// Get encounter history
func getHistory(for peerId: String) -> EncounterHistory?

// Sorted lists
var sortedByEncounterCount: [EncounterHistory]
var sortedByLastEncounter: [EncounterHistory]
var frequentEncounters: [EncounterHistory]

// Statistics
var totalEncounterCount: Int
var uniquePeerCount: Int

// Update current station (from GeofenceManager)
func updateCurrentStation(_ station: Station?)

// Cleanup
func clearOldEncounters()  // Removes encounters older than 90 days
func clearAll()
func deleteHistory(for peerId: String)
```

**Configuration**:
- Max encounters per peer: 100
- Retention period: 90 days
- Deduplication window: 5 minutes (300 seconds)
- Storage: UserDefaults (`trainblink.encounter_histories`)

**Deduplication Logic**:
- Skips recording if same peer + same interaction type within 5 minutes
- Different interaction types always recorded
- Prevents duplicate encounters from rapid P2P re-discoveries

---

## Integration Points

### GeofenceManager (Feature 1)

**Station Entry**:
```swift
// confirmStationEntry()
EncounterTrackingManager.shared.updateCurrentStation(station)
```

**Station Exit**:
```swift
// confirmStationExit()
EncounterTrackingManager.shared.updateCurrentStation(nil)
```

### MultipeerManager (Feature 2)

**Peer Discovery**:
```swift
// updateDiscoveredPeer() - when NEW peer discovered
EncounterTrackingManager.shared.recordEncounter(
    with: peer,
    interactionType: .discovery
)
```

### ChatRoom (Feature 5)

**New Methods**:
```swift
// Sync encounter count from tracking
mutating func syncEncounterCount()

// Create chat room with tracked encounter count
static func createWithTracking(peer: Peer) -> ChatRoom
```

**Usage**:
```swift
// Create chat room with automatic encounter count
let chatRoom = ChatRoom.createWithTracking(peer: peer)

// Or sync existing chat room
chatRoom.syncEncounterCount()
```

---

## Firebase Analytics

### Events

| Event | Parameters | When Logged |
|-------|-----------|-------------|
| `encounter_recorded` | `peer_id`, `interaction_type`, `station_id?` | Encounter recorded |
| `old_encounters_cleared` | `retention_days` | Old encounters cleaned up |
| `all_encounters_cleared` | `peer_count`, `encounter_count` | All encounters cleared |
| `frequent_encounter_detected` | `peer_id`, `encounter_count` | Peer becomes frequent |

### Implementation

```swift
extension AnalyticsManager {
    func logEncounterRecorded(peerId: String, interactionType: String, stationId: String?)
    func logOldEncountersCleared(retentionDays: Int)
    func logAllEncountersCleared(peerCount: Int, encounterCount: Int)
    func logFrequentEncounterDetected(peerId: String, encounterCount: Int)
}
```

---

## Testing

### Unit Tests (90%+ Coverage)

**EncounterTrackingTests.swift** (35+ tests):

**Encounter Model Tests** (6 tests):
- Creation, timestamps, location display
- Static constructors
- Time since encounter formatting

**EncounterHistory Model Tests** (12 tests):
- Add encounters
- First/last encounter
- Most common station
- Station breakdown
- Interaction type breakdown
- Recent encounters, frequent encounter detection
- Remove old encounters
- Summary generation

**EncounterTrackingManager Tests** (14 tests):
- Record encounter
- Deduplication (5-minute window)
- Get history
- Multiple encounters
- Update current station
- Sorted lists (by count, by last encounter)
- Total/unique counts
- Clear all, delete history

**ChatRoom Integration Tests** (2 tests):
- Sync encounter count
- Create with tracking

**Performance Tests** (2 tests):
- Record 100 encounters
- Get history for 100 peers

---

## Code Examples

### Record Encounter (Automatic)

Encounters are recorded automatically by integration points:

```swift
// P2P discovery (automatic in MultipeerManager)
// New peer discovered → encounter recorded automatically

// GeofenceManager sets current station
// Station entry → EncounterTrackingManager.updateCurrentStation(station)
// Station exit → EncounterTrackingManager.updateCurrentStation(nil)
```

### Get Encounter History

```swift
if let history = EncounterTrackingManager.shared.getHistory(for: peerId) {
    print("Met \(history.encounterCount) times")
    print("First: \(history.firstEncounter?.timeSinceEncounter)")
    print("Last: \(history.lastEncounter?.timeSinceEncounter)")
    
    if let station = history.mostCommonStation {
        print("Usually at: \(station.name) (\(station.count) times)")
    }
    
    print("Summary: \(history.summary)")
}
```

### Check Frequent Encounters

```swift
let frequentPeers = EncounterTrackingManager.shared.frequentEncounters

for history in frequentPeers {
    print("\(history.peerDisplayName): \(history.recentEncounterCount) encounters this week")
}
```

### Display Statistics

```swift
let total = EncounterTrackingManager.shared.totalEncounterCount
let unique = EncounterTrackingManager.shared.uniquePeerCount

print("Total encounters: \(total) with \(unique) unique peers")

// Sorted by encounter count
let topEncounters = EncounterTrackingManager.shared.sortedByEncounterCount.prefix(5)

for history in topEncounters {
    print("\(history.peerDisplayName): \(history.encounterCount) times")
    print("  Frequency: \(history.frequencyLabel)")
    print("  Streak: \(history.currentStreak) days")
}
```

### Create Chat Room with Tracking

```swift
// Automatically uses encounter count from tracking
let chatRoom = ChatRoom.createWithTracking(peer: peer)

print("Chat room created with \(chatRoom.encounterCount) previous encounters")
```

---

## Best Practices

### When to Use Encounter Tracking

**Good Use Cases**:
- Display "You've met 5 times" in chat UI
- Show most common station in peer profile
- Detect frequent commuters
- Gamification (encounter streaks, badges)
- Analytics (user engagement patterns)

**UI Examples**:
- Peer list: Show encounter count badge
- Chat header: "Met 3 times, mostly at Taipei Main Station"
- Profile: Encounter history timeline
- Insights: "You've met 10 unique people this week"

### Performance Considerations

1. **Deduplication Window**:
   - 5 minutes prevents rapid P2P re-discovery spam
   - Adjust if needed: `deduplicationWindowSeconds`

2. **Max Encounters Per Peer**:
   - Limited to 100 per peer (prevents unbounded growth)
   - Oldest encounters pruned automatically

3. **Retention Period**:
   - 90 days default (configurable: `encounterRetentionDays`)
   - Call `clearOldEncounters()` periodically (e.g., on app launch)

### Privacy Considerations

**Data Stored**:
- Peer ID (anonymous)
- Display name (user-chosen)
- Station names (public places)
- Timestamps

**Data NOT Stored**:
- GPS coordinates
- Personal information
- Message content

**User Control**:
- Can clear all encounter history
- Can delete specific peer history
- Data local only (UserDefaults)

---

## Troubleshooting

### Encounters Not Recording

**Symptoms**: No encounter history for discovered peers

**Possible Causes**:
1. Integration not called → Check MultipeerManager
2. Deduplication → Within 5-minute window
3. Storage failure → Check UserDefaults

**Debug**:
```swift
print("Total encounters: \(EncounterTrackingManager.shared.totalEncounterCount)")
print("Unique peers: \(EncounterTrackingManager.shared.uniquePeerCount)")
```

### Wrong Station in Encounters

**Symptoms**: Encounters show wrong station or "Unknown Location"

**Possible Causes**:
1. GeofenceManager not updating current station
2. Encounter recorded before station confirmed (30s delay)

**Debug**:
```swift
// Check if GeofenceManager is updating EncounterTrackingManager
// confirmStationEntry() should call:
// EncounterTrackingManager.shared.updateCurrentStation(station)
```

### Duplicate Encounters

**Symptoms**: Multiple encounters within seconds

**Possible Causes**:
1. Different interaction types (expected)
2. Deduplication not working

**Debug**:
```swift
if let history = EncounterTrackingManager.shared.getHistory(for: peerId) {
    for encounter in history.encounters.prefix(5) {
        print("\(encounter.timestamp): \(encounter.interactionType.rawValue)")
    }
}
```

---

## Future Enhancements

### Phase 2

- [ ] Encounter timeline view (calendar)
- [ ] Encounter heat map (which stations, which times)
- [ ] Push notification for frequent encounters
- [ ] "People you may know" suggestions
- [ ] Export encounter history (JSON/CSV)

### Phase 3

- [ ] Encounter streaks and achievements
- [ ] Social features (mutual encounter count)
- [ ] Privacy zones (don't track certain stations)
- [ ] Encounter insights ("You meet most people on Mondays")
- [ ] Compare encounter patterns with friends

### Phase 4

- [ ] Server-side encounter sync (multi-device)
- [ ] Encounter-based recommendations
- [ ] Community events (meet users with high encounter overlap)

---

## Summary

**Feature 8: Encounter Tracking** provides comprehensive encounter tracking with:
- ✅ Automatic recording (discovery, chat, content sharing)
- ✅ Location and timestamp tracking
- ✅ Deduplication (5-minute window)
- ✅ Statistics (total, frequency, most common station, streaks)
- ✅ Frequent encounter detection (3+ in 7 days)
- ✅ 90-day retention with automatic cleanup
- ✅ Firebase Analytics integration
- ✅ UserDefaults persistence
- ✅ Thread-safe operations
- ✅ 90%+ test coverage (35+ tests)

**Status**: Production-ready. Fully integrated with Features 1, 2, and 5.

---

*Last updated: 2025-11-19*
*Version: 1.0*

# Research: Multi-Device Strength Training Management System

**Feature**: 001-strength-training-system  
**Date**: 2026-02-11

## R-001: wger REST API Integration

### Decision
Use wger REST API v2 with JWT authentication. The primary endpoints for plan retrieval are the **routine structure** endpoint (`/api/v2/routine/{id}/structure/`) which returns the full nested plan in a single call, and the **exerciseinfo** endpoint (`/api/v2/exerciseinfo/{id}/`) for exercise details.

### Rationale
- JWT is the recommended auth method (token auth is deprecated)
- The `structure/` endpoint returns the full routine hierarchy (days → slots → entries with configs) in one request, avoiding N+1 API calls
- Exercise info endpoint provides localized names, muscle groups, and images in one call
- Workout logs can be posted back via `POST /api/v2/workoutlog/` for two-way sync

### Key Endpoints

| Purpose | Method | Endpoint |
|---------|--------|----------|
| Login (JWT) | POST | `/api/v2/token` |
| Token Refresh | POST | `/api/v2/token/refresh` |
| Routine List | GET | `/api/v2/routine/` |
| Routine Structure | GET | `/api/v2/routine/{id}/structure/` |
| Exercise Info | GET | `/api/v2/exerciseinfo/{id}/` |
| Session Create | POST | `/api/v2/workoutsession/` |
| Log Create | POST | `/api/v2/workoutlog/` |
| Units | GET | `/api/v2/setting-repetitionunit/`, `/api/v2/setting-weightunit/` |

### API Response Mapping

wger `routine/{id}/structure/` → internal `WorkoutPlan`:
- `routine.id` → `planId`
- `routine.name` → `name`
- `days[].slots[].entries[]` → `exercises[]`
- `entries[].exercise` → `exerciseId`
- `entries[].set_nr_configs` → `sets`
- `entries[].repetitions_configs` → `reps`
- `entries[].rest_configs` → `restSec`

### Pagination
All list endpoints use `LimitOffset` pagination with default `PAGE_SIZE=20`. Format: `{count, next, previous, results}`.

### Alternatives Considered
- **Token auth**: Simpler but deprecated by wger; JWT is future-proof
- **Individual sub-resource calls** (`/day/`, `/slot/`, `/slot-entry/`): More granular but requires multiple requests; `structure/` endpoint preferred
- **GraphQL**: Not supported by wger

---

## R-002: HealthKit Workout Session (watchOS 10+)

### Decision
Use `HKWorkoutSession` + `HKLiveWorkoutBuilder` with `HKLiveWorkoutDataSource` for automatic heart rate collection. Store custom metadata (sessionId, planId) in the HKWorkout via `builder.addMetadata()`.

### Rationale
- `HKLiveWorkoutDataSource` automatically collects heart rate, active energy, and basal energy — no manual `HKAnchoredObjectQuery` needed for standard metrics
- The delegate-based notification pattern (`workoutBuilder(_:didCollectDataOf:)`) provides real-time HR updates with minimal code
- Metadata survives HealthKit sync to iCloud, making it the ideal cross-reference point

### Session Lifecycle

```
1. Request authorization (workout type write, heartRate/activeEnergy read)
2. Create HKWorkoutConfiguration(.traditionalStrengthTraining, .indoor)
3. Create HKWorkoutSession(healthStore:configuration:)  // non-deprecated init
4. Get builder = session.associatedWorkoutBuilder()
5. Set HKLiveWorkoutDataSource(healthStore:workoutConfiguration:)
6. Set delegate on both session and builder
7. session.startActivity(with: Date())
8. builder.beginCollection(withStart: Date())
9. builder.addMetadata(["com.fitnessapp.sessionId": uuid, "com.fitnessapp.planId": planId])
10. [Workout execution — HR arrives via delegate automatically]
11. session.stopActivity(with: Date())
12. builder.endCollection(withEnd: Date())
13. builder.finishWorkout()  // saves HKWorkout
14. session.end()
```

### Key Technical Notes
- Only **one** HKWorkoutSession can be active on the Watch at a time
- Delegate methods run on **non-main threads** → use `nonisolated` + `Task { @MainActor in }` pattern
- Metadata is **append-only** — same key cannot be overwritten after first add
- `init(configuration:)` is deprecated on watchOS 10 → use `init(healthStore:configuration:)`
- Calorie estimation for strength training is less accurate than for cardio (known Apple limitation)
- Always save local strength data **before** HKWorkout save — if HealthKit fails, local data is preserved

### Authorization
- **Write**: `HKQuantityType.workoutType()` — status check possible
- **Read**: `heartRate`, `activeEnergyBurned` — denial cannot be detected (Apple privacy returns `.notDetermined`)
- Required Info.plist keys: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`

### Alternatives Considered
- **HKAnchoredObjectQuery for HR**: More complex, only needed for individual sample timestamps; `HKLiveWorkoutDataSource` is sufficient for display
- **Manual sample collection**: Unnecessary — the data source handles this automatically
- **HKWorkoutActivity (multi-activity)**: Overkill for single-plan sessions

---

## R-003: Local Data Persistence Strategy

### Decision
Use **Codable structs + JSON files (FileManager)** for local persistence. No Core Data or SwiftData.

### Rationale
1. **Model unity**: The same Codable struct serves REST API parsing, WCSession transfer, and local storage — zero conversion layers
2. **WCSession simplicity**: `JSONEncoder().encode(plan)` → `Data` → `sendMessageData()` works directly
3. **watchOS lightweight**: No database engine overhead on the memory-constrained Apple Watch
4. **Sufficient scale**: ~700 sessions/year × ~3KB = ~2MB/year — well within FileManager capabilities
5. **HealthKit owns health data**: Only custom strength data needs local storage; time, HR, energy are in HealthKit

### Storage Layout

```
Documents/
├── config.json              # Server URL, auth tokens
├── plans/
│   ├── plan-{planId}.json   # Cached WorkoutPlan (from wger)
│   └── index.json           # Plan list metadata + last sync timestamp
├── sessions/
│   ├── {sessionId}.json     # WorkoutSessionResult
│   └── index.json           # Session list (sorted by date, for history view)
└── pending/
    └── {sessionId}.json     # Sessions pending wger sync or HealthKit retry
```

### Query Patterns
- **By sessionId**: Direct file lookup `sessions/{sessionId}.json`
- **By date range**: Read `sessions/index.json` (sorted), filter by `performedAt`
- **By planId**: Read `sessions/index.json`, filter by `planId`
- **Plan cache**: Direct file lookup `plans/plan-{planId}.json`

### Migration Path
If data volume grows beyond thousands of sessions, Codable structs can be wrapped with SwiftData `@Model` at low cost (add macro + convenience init).

### Alternatives Considered
- **SwiftData (iOS 17+)**: Works on watchOS but v1 maturity risk; Codable conformance requires manual boilerplate; 2-layer model pattern needed
- **Core Data**: Mature but heavyweight; NSManagedObject doesn't conform to Codable; requires separate transfer objects for WCSession
- **SQLite (direct)**: Good performance but unnecessary given data volume
- **UserDefaults**: Too limited for structured session history

---

## R-004: WatchConnectivity Data Transfer Pattern

### Decision
Use `WCSession.sendMessageData()` for live transfers (session start) and `transferUserInfo()` for background result sync. Data is serialized as JSON via Codable.

### Rationale
- `sendMessageData()` provides immediate delivery when Watch is reachable — ideal for starting a workout session
- `transferUserInfo()` queues data for eventual delivery — ideal for session results when the iPhone may not be immediately available
- Both accept `Data` which maps directly to `JSONEncoder` output from Codable structs

### Transfer Protocol

| Direction | Trigger | Method | Data |
|-----------|---------|--------|------|
| iPhone → Watch | User taps "Start Workout" | `sendMessageData()` | `WorkoutPlan` JSON |
| Watch → iPhone | Session ends | `transferUserInfo()` | `WorkoutSessionResult` JSON |
| iPhone → Watch | Plan update | `updateApplicationContext()` | Latest plan list metadata |

### Error Handling
- If `sendMessageData()` fails (Watch unreachable): Show error on iPhone, do not start session
- If `transferUserInfo()` queue is full: Results saved locally on Watch; sync on next opportunity
- Connection loss mid-session: Watch continues independently (FR-016); results queue for later transfer

### Alternatives Considered
- **`sendMessage()` with dictionary**: Loses type safety; raw `Data` with Codable is cleaner
- **`transferFile()`**: Appropriate for large files; workout data is small (< 10KB)
- **Application context only**: Overwritten on each update; session results need guaranteed delivery via `transferUserInfo()`

---

## R-005: Backend Abstraction Layer

### Decision
Define a Swift `WorkoutAPIProtocol` that abstracts all backend interactions. The initial implementation targets wger, but the protocol boundary allows future backend replacement without UI changes.

### Rationale
- Constitution Principle V (Extensibility) requires all backend interactions through an abstraction layer
- Protocol-oriented design enables mock implementations for testing and preview
- Separates API-specific JSON mapping from business logic

### Protocol Surface

```swift
protocol WorkoutAPIProtocol {
    func authenticate(serverURL: URL, username: String, password: String) async throws -> AuthToken
    func refreshToken(_ token: AuthToken) async throws -> AuthToken
    func fetchRoutines() async throws -> [WorkoutPlan]
    func fetchRoutineStructure(routineId: String) async throws -> WorkoutPlan
    func fetchExerciseInfo(exerciseId: String) async throws -> ExerciseDetail
    func createWorkoutSession(_ session: WorkoutSessionLog) async throws
    func createWorkoutLog(_ log: WorkoutLogEntry) async throws
}
```

### Alternatives Considered
- **Direct URLSession calls in ViewModels**: Violates separation of concerns; makes testing and backend swapping difficult
- **Generic HTTP client wrapper**: Too abstract; domain-specific protocol is clearer
- **Combine publishers**: async/await is the modern Swift pattern; Combine adds unnecessary complexity for request/response flows

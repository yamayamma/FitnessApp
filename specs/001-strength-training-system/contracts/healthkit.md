# API Contracts: HealthKit Integration

**Feature**: 001-strength-training-system  
**Date**: 2026-02-11

## Overview

HealthKit is used for two purposes:
1. **Workout recording** — saving HKWorkout with heart rate and energy data during sessions
2. **Cross-reference** — linking HKWorkout to local strength data via metadata UUID

HealthKit owns: time, duration, heart rate, active/basal energy, workout type.  
Local storage owns: sets, reps, weight, exercise details.

---

## Required Permissions

### Write Types
| Type | Identifier | Purpose |
|------|-----------|---------|
| Workout | `HKObjectType.workoutType()` | Save HKWorkout records |

### Read Types
| Type | Identifier | Purpose |
|------|-----------|---------|
| Heart Rate | `HKQuantityType(.heartRate)` | Display real-time HR on Watch |
| Active Energy | `HKQuantityType(.activeEnergyBurned)` | Session energy summary |

### Info.plist Keys
- `NSHealthShareUsageDescription`: "FitnessApp reads heart rate and energy data during workout sessions to display real-time metrics and session summaries."
- `NSHealthUpdateUsageDescription`: "FitnessApp saves your workout sessions to Apple Health so they appear in your health data and activity rings."

---

## Workout Configuration

```
Activity Type: .traditionalStrengthTraining
Location Type: .indoor
```

---

## Metadata Contract

Custom metadata stored in HKWorkout:

| Key | Type | Example | Description |
|-----|------|---------|-------------|
| `com.fitnessapp.sessionId` | `String` | `"550e8400-e29b-41d4-a716-446655440000"` | Links to WorkoutSessionResult |
| `com.fitnessapp.planId` | `String` | `"1"` | Links to the originating WorkoutPlan |
| `com.fitnessapp.schemaVersion` | `String` | `"1.0.0"` | Schema version at creation time |

### Metadata Rules
- Metadata MUST be added via `builder.addMetadata()` after `beginCollection()` and before `endCollection()`
- Metadata is **append-only** — keys cannot be updated after initial write
- All values MUST be String type (HealthKit metadata requirement)

---

## Session Lifecycle Contract

### Preconditions
1. HealthKit authorization requested and workout write granted
2. WorkoutPlan with selectedDayId received from iPhone
3. No other HKWorkoutSession currently active

### Sequence
```
[Authorization Check]
    ↓
[Create HKWorkoutConfiguration]
    ↓
[Create HKWorkoutSession(healthStore:configuration:)]
    ↓
[Get HKLiveWorkoutBuilder via session.associatedWorkoutBuilder()]
    ↓
[Attach HKLiveWorkoutDataSource]  ← auto-collects HR, energy
    ↓
[Set delegates on session + builder]
    ↓
[session.startActivity(with: startDate)]
    ↓
[builder.beginCollection(withStart: startDate)]
    ↓
[builder.addMetadata(sessionId, planId, schemaVersion)]
    ↓
[... workout execution — delegate receives HR/energy updates ...]
    ↓
[session.stopActivity(with: endDate)]
    ↓
[builder.endCollection(withEnd: endDate)]
    ↓
[builder.finishWorkout()]  ← saves HKWorkout to HealthKit
    ↓
[session.end()]
```

### Postconditions
1. HKWorkout exists in HealthKit with correct activity type, duration, and metadata
2. Heart rate samples are associated with the workout
3. Active energy burned is calculated and associated

---

## Data Reading Contract (iPhone)

### Query Workouts by Metadata

To correlate HealthKit workouts with local session data on iPhone:

```
Predicate: HKQuery.predicateForObjects(withMetadataKey: "com.fitnessapp.sessionId", operatorType: .equalTo, value: sessionId)
Sort: HKSampleSortIdentifierStartDate, descending
```

### Read Heart Rate for Session

```
Predicate: HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate)
Type: HKQuantityType(.heartRate)
Unit: HKUnit.count().unitDivided(by: .minute())  → BPM
```

---

## Error Handling

| Error | Detection | Action |
|-------|-----------|--------|
| Authorization denied (write) | `healthStore.authorizationStatus(for: workoutType) == .sharingDenied` | Save local data only; set `isHealthKitSynced = false` |
| Authorization not determined (read) | Cannot detect — Apple privacy returns `.notDetermined` even if denied | Proceed; HR display may show no data |
| Another workout active | `HKWorkoutSession` init throws | Show error; prompt user to end other workout |
| Builder finish fails | `finishWorkout()` throws | Log error; local data already saved; mark `isHealthKitSynced = false` |
| Session interrupted (app crash) | `WKApplicationDelegate.handle(_:)` for background recovery | Attempt to save partial data on next launch |

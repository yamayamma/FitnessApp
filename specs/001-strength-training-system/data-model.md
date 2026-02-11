# Data Model: Multi-Device Strength Training Management System

**Feature**: 001-strength-training-system  
**Date**: 2026-02-11  
**Schema Version**: 1.0.0

## Overview

All models conform to `Codable` and are shared across REST API parsing, WatchConnectivity transfer, and local JSON file persistence. HealthKit owns time, heart rate, and energy data — only custom strength data is modeled here.

---

## Entities

### WorkoutPlan

Represents a training routine synced from wger. Source of truth: wger backend.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `planId` | `String` | ✅ | Unique identifier from wger (`routine.id` as string) |
| `name` | `String` | ✅ | Plan display name |
| `description` | `String` | ❌ | Optional plan description |
| `days` | `[WorkoutDay]` | ✅ | Ordered list of training days |
| `lastSyncedAt` | `Date` | ✅ | Timestamp of last successful sync from wger |
| `schemaVersion` | `String` | ✅ | Schema version for migration support |

### WorkoutDay

A single training day within a plan (e.g., "Push Day", "Pull Day").

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dayId` | `String` | ✅ | Unique identifier from wger (`day.id` as string) |
| `name` | `String` | ✅ | Day display name |
| `order` | `Int` | ✅ | Display order within the plan |
| `isRest` | `Bool` | ✅ | Whether this is a rest day |
| `exercises` | `[PlannedExercise]` | ✅ | Ordered list of exercises for this day |

### PlannedExercise

An exercise within a workout day, with target parameters.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `exerciseId` | `String` | ✅ | Exercise identifier from wger |
| `exerciseName` | `String` | ✅ | Localized exercise name (cached from exerciseinfo) |
| `order` | `Int` | ✅ | Display order within the day |
| `sets` | `Int` | ✅ | Target number of sets |
| `reps` | `Int` | ✅ | Target number of reps per set |
| `weightKg` | `Double?` | ❌ | Target weight in kilograms (nil = bodyweight) |
| `restSec` | `Int` | ✅ | Rest interval in seconds between sets |

### WorkoutSessionResult

A record of a completed workout session. Stored locally as JSON file.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sessionId` | `String` (UUID) | ✅ | Unique session identifier, shared with HKWorkout metadata |
| `planId` | `String` | ✅ | Reference to the WorkoutPlan used |
| `dayId` | `String` | ✅ | Reference to the specific WorkoutDay executed |
| `performedAt` | `Date` | ✅ | Session start timestamp |
| `completedAt` | `Date` | ✅ | Session end timestamp |
| `exercises` | `[ExerciseResult]` | ✅ | Detailed per-exercise results |
| `isHealthKitSynced` | `Bool` | ✅ | Whether HKWorkout was saved successfully |
| `isWgerSynced` | `Bool` | ✅ | Whether results were posted to wger |
| `schemaVersion` | `String` | ✅ | Schema version for migration support |

### ExerciseResult

Actual performance data for one exercise in a session.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `exerciseId` | `String` | ✅ | Exercise identifier (matches PlannedExercise) |
| `exerciseName` | `String` | ✅ | Exercise name at time of execution |
| `sets` | `[SetResult]` | ✅ | Per-set performance data |

### SetResult

Actual performance data for one set.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `setNumber` | `Int` | ✅ | Set ordinal (1-based) |
| `reps` | `Int` | ✅ | Actual reps completed |
| `weightKg` | `Double` | ✅ | Actual weight used in kg (0 for bodyweight) |
| `completed` | `Bool` | ✅ | Whether the set was completed as planned |

### AuthToken

JWT token pair for wger authentication. Stored in config.json.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `accessToken` | `String` | ✅ | JWT access token (5 min expiry) |
| `refreshToken` | `String` | ✅ | JWT refresh token (1 day expiry) |
| `expiresAt` | `Date` | ✅ | Access token expiration timestamp |

### AppConfig

Application configuration. Stored in config.json.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `serverURL` | `String` | ✅ | wger instance base URL |
| `authToken` | `AuthToken?` | ❌ | Current authentication tokens |
| `lastSyncAt` | `Date?` | ❌ | Last successful full sync timestamp |

---

## Relationships

```
WorkoutPlan
 └── days: [WorkoutDay]          (1:N, ordered)
      └── exercises: [PlannedExercise]  (1:N, ordered)

WorkoutSessionResult
 └── exercises: [ExerciseResult]  (1:N, ordered)
      └── sets: [SetResult]       (1:N, ordered)

WorkoutSessionResult.planId  → WorkoutPlan.planId   (reference)
WorkoutSessionResult.dayId   → WorkoutDay.dayId     (reference)
WorkoutSessionResult.sessionId = HKWorkout.metadata["com.fitnessapp.sessionId"]  (cross-store link)
```

---

## State Transitions

### WorkoutSession States

```
[idle] → [planSelected] → [transferringToWatch] → [executing] → [saving] → [completed]
                                                        ↓
                                                   [cancelled]
```

| State | Description |
|-------|-------------|
| `idle` | No active session |
| `planSelected` | User selected a plan on iPhone |
| `transferringToWatch` | Sending plan to Watch via WCSession |
| `executing` | HKWorkoutSession active, user performing exercises |
| `saving` | Session ended, saving results locally and to HealthKit |
| `completed` | All saves successful |
| `cancelled` | Session cancelled by user before completion |

### Sync States (per session result)

```
[local] → [healthKitSynced] → [wgerSynced] → [fullySynced]
```

| State | `isHealthKitSynced` | `isWgerSynced` |
|-------|---------------------|----------------|
| `local` | false | false |
| `healthKitSynced` | true | false |
| `wgerSynced` | false | true |
| `fullySynced` | true | true |

---

## Validation Rules

- `planId`, `sessionId`, `dayId`, `exerciseId` must be non-empty strings
- `sets` in PlannedExercise must be ≥ 1
- `reps` in PlannedExercise must be ≥ 1
- `restSec` must be ≥ 0
- `weightKg` in SetResult must be ≥ 0
- `reps` in SetResult must be ≥ 0
- `performedAt` must be before `completedAt` in WorkoutSessionResult
- `schemaVersion` must follow semantic versioning format

---

## HealthKit Metadata Keys

| Key | Value | Description |
|-----|-------|-------------|
| `com.fitnessapp.sessionId` | UUID string | Links HKWorkout to WorkoutSessionResult |
| `com.fitnessapp.planId` | Plan ID string | Links HKWorkout to the originating plan |
| `com.fitnessapp.schemaVersion` | Version string | Schema version at time of creation |

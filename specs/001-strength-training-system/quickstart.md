# Quickstart: Multi-Device Strength Training Management System

**Feature**: 001-strength-training-system  
**Date**: 2026-02-11

## Prerequisites

- Xcode 15+ with iOS 17 SDK and watchOS 10 SDK
- Physical iPhone + Apple Watch pair (HealthKit requires real devices for workout sessions)
- A running wger instance (self-hosted or `https://wger.de` for testing)
- Apple Developer account (for HealthKit entitlement)

## Project Setup

The Xcode project already includes two targets:
- **FitnessApp** (iPhone) — SwiftUI app with WatchConnectivity
- **FitnessAppWatch Watch App** (watchOS) — SwiftUI app with WatchConnectivity

### Entitlements (already configured)
- Both targets have `com.apple.developer.healthkit` enabled
- WatchConnectivity is available without additional entitlements

### Info.plist Additions Required
Add to both iPhone and Watch targets:
- `NSHealthShareUsageDescription` — for reading heart rate and energy
- `NSHealthUpdateUsageDescription` — for writing workout records

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│  wger (self-hosted)                         │
│  REST API v2 + JWT auth                     │
└─────────────────┬───────────────────────────┘
                  │ HTTPS
┌─────────────────▼───────────────────────────┐
│  iPhone App (FitnessApp)                    │
│  ┌──────────┐ ┌──────────┐ ┌─────────────┐ │
│  │ API      │ │ Storage  │ │ WCSession   │ │
│  │ Service  │ │ Manager  │ │ Manager     │ │
│  └──────────┘ └──────────┘ └──────┬──────┘ │
│  ┌──────────┐ ┌──────────┐        │        │
│  │ Plan     │ │ History  │        │        │
│  │ Views    │ │ Views    │        │        │
│  └──────────┘ └──────────┘        │        │
└───────────────────────────────────┼────────┘
                                    │ WatchConnectivity
┌───────────────────────────────────▼────────┐
│  Watch App (FitnessAppWatch)               │
│  ┌──────────┐ ┌──────────┐ ┌────────────┐ │
│  │ Workout  │ │ HK       │ │ WCSession  │ │
│  │ Manager  │ │ Manager  │ │ Manager    │ │
│  └──────────┘ └──────────┘ └────────────┘ │
│  ┌──────────┐ ┌──────────┐                │
│  │ Exercise │ │ Summary  │                │
│  │ View     │ │ View     │                │
│  └──────────┘ └──────────┘                │
└────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1 — Core Watch + HealthKit MVP (v0.1)
**Goal**: Watch logs a basic strength workout to HealthKit

1. Create `WorkoutManager` on Watch:
   - `HKWorkoutSession` + `HKLiveWorkoutBuilder`
   - Activity type: `.traditionalStrengthTraining`
   - Heart rate streaming via `HKLiveWorkoutDataSource`
2. Create basic `WorkoutView` on Watch:
   - Display current exercise, set number, reps target
   - Rest timer countdown with haptic feedback
   - "Complete Set" / "End Workout" buttons
3. Save `HKWorkout` with custom metadata (`sessionId`, `planId`)
4. Verify workout appears in Apple Health app

**Test**: Start a hardcoded workout on Watch → complete sets → verify HKWorkout in Health app with correct metadata

### Phase 2 — iPhone Hub (v0.2)
**Goal**: iPhone stores plans and reads workout history

1. Define Codable model structs (`WorkoutPlan`, `WorkoutSessionResult`, etc.)
2. Implement `StorageManager` with JSON file persistence
3. Implement `WatchConnectivityManager` upgrade:
   - `sendMessageData()` for plan transfer
   - Receive `transferUserInfo()` for session results
4. Create plan list view and plan detail view on iPhone
5. Add HealthKit read capability on iPhone (query workouts by metadata)

**Test**: Send a plan from iPhone → Watch receives it → execute workout → results appear on iPhone

### Phase 3 — wger Integration (v0.3)
**Goal**: Plans sync from wger to iPhone

1. Define `WorkoutAPIProtocol` abstraction
2. Implement `WgerAPIService`:
   - JWT authentication flow
   - `GET /api/v2/routine/` + `GET /api/v2/routine/{id}/structure/`
   - `GET /api/v2/exerciseinfo/{id}/` for exercise names
3. Implement sync logic: fetch → map → store locally
4. Add server configuration UI (URL + credentials)
5. Add pull-to-refresh sync trigger

**Test**: Create plan in wger web → sync on iPhone → plan appears with correct exercises

### Phase 4 — Full Execution Pipeline (v1.0)
**Goal**: End-to-end workout flow with two-way sync

1. Convert `WorkoutPlan` → execution session payload
2. iPhone → Watch transfer with day selection
3. Watch executes full guided session with real-time HR
4. On completion: save HKWorkout + local results + transfer to iPhone
5. iPhone receives results → save locally → sync to wger (`POST /workoutsession/` + `POST /workoutlog/`)
6. Workout history view on iPhone

**Test**: Select plan from wger → start on Watch → complete workout → verify data in Health app, local storage, and wger

### Phase 5 — Web Enhancement (optional)
**Goal**: Lightweight web companion

1. Custom web UI for detailed analytics
2. CSV/JSON import/export support (Constitution Principle III)

## Running the Project

1. Open `FitnessApp.xcodeproj` in Xcode
2. Select the **FitnessApp** scheme for iPhone, or **FitnessAppWatch Watch App** scheme for Watch
3. Build and run on physical devices (Simulator lacks HealthKit workout support)
4. Grant HealthKit permissions when prompted

## Key Files to Create/Modify

| File | Target | Purpose |
|------|--------|---------|
| `Shared/Models/WorkoutPlan.swift` | Both | Codable plan model |
| `Shared/Models/WorkoutSessionResult.swift` | Both | Codable session result model |
| `Shared/Models/AppConfig.swift` | iPhone | Server configuration model |
| `FitnessApp/Services/WgerAPIService.swift` | iPhone | wger REST API client |
| `FitnessApp/Services/StorageManager.swift` | iPhone | JSON file persistence |
| `FitnessApp/Services/WatchConnectivityManager.swift` | iPhone | WCSession hub (upgrade existing) |
| `FitnessApp/Views/PlanListView.swift` | iPhone | Browse workout plans |
| `FitnessApp/Views/PlanDetailView.swift` | iPhone | View plan exercises |
| `FitnessApp/Views/HistoryView.swift` | iPhone | Workout session history |
| `FitnessApp/Views/SettingsView.swift` | iPhone | Server URL + auth config |
| `Watch/WorkoutManager.swift` | Watch | HKWorkoutSession lifecycle |
| `Watch/WatchSessionManager.swift` | Watch | WCSession handler (upgrade existing) |
| `Watch/Views/ExerciseView.swift` | Watch | Guided exercise display |
| `Watch/Views/RestTimerView.swift` | Watch | Rest countdown timer |
| `Watch/Views/SummaryView.swift` | Watch | Post-workout summary |

# Implementation Plan: Multi-Device Strength Training Management System

**Branch**: `001-strength-training-system` | **Date**: 2026-02-11 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-strength-training-system/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Build a multi-device strength training management system that syncs workout plans from a self-hosted wger REST API to an iPhone app, transfers execution sessions to an Apple Watch for guided workout tracking with HealthKit heart rate integration, and saves detailed strength data (sets, reps, weights) locally linked to HKWorkout records via shared UUID. The system uses Codable structs with JSON file persistence, WatchConnectivity for device communication, and a protocol-based API abstraction layer for backend extensibility.

## Technical Context

**Language/Version**: Swift 5.9+  
**Primary Dependencies**: SwiftUI, HealthKit, WatchConnectivity, Foundation (URLSession)  
**Storage**: Codable JSON files via FileManager (iPhone + Watch); HealthKit for health metrics  
**Testing**: XCTest (existing test targets: FitnessAppTests, FitnessAppWatch Watch AppTests)  
**Target Platform**: iOS 17+ (iPhone), watchOS 10+ (Apple Watch)  
**Project Type**: Mobile (iOS + watchOS multi-target Xcode project)  
**Performance Goals**: Plan display < 5s cached / < 10s first sync; HR updates every 5s; session save < 10s  
**Constraints**: Offline-capable workout execution; Watch operates independently during session; < 5KB WCSession payloads  
**Scale/Scope**: Single user; ~700 sessions/year; ~2MB/year local storage; 5-10 screens per target

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Pre-Design | Post-Design | Notes |
|-----------|-----------|-------------|-------|
| I. HealthKit as Source of Truth | ✅ PASS | ✅ PASS | HK owns time/HR/energy; custom metadata links via UUID; local storage only holds strength data (sets/reps/weight) |
| II. Separation of Concerns | ✅ PASS | ✅ PASS | wger=CRUD/catalog, iPhone=sync hub, Watch=execution only, Web=editing/analysis |
| III. Open Data Format | ✅ PASS | ✅ PASS | Public Codable JSON schemas versioned with `schemaVersion` field; JSON/CSV import/export in Phase 5 |
| IV. Offline First | ✅ PASS | ✅ PASS | iPhone caches plans as JSON files; Watch receives full payload before session; eventual consistency via pending queue |
| V. Extensibility | ✅ PASS | ✅ PASS | `WorkoutAPIProtocol` abstracts backend; wger is swappable; modular build targets |
| VI. Watch Simplicity | ✅ PASS | ✅ PASS | Large tap targets, no text input, no plan editing, single-purpose screens |
| VII. OSS Transparency | ✅ PASS | ✅ PASS | Schemas in data-model.md, API contracts in contracts/, architectural decisions in research.md |

**Gate Result**: ✅ ALL PASS — No violations. Proceeding without complexity justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-strength-training-system/
├── plan.md              # This file
├── research.md          # Phase 0 output — technology decisions
├── data-model.md        # Phase 1 output — entity definitions
├── quickstart.md        # Phase 1 output — setup & implementation guide
├── contracts/
│   ├── wger-api.md      # wger REST API v2 contract
│   ├── watch-connectivity.md  # WCSession message protocol
│   └── healthkit.md     # HealthKit integration contract
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
FitnessApp/                          # iPhone target (existing)
├── FitnessAppApp.swift              # App entry point (existing)
├── FitnessApp.entitlements          # HealthKit entitlement (existing)
├── Info.plist                       # (existing, needs HealthKit usage descriptions)
├── Models/                          # NEW: Shared Codable models
│   ├── WorkoutPlan.swift            # WorkoutPlan, WorkoutDay, PlannedExercise
│   ├── WorkoutSessionResult.swift   # WorkoutSessionResult, ExerciseResult, SetResult
│   └── AppConfig.swift              # AuthToken, AppConfig
├── Services/                        # NEW: Business logic layer
│   ├── WorkoutAPIProtocol.swift     # Backend abstraction protocol
│   ├── WgerAPIService.swift         # wger REST API implementation
│   ├── StorageManager.swift         # JSON file persistence
│   └── WatchConnectivityManager.swift  # Upgrade existing WCSession hub
├── Views/                           # NEW: SwiftUI views
│   ├── HomeView.swift               # Upgrade existing → plan list + navigation
│   ├── PlanDetailView.swift         # Plan exercise detail
│   ├── HistoryView.swift            # Session history list
│   ├── SessionDetailView.swift      # Single session detail
│   └── SettingsView.swift           # Server URL + auth configuration
└── Assets.xcassets/                 # (existing)

FitnessAppWatch Watch App/           # watchOS target (existing)
├── FitnessAppWatchApp.swift         # App entry point (existing)
├── FitnessAppWatch Watch App.entitlements  # (existing)
├── Models/                          # Shared models (same source files or SPM)
│   ├── WorkoutPlan.swift            # (shared with iPhone target)
│   └── WorkoutSessionResult.swift   # (shared with iPhone target)
├── Services/                        # NEW: Watch-specific services
│   ├── WorkoutManager.swift         # HKWorkoutSession + HKLiveWorkoutBuilder
│   ├── WatchSessionManager.swift    # Upgrade existing WCSession handler
│   └── LocalResultStore.swift       # Watch-side JSON file cache
├── Views/                           # NEW: Watch SwiftUI views
│   ├── WorkoutView.swift            # Upgrade existing → guided exercise flow
│   ├── ExerciseView.swift           # Single exercise display with set tracking
│   ├── RestTimerView.swift          # Rest countdown with haptic
│   └── SummaryView.swift            # Post-workout summary
└── Assets.xcassets/                 # (existing)

FitnessAppTests/                     # iPhone unit tests (existing)
├── FitnessAppTests.swift            # (existing)
├── ModelTests.swift                 # NEW: Codable encode/decode tests
├── StorageManagerTests.swift        # NEW: JSON persistence tests
├── WgerAPIServiceTests.swift        # NEW: API mapping tests with mock data
└── SyncFlowTests.swift              # NEW: End-to-end sync logic tests

FitnessAppWatch Watch AppTests/      # Watch unit tests (existing)
├── FitnessAppWatch_Watch_AppTests.swift  # (existing)
└── WorkoutManagerTests.swift        # NEW: Session lifecycle tests
```

**Structure Decision**: Mobile multi-target (Option 3). The existing Xcode project already has iPhone and watchOS targets. Shared models are added to both targets (or extracted to a local Swift Package if the project grows). Services are target-specific. The structure follows Constitution Principle II (Separation of Concerns) with clear target boundaries.

## Complexity Tracking

> No Constitution Check violations found. This section is intentionally empty.

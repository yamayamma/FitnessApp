# Tasks: Multi-Device Strength Training Management System

**Input**: Design documents from `/specs/001-strength-training-system/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Not explicitly requested — test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project directory structure and Xcode target configuration

- [ ] T001 Create Models/ directory in FitnessApp/ and add to iPhone Xcode target
- [ ] T002 Create Services/ directory in FitnessApp/ and add to iPhone Xcode target
- [ ] T003 Create Models/ directory in FitnessAppWatch Watch App/ and add to Watch Xcode target
- [ ] T004 Create Services/ directory in FitnessAppWatch Watch App/ and add to Watch Xcode target
- [ ] T005 [P] Add NSHealthShareUsageDescription and NSHealthUpdateUsageDescription to FitnessApp/Info.plist
- [ ] T006 [P] Add NSHealthShareUsageDescription and NSHealthUpdateUsageDescription to FitnessAppWatch-Watch-App-Info.plist

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared Codable models and storage infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T007 [P] Create WorkoutPlan, WorkoutDay, and PlannedExercise Codable structs in FitnessApp/Models/WorkoutPlan.swift (add to both iPhone and Watch targets)
- [ ] T008 [P] Create WorkoutSessionResult, ExerciseResult, and SetResult Codable structs in FitnessApp/Models/WorkoutSessionResult.swift (add to both iPhone and Watch targets)
- [ ] T009 Implement StorageManager with JSON file persistence (plans/, sessions/, pending/ directories) in FitnessApp/Services/StorageManager.swift
- [ ] T010 Implement LocalResultStore for Watch-side JSON session caching in FitnessAppWatch Watch App/Services/LocalResultStore.swift

**Checkpoint**: Foundation ready — shared models and storage available on both targets. User story implementation can now begin.

---

## Phase 3: User Story 4 — Sync Workout Plans from wger (Priority: P2) 🎯 MVP Foundation

**Goal**: iPhone syncs workout plans from wger REST API and stores them locally. This is placed before US1 because US1 (browsing plans) requires synced data to display.

**Independent Test**: Configure wger server URL → trigger sync → verify plans stored as JSON files in Documents/plans/

### Implementation

- [ ] T011 [P] [US4] Create AuthToken and AppConfig Codable structs in FitnessApp/Models/AppConfig.swift
- [ ] T012 [P] [US4] Define WorkoutAPIProtocol with async/await method signatures in FitnessApp/Services/WorkoutAPIProtocol.swift
- [ ] T013 [US4] Implement WgerAPIService conforming to WorkoutAPIProtocol with JWT auth (POST /api/v2/token, /token/refresh) in FitnessApp/Services/WgerAPIService.swift
- [ ] T014 [US4] Add fetchRoutines() and fetchRoutineStructure() to WgerAPIService mapping wger routine JSON to WorkoutPlan in FitnessApp/Services/WgerAPIService.swift
- [ ] T015 [US4] Add fetchExerciseInfo() to WgerAPIService for exercise name resolution in FitnessApp/Services/WgerAPIService.swift
- [ ] T016 [US4] Implement sync orchestration logic: fetch all routines → fetch structure → resolve exercise names → save to StorageManager in FitnessApp/Services/WgerAPIService.swift
- [ ] T017 [US4] Implement pagination handling for wger list endpoints (follow next links until null) in FitnessApp/Services/WgerAPIService.swift
- [ ] T018 [US4] Implement token refresh interceptor: detect 401 → refresh JWT → retry request once in FitnessApp/Services/WgerAPIService.swift
- [ ] T019 [US4] Create SettingsView with server URL input, username/password fields, and login button in FitnessApp/Views/SettingsView.swift
- [ ] T020 [US4] Add error handling for sync failures: show alert, preserve existing local cache in FitnessApp/Services/WgerAPIService.swift

**Checkpoint**: wger plans sync to local JSON storage. SettingsView allows server configuration and login.

---

## Phase 4: User Story 1 — Browse and Select Workout Plan on iPhone (Priority: P1) 🎯 MVP

**Goal**: Users see a list of synced workout plans and can tap to view exercise details

**Independent Test**: Open iPhone app → plans appear from cached data → tap a plan → exercise details visible (sets, reps, rest)

### Implementation

- [ ] T021 [US1] Refactor HomeView.swift to display a NavigationStack with plan list fetched from StorageManager in FitnessApp/Views/HomeView.swift
- [ ] T022 [US1] Add pull-to-refresh to plan list that triggers wger sync in FitnessApp/Views/HomeView.swift
- [ ] T023 [US1] Display offline indicator when plans loaded from cache and wger is unreachable in FitnessApp/Views/HomeView.swift
- [ ] T024 [US1] Display empty state with guidance when no plans are cached in FitnessApp/Views/HomeView.swift
- [ ] T025 [US1] Create PlanDetailView showing all exercises with set count, rep count, rest interval, and target weight in FitnessApp/Views/PlanDetailView.swift
- [ ] T026 [US1] Add day selector (tab or picker) to PlanDetailView for multi-day plans in FitnessApp/Views/PlanDetailView.swift
- [ ] T027 [US1] Update FitnessAppApp.swift to use HomeView as root and inject StorageManager as environment object in FitnessApp/FitnessAppApp.swift
- [ ] T028 [US1] Add navigation from plan list to PlanDetailView via NavigationLink in FitnessApp/Views/HomeView.swift

**Checkpoint**: Users can browse cached plans, pull-to-refresh from wger, view plan details with exercises. Works offline with cached data.

---

## Phase 5: User Story 5 — Transfer Workout Session to Apple Watch (Priority: P2)

**Goal**: User selects a plan/day on iPhone and sends it to the Watch, which confirms readiness

**Independent Test**: Select a plan on iPhone → tap "Start on Watch" → Watch displays plan name and exercise count

### Implementation

- [ ] T029 [US5] Add "Start Workout on Watch" button to PlanDetailView with day selection in FitnessApp/Views/PlanDetailView.swift
- [ ] T030 [US5] Upgrade WatchConnectivityManager to send WorkoutPlan as Codable JSON via sendMessageData() in FitnessApp/Services/WatchConnectivityManager.swift
- [ ] T031 [US5] Add message type routing (startWorkout, sessionResult, planListUpdate) to WatchConnectivityManager in FitnessApp/Services/WatchConnectivityManager.swift
- [ ] T032 [US5] Add reachability check before send: show "Watch not connected" alert if isReachable is false in FitnessApp/Services/WatchConnectivityManager.swift
- [ ] T033 [US5] Upgrade WatchSessionManager to receive startWorkout message and decode WorkoutPlan from JSON in FitnessAppWatch Watch App/Services/WatchSessionManager.swift
- [ ] T034 [US5] Add reply handler in WatchSessionManager sending startWorkoutAck with ready/error status in FitnessAppWatch Watch App/Services/WatchSessionManager.swift
- [ ] T035 [US5] Update WatchConnectivityManager to receive sessionResult via didReceiveUserInfo and save to StorageManager in FitnessApp/Services/WatchConnectivityManager.swift

**Checkpoint**: iPhone sends plan to Watch, Watch receives and acknowledges. Session results transfer back to iPhone after workout.

---

## Phase 6: User Story 2 — Execute Workout Session on Apple Watch (Priority: P1)

**Goal**: Watch guides user through exercises with set tracking, rest timer, heart rate display, and haptic feedback

**Independent Test**: Receive plan on Watch → start session → navigate exercises/sets with rest timer → see HR → end session with summary

### Implementation

- [ ] T036 [US2] Create WorkoutManager with HKWorkoutSession + HKLiveWorkoutBuilder lifecycle in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T037 [US2] Implement HealthKit authorization request (workout write, heartRate and activeEnergy read) in WorkoutManager in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T038 [US2] Implement HKLiveWorkoutDataSource setup for automatic HR and energy collection in WorkoutManager in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T039 [US2] Implement HKLiveWorkoutBuilderDelegate to publish real-time heart rate to UI in WorkoutManager in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T040 [US2] Add session metadata (com.fitnessapp.sessionId, planId, schemaVersion) via builder.addMetadata() in WorkoutManager in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T041 [US2] Implement exercise/set progression state machine tracking current exercise index, set index, and session state in WorkoutManager in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T042 [US2] Implement rest timer countdown with WKInterfaceDevice.current().play(.notification) haptic on completion in WorkoutManager in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T043 [US2] Allow user to modify actual reps and weight for each set via Digital Crown or +/- buttons in WorkoutManager in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T044 [US2] Refactor WorkoutView.swift as the main guided exercise screen showing current exercise, set, target reps, weight, and heart rate in FitnessAppWatch Watch App/Views/WorkoutView.swift
- [ ] T045 [P] [US2] Create ExerciseView as a sub-view showing exercise name, set progress (e.g., "Set 2/4"), and target reps in FitnessAppWatch Watch App/Views/ExerciseView.swift
- [ ] T046 [P] [US2] Create RestTimerView showing countdown seconds, next exercise preview, and cancel button in FitnessAppWatch Watch App/Views/RestTimerView.swift
- [ ] T047 [US2] Create SummaryView showing total duration, exercises completed, total sets, and average heart rate in FitnessAppWatch Watch App/Views/SummaryView.swift
- [ ] T048 [US2] Update FitnessAppWatchApp.swift to route between idle state and WorkoutView based on received plan in FitnessAppWatch Watch App/FitnessAppWatchApp.swift

**Checkpoint**: Watch executes a full guided strength training session with HR tracking, rest timers, haptic alerts, and session summary.

---

## Phase 7: User Story 3 — Save Workout Results and Health Data (Priority: P1)

**Goal**: On session end, save HKWorkout to HealthKit and detailed strength data to local storage, linked by shared UUID

**Independent Test**: Complete a session on Watch → verify HKWorkout in Apple Health with sessionId metadata → verify session JSON in local storage with matching UUID

### Implementation

- [ ] T049 [US3] Implement finishWorkout flow in WorkoutManager: stopActivity → endCollection → finishWorkout → session.end() in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T050 [US3] Build WorkoutSessionResult from collected exercise/set data in WorkoutManager upon session end in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T051 [US3] Save WorkoutSessionResult to LocalResultStore as JSON before HKWorkout finalization in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T052 [US3] Handle HealthKit save failure: set isHealthKitSynced=false, show notification, keep local data in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T053 [US3] Transfer WorkoutSessionResult to iPhone via WCSession.transferUserInfo() after save in FitnessAppWatch Watch App/Services/WatchSessionManager.swift
- [ ] T054 [US3] On iPhone: receive session result, save to StorageManager sessions/ directory in FitnessApp/Services/WatchConnectivityManager.swift
- [ ] T055 [US3] On iPhone: update sessions/index.json with new session metadata (sessionId, planId, performedAt) in FitnessApp/Services/StorageManager.swift
- [ ] T056 [US3] Implement pending sync queue: save sessions with isWgerSynced=false to pending/ directory for later wger upload in FitnessApp/Services/StorageManager.swift
- [ ] T057 [US3] Add wger result sync: POST /workoutsession/ and POST /workoutlog/ for each set in pending sessions in FitnessApp/Services/WgerAPIService.swift

**Checkpoint**: Session results saved to HealthKit + local JSON + transferred to iPhone + synced to wger. UUID links all records.

---

## Phase 8: User Story 6 — View Workout History (Priority: P3)

**Goal**: Users review past sessions on iPhone with complete exercise/set/weight/HR details

**Independent Test**: Complete multiple sessions → open history → sessions listed by date → tap session → full detail visible

### Implementation

- [ ] T058 [US6] Create HistoryView listing past sessions from StorageManager sessions/index.json in reverse chronological order in FitnessApp/Views/HistoryView.swift
- [ ] T059 [US6] Display session summary in list row: date, plan name, exercise count, duration in FitnessApp/Views/HistoryView.swift
- [ ] T060 [US6] Display empty state when no sessions exist with guidance to start a workout in FitnessApp/Views/HistoryView.swift
- [ ] T061 [US6] Create SessionDetailView showing all exercises with per-set reps, weight, and completion status in FitnessApp/Views/SessionDetailView.swift
- [ ] T062 [US6] Query HealthKit for matching HKWorkout by sessionId metadata and display duration and average heart rate in SessionDetailView in FitnessApp/Views/SessionDetailView.swift
- [ ] T063 [US6] Add History tab to HomeView navigation (TabView or sidebar) in FitnessApp/Views/HomeView.swift
- [ ] T064 [US6] Add navigation from history list to SessionDetailView via NavigationLink in FitnessApp/Views/HistoryView.swift

**Checkpoint**: Users can browse full workout history with all details including HealthKit-sourced heart rate data.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T065 [P] Add app icon assets to FitnessApp/Assets.xcassets/AppIcon.appiconset/ and FitnessAppWatch Watch App/Assets.xcassets/AppIcon.appiconset/
- [ ] T066 [P] Add AccentColor configuration in FitnessApp/Assets.xcassets/AccentColor.colorset/
- [ ] T067 Handle Watch connectivity loss mid-session: continue session independently, queue result transfer in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T068 Implement session recovery on Watch app relaunch after force-quit: check for unsaved session data in FitnessAppWatch Watch App/Services/WorkoutManager.swift
- [ ] T069 Add background pending sync retry: on app launch check pending/ directory and attempt wger upload in FitnessApp/Services/WgerAPIService.swift
- [ ] T070 Add updateApplicationContext for plan list metadata push to Watch after sync in FitnessApp/Services/WatchConnectivityManager.swift
- [ ] T071 Run quickstart.md validation: verify all documented files exist and architecture matches plan

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **US4 Sync (Phase 3)**: Depends on Foundational — provides data for US1
- **US1 Browse (Phase 4)**: Depends on US4 (needs synced plans to display)
- **US5 Transfer (Phase 5)**: Depends on Foundational + US1 (needs PlanDetailView)
- **US2 Execute (Phase 6)**: Depends on US5 (needs plan on Watch) + Foundational
- **US3 Save (Phase 7)**: Depends on US2 (needs active session to save)
- **US6 History (Phase 8)**: Depends on Foundational + US3 (needs saved sessions)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational: models + storage)
    ↓
Phase 3 (US4: wger sync) ← provides plan data
    ↓
Phase 4 (US1: browse plans) ← displays synced data
    ↓
Phase 5 (US5: transfer to Watch) ← sends selected plan
    ↓
Phase 6 (US2: execute on Watch) ← runs transferred plan
    ↓
Phase 7 (US3: save results) ← persists session data
    ↓
Phase 8 (US6: view history) ← reads saved sessions
    ↓
Phase 9 (Polish)
```

### Within Each User Story

- Models before services
- Services before views
- Core implementation before error handling/edge cases
- Story complete before moving to next priority

### Parallel Opportunities

Within Phase 2 (Foundational):
- T007 (WorkoutPlan model) and T008 (WorkoutSessionResult model) can run in parallel [P]

Within Phase 3 (US4):
- T011 (AppConfig) and T012 (WorkoutAPIProtocol) can run in parallel [P]

Within Phase 6 (US2):
- T045 (ExerciseView) and T046 (RestTimerView) can run in parallel [P]

Within Phase 9 (Polish):
- T065 (app icon) and T066 (AccentColor) can run in parallel [P]

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch models in parallel:
Task T007: "Create WorkoutPlan structs in FitnessApp/Models/WorkoutPlan.swift"
Task T008: "Create WorkoutSessionResult structs in FitnessApp/Models/WorkoutSessionResult.swift"

# Then sequentially (depends on models):
Task T009: "Implement StorageManager in FitnessApp/Services/StorageManager.swift"
Task T010: "Implement LocalResultStore in FitnessAppWatch Watch App/Services/LocalResultStore.swift"
```

## Parallel Example: Phase 6 (US2 — Watch Execution)

```bash
# Sequential: WorkoutManager core (T036-T043)
# Then parallel views:
Task T045: "Create ExerciseView in FitnessAppWatch Watch App/Views/ExerciseView.swift"
Task T046: "Create RestTimerView in FitnessAppWatch Watch App/Views/RestTimerView.swift"

# Then sequential integration:
Task T044: "Refactor WorkoutView as main guided screen"
Task T047: "Create SummaryView"
Task T048: "Update FitnessAppWatchApp routing"
```

---

## Implementation Strategy

### MVP First (US4 → US1 → US5 → US2 → US3)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (models + storage)
3. Complete Phase 3: US4 (wger sync) — plans available locally
4. Complete Phase 4: US1 (browse plans) — **first demo: "I can see my plans on iPhone"**
5. Complete Phase 5: US5 (transfer to Watch) — bridge established
6. Complete Phase 6: US2 (execute on Watch) — **core demo: "guided workout on wrist"**
7. Complete Phase 7: US3 (save results) — **MVP complete: "full workout recorded"**
8. **STOP and VALIDATE**: End-to-end flow from wger → iPhone → Watch → HealthKit → local storage

### Incremental Delivery

1. Setup + Foundational → Infrastructure ready
2. Add US4 + US1 → iPhone can browse wger plans (v0.3)
3. Add US5 → Plans reach the Watch (v0.3+)
4. Add US2 + US3 → Watch executes and saves workouts (v1.0)
5. Add US6 → History view for progress tracking (v1.1)
6. Each phase adds value without breaking previous phases

### Deliverable Milestones

| Version | Content | Phases |
|---------|---------|--------|
| v0.1 | Watch logs hardcoded workout to HealthKit | Phase 1-2 + minimal US2/US3 |
| v0.2 | iPhone sync + local storage | Phase 3 (US4) |
| v0.3 | Plan browsing on iPhone | Phase 4 (US1) |
| v1.0 | Full execution pipeline | Phase 5-7 (US5 + US2 + US3) |
| v1.1 | Workout history | Phase 8 (US6) |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable, though this feature has a natural pipeline dependency (sync → browse → transfer → execute → save)
- Tests not generated (not requested in spec) — add via `/speckit.tasks` with TDD flag if needed
- Commit after each task or logical group
- Stop at any checkpoint to validate the current story independently
- All models are Codable and shared between targets — changes to model files affect both iPhone and Watch

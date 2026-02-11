# Feature Specification: Multi-Device Strength Training Management System

**Feature Branch**: `001-strength-training-system`  
**Created**: 2026-02-11  
**Status**: Draft  
**Input**: User description: "Multi-device strength training management system with Web, iPhone, and Apple Watch support, backed by wger REST API"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse and Select Workout Plan on iPhone (Priority: P1)

A user opens the iPhone app and sees a list of workout plans that have been created in the wger web interface. The user selects a plan to view its details — exercises, sets, reps, and rest intervals — and chooses a plan to start a workout session.

**Why this priority**: This is the foundational flow. Without the ability to browse and select plans synced from wger, no other features (execution, saving) can function. It delivers immediate value by letting users access their pre-configured training plans on mobile.

**Independent Test**: Can be fully tested by opening the iPhone app, verifying plans appear from wger, tapping a plan, and confirming exercise details are displayed correctly.

**Acceptance Scenarios**:

1. **Given** the user has workout plans configured in wger, **When** the user opens the iPhone app, **Then** all available workout plans are displayed with their names.
2. **Given** the user is viewing the plan list, **When** the user taps a specific plan, **Then** the app displays all exercises in the plan including set count, rep count, and rest intervals.
3. **Given** the wger server is unreachable, **When** the user opens the iPhone app, **Then** the app shows the most recently cached plans with an indicator that data may be outdated.
4. **Given** the user has no plans configured in wger, **When** the user opens the iPhone app, **Then** the app displays a helpful empty state directing the user to create plans via the web interface.

---

### User Story 2 - Execute Workout Session on Apple Watch (Priority: P1)

A user initiates a workout session from the iPhone (or directly on the Watch). The Apple Watch guides the user through each exercise in the plan — displaying the current exercise, set number, target reps, and rest timer between sets. Heart rate is tracked continuously via HealthKit throughout the session.

**Why this priority**: The Watch-based guided workout is the core value proposition of the system, providing hands-free, real-time training guidance during exercise. This is the primary differentiator and must work reliably.

**Independent Test**: Can be tested by starting a workout session on the Watch, verifying each exercise and set is presented in order, confirming the rest timer counts down correctly, and verifying heart rate data is being collected.

**Acceptance Scenarios**:

1. **Given** a workout plan has been sent to the Watch, **When** the user starts the session, **Then** the Watch displays the first exercise with set number, target reps, and target weight (if specified).
2. **Given** the user is performing an exercise, **When** the user completes a set and confirms it, **Then** the Watch starts a rest countdown timer using the plan's configured rest interval.
3. **Given** the rest timer is counting down, **When** the timer reaches zero, **Then** the Watch alerts the user (haptic feedback) and displays the next set or next exercise.
4. **Given** a workout session is active, **When** the user checks the display at any time, **Then** the current heart rate is visible on screen.
5. **Given** the user is on the last set of the last exercise, **When** the user completes it, **Then** the Watch presents a session summary with total duration, exercises completed, and average heart rate.
6. **Given** a session is in progress, **When** the user modifies the actual reps or weight performed for a set, **Then** the modified values are recorded instead of the plan defaults.

---

### User Story 3 - Save Workout Results and Health Data (Priority: P1)

When the user ends a workout session, the system saves the workout data in two ways: a HealthKit workout record (HKWorkout) for Apple Health integration, and detailed strength training data (sets, reps, weights per exercise) to local storage. Both records are linked by a shared session UUID so they can be correlated later.

**Why this priority**: Without reliable data persistence, workout tracking has no lasting value. Saving to HealthKit ensures the workout appears in Apple Health and integrates with the broader health ecosystem. Saving detailed strength data enables progressive overload tracking.

**Independent Test**: Can be tested by completing a workout session, then verifying that an HKWorkout appears in Apple Health with the correct metadata, and that detailed set/rep/weight data is retrievable from local storage with the matching session UUID.

**Acceptance Scenarios**:

1. **Given** the user finishes a workout session, **When** the session is saved, **Then** an HKWorkout record is created in HealthKit with the session duration, calories (if available), and heart rate samples.
2. **Given** the user finishes a workout session, **When** the session is saved, **Then** the HKWorkout metadata includes the sessionId and planId for cross-referencing.
3. **Given** the user finishes a workout session, **When** the session is saved, **Then** detailed strength data (exercise ID, sets with reps and weight per set) is saved to local storage.
4. **Given** both records have been saved, **When** the data is queried by sessionId, **Then** the HealthKit workout and the local strength data can be matched via the shared UUID.
5. **Given** a session save fails (e.g., HealthKit permission denied), **When** the error occurs, **Then** the user is notified and the strength data is still saved locally with a flag indicating HealthKit sync is pending.

---

### User Story 4 - Sync Workout Plans from wger to iPhone (Priority: P2)

The system periodically and on-demand syncs workout plans from the self-hosted wger instance via its REST API. Plans are fetched, validated, and converted into an internal execution format suitable for use on the iPhone and Apple Watch.

**Why this priority**: While plan browsing (Story 1) depends on this, the sync mechanism itself can be refined independently. A basic manual sync is sufficient for MVP; automatic/periodic sync adds convenience.

**Independent Test**: Can be tested by creating or modifying a plan in the wger web interface, triggering a sync on the iPhone, and verifying the updated plan data appears correctly in the app.

**Acceptance Scenarios**:

1. **Given** the user has configured the wger server URL and credentials, **When** the user triggers a manual sync (pull-to-refresh), **Then** all plans are fetched from the wger REST API and stored locally.
2. **Given** a plan has been updated in wger (e.g., an exercise was added), **When** the next sync occurs, **Then** the local plan reflects the changes.
3. **Given** the wger server returns an error, **When** the sync fails, **Then** the user sees a clear error message and existing local data is preserved.
4. **Given** the sync completes successfully, **When** the user views a plan, **Then** the plan data matches what is configured in wger, including exercise names, set counts, rep targets, and rest intervals.

---

### User Story 5 - Transfer Workout Session to Apple Watch (Priority: P2)

The user selects a workout plan on the iPhone and sends it to the Apple Watch to begin a workout session. The Watch receives the execution session data and is ready for the user to start exercising.

**Why this priority**: This bridges the iPhone planning experience with the Watch execution experience. It must work reliably but is secondary to the core plan viewing and workout execution stories.

**Independent Test**: Can be tested by selecting a plan on the iPhone, tapping "Start on Watch," and verifying the Watch receives and displays the correct plan details ready for execution.

**Acceptance Scenarios**:

1. **Given** the user has selected a plan on the iPhone, **When** the user initiates the workout session, **Then** the plan data is transferred to the paired Apple Watch.
2. **Given** the Watch is not reachable (out of range or off), **When** the user attempts to send a session, **Then** the iPhone displays an error indicating the Watch is unavailable.
3. **Given** the plan data has been sent, **When** the Watch receives it, **Then** the Watch displays a confirmation with the plan name and exercise count, ready to start.

---

### User Story 6 - View Workout History (Priority: P3)

A user can review past workout sessions on the iPhone, including the date, plan used, exercises performed, sets/reps/weights, session duration, and heart rate summary. This enables the user to track progress over time.

**Why this priority**: Workout history is essential for long-term value but is not required for the initial workout capture flow. Users can derive some value from HealthKit integration in the short term.

**Independent Test**: Can be tested by completing several workout sessions, opening the history view, and verifying that past sessions are listed with accurate and complete data.

**Acceptance Scenarios**:

1. **Given** the user has completed previous workout sessions, **When** the user opens the history view, **Then** past sessions are listed in reverse chronological order.
2. **Given** the user is viewing the history list, **When** the user taps a specific session, **Then** the detail view shows all exercises, sets with reps and weights, duration, and average heart rate.
3. **Given** no workout sessions have been recorded, **When** the user opens the history view, **Then** the app shows an empty state with guidance on how to start a workout.

---

### Edge Cases

- What happens when the Watch loses connection to the iPhone mid-session? The Watch should continue tracking the workout independently and sync results when connectivity is restored.
- What happens when HealthKit authorization is not granted? The system should still function for workout tracking, saving strength data locally, and clearly inform the user that health data integration is unavailable.
- What happens when a workout plan is deleted in wger while a session is in progress? The in-progress session should complete normally using the locally cached plan data. The plan should be removed on the next sync.
- What happens when the user force-quits the Watch app during a session? The system should attempt to save any recorded data up to that point and allow recovery on next launch.
- What happens when the local storage is full? The system should notify the user and suggest actions such as exporting or clearing old data.
- What happens when there are conflicting plan updates (edited locally and on wger)? Since wger is the source of truth for plans, the wger version should always take precedence on sync.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST sync workout plans from a self-hosted wger instance via REST API and store them locally on the iPhone.
- **FR-002**: System MUST convert wger workout plan data into an internal execution format containing exercise ID, set count, rep count, and rest interval per exercise.
- **FR-003**: System MUST display a list of available workout plans on the iPhone with plan name and exercise summary.
- **FR-004**: System MUST transfer a selected workout plan from the iPhone to the Apple Watch for session execution.
- **FR-005**: System MUST guide the user through a workout session on the Apple Watch, presenting exercises in order with set number, target reps, and rest timer.
- **FR-006**: System MUST allow the user to record actual reps and weight performed for each set during a Watch session.
- **FR-007**: System MUST stream and display real-time heart rate data from HealthKit during an active workout session on the Watch.
- **FR-008**: System MUST save an HKWorkout record to HealthKit upon session completion, including duration and heart rate samples.
- **FR-009**: System MUST embed sessionId and planId as metadata in the HKWorkout record for cross-referencing.
- **FR-010**: System MUST save detailed strength training results (exercise ID, sets with reps and weight) to local storage upon session completion.
- **FR-011**: System MUST link the HealthKit workout and local strength data via a shared UUID (sessionId).
- **FR-012**: System MUST cache the most recent workout plans locally to allow offline access when the wger server is unreachable.
- **FR-013**: System MUST provide haptic feedback on the Apple Watch when a rest timer completes.
- **FR-014**: System MUST display a session summary on the Watch upon workout completion, including total duration, exercises completed, and average heart rate.
- **FR-015**: System MUST handle HealthKit authorization denial gracefully, saving strength data locally and notifying the user about limited health integration.
- **FR-016**: System MUST maintain workout session integrity on the Watch even if connectivity to the iPhone is lost mid-session.
- **FR-017**: System MUST display workout history on the iPhone in reverse chronological order with session details.
- **FR-018**: System MUST allow the user to configure the wger server URL and authentication credentials.

### Key Entities

- **WorkoutPlan**: A training plan created in wger, containing a unique plan ID, name, and an ordered list of exercises. Each exercise specifies set count, rep target, and rest interval. Plans are the source of truth in wger and are synced to the iPhone.
- **WorkoutSessionResult**: A record of a completed workout session, containing a unique session ID, the associated plan ID, timestamp, and detailed per-exercise results with actual reps and weight for each set. Stored locally on the device.
- **HKWorkout**: An Apple HealthKit workout record representing one completed session. Linked to the WorkoutSessionResult via sessionId and planId stored in metadata. Contains duration, energy burned, and heart rate samples.
- **Exercise**: An individual exercise within a plan, identified by exercise ID. Contains target parameters (sets, reps, rest) from the plan and actual performance data (reps, weight) from the session.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view their wger workout plans on the iPhone within 5 seconds of opening the app (with cached data) or within 10 seconds (on first sync).
- **SC-002**: Users can start a workout session on the Apple Watch within 30 seconds of selecting a plan on the iPhone.
- **SC-003**: The rest timer between sets is accurate to within 1 second of the configured interval.
- **SC-004**: Heart rate updates are displayed on the Watch at least once every 5 seconds during an active session.
- **SC-005**: Workout results (both HealthKit and local strength data) are saved within 10 seconds of ending a session.
- **SC-006**: 100% of completed sessions have a matching HKWorkout and local strength record linked by the same sessionId (when HealthKit is authorized).
- **SC-007**: Users can complete a full workout session on the Watch without needing to interact with the iPhone after the session is initiated.
- **SC-008**: The system retains full functionality for workout tracking and data recording even when HealthKit authorization is denied, with only health metrics unavailable.
- **SC-009**: Cached workout plans remain accessible and usable for session execution when the wger server is offline.
- **SC-010**: Users can review past workout sessions and see complete details (exercises, sets, reps, weights, duration, heart rate) within 3 seconds of opening the history view.

## Assumptions

- **A-001**: The wger instance is self-hosted and accessible via HTTPS from the user's network. Standard REST API authentication (token-based) is used.
- **A-002**: The user owns an iPhone and Apple Watch pair with watchOS capable of running SwiftUI apps and accessing HealthKit.
- **A-003**: Workout plans are created and maintained exclusively in the wger web interface. The iPhone and Watch apps are consumers of plan data, not editors.
- **A-004**: One workout session corresponds to exactly one workout plan execution. Partial plan executions (skipping exercises) are allowed but tracked.
- **A-005**: Weight is recorded in kilograms as the primary unit, consistent with the wger data model.
- **A-006**: The system targets a single user per device. Multi-user support is out of scope.
- **A-007**: Internet connectivity is required for initial plan sync but not for workout execution or data recording.
- **A-008**: Data retention follows the device's local storage lifecycle. No cloud backup of strength data is in scope (HealthKit handles its own backup via iCloud).

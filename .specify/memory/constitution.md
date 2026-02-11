# FitnessApp Constitution

## Core Principles

### I. HealthKit as Source of Truth

- All workout sessions MUST be saved to HealthKit via
  `HKWorkoutSession` and `HKWorkoutBuilder`.
- HealthKit owns time, active/basal energy, heart rate, and
  session metadata. The application MUST NOT duplicate these
  fields in its own persistence layer.
- Custom strength data (sets, reps, weight, RPE) MUST be linked
  to the corresponding `HKWorkout` via a shared UUID stored in
  workout metadata.
- Deleting a workout from HealthKit MUST cascade to orphaned
  custom strength records on next sync.

**Rationale**: A single canonical store eliminates data drift
between platforms and gives users one place to audit their data.

### II. Separation of Concerns

- **Backend (wger)**: Manages workout plan CRUD, exercise
  catalogue, and long-term analytics. MUST expose a REST/JSON
  API consumed by the iPhone app.
- **iPhone**: Acts as the synchronization hub. MUST mediate all
  data flow between backend, Watch, and HealthKit.
- **Apple Watch**: Handles workout execution only. MUST NOT
  perform plan editing, analytics, or direct backend calls.
- **Web**: Handles heavy editing (program design, bulk import)
  and detailed analysis/reporting.

**Rationale**: Strict role boundaries prevent feature creep on
constrained devices and keep each target focused.

### III. Open Data Format

- Workout plan and result schemas MUST be public JSON documents
  versioned alongside the source code.
- Import and export MUST be supported in both JSON and CSV
  formats.
- AI-generated workout plans MUST conform to the same schema so
  they are interchangeable with manually created plans.
- Schema changes MUST follow semantic versioning and include
  migration notes.

**Rationale**: Open, documented formats prevent vendor lock-in
and enable community tooling and integrations.

### IV. Offline First

- The iPhone app MUST cache the active workout plan and exercise
  catalogue locally (Core Data or SwiftData) so users can train
  without network access.
- The Apple Watch MUST receive the workout payload before a
  session begins and MUST execute the full session without a live
  backend or iPhone dependency.
- Sync MUST be eventual-consistency-based: local changes queue
  and reconcile when connectivity is restored.

**Rationale**: Gym environments have unreliable connectivity;
training MUST never be blocked by network status.

### V. Extensibility

- The system MUST NOT depend on proprietary, non-replaceable
  services. Every external dependency MUST have a documented
  interface boundary.
- Architecture MUST be modular: backend, sync layer, and UI
  targets are separate build targets with explicit dependency
  declarations.
- The backend MUST be swappable — all backend interactions go
  through an abstraction layer (protocol/interface) so a future
  replacement requires no UI-layer changes.

**Rationale**: Long-term viability of an open-source project
depends on avoiding single points of vendor failure.

### VI. Watch Simplicity

- Watch UI MUST prioritize minimal interaction: large tap
  targets, single-purpose screens, no text input.
- Editing of plans, exercises, or settings MUST NOT be available
  on the Watch. All configuration happens on iPhone or Web.
- Watch complications and notifications MUST surface only
  actionable, glanceable data (next set, rest timer).

**Rationale**: The Watch's small screen and workout context
demand distraction-free, glove-friendly interaction.

### VII. OSS Transparency

- All data schemas, API contracts, and architectural decisions
  MUST be documented in the repository.
- Repository structure MUST follow a clear, discoverable layout
  with a top-level README explaining each target and directory.
- Contribution guidelines, licensing (open-source), and a code
  of conduct MUST be present at the repository root.

**Rationale**: Transparency lowers the barrier to contribution
and builds trust with the user community.

## Architecture Overview

- **Platforms**: Web (browser), iOS (iPhone), watchOS
  (Apple Watch).
- **Backend**: wger (Django/DRF) — self-hosted or cloud.
- **Languages**: Swift (iOS/watchOS), TypeScript or Python (Web),
  Python (backend/wger).
- **Health Integration**: HealthKit (iOS/watchOS).
- **Watch ↔ iPhone**: WatchConnectivity framework
  (`WCSession`).
- **Data Persistence**: Core Data / SwiftData (iPhone),
  `UserDefaults` or lightweight cache (Watch), PostgreSQL
  (backend).
- **Sync Model**: iPhone-centric hub; backend ↔ iPhone ↔ Watch.

## Development Workflow

- All PRs and code reviews MUST verify compliance with the
  principles defined in this constitution.
- New features MUST begin with a specification
  (`/specs/<feature>/spec.md`) before implementation.
- Tests MUST accompany every feature that touches data
  persistence, sync, or HealthKit integration.
- Commit messages MUST follow Conventional Commits
  (`feat:`, `fix:`, `docs:`, `chore:`, etc.).
- CI MUST run linting, unit tests, and schema validation on
  every push.

## Governance

This constitution is the highest-authority document for the
FitnessApp project. All architectural decisions, code reviews,
and feature proposals MUST be evaluated against these principles.

**Amendment Procedure**:

1. Propose a change via a pull request modifying this file.
2. The PR description MUST state the affected principle(s),
   rationale, and migration impact.
3. At least one maintainer MUST approve the amendment.
4. Upon merge, `CONSTITUTION_VERSION` MUST be incremented per
   semantic versioning (see below) and `LAST_AMENDED_DATE`
   updated.

**Versioning Policy**:

- **MAJOR**: Removal or incompatible redefinition of a principle.
- **MINOR**: New principle added or material expansion of
  existing guidance.
- **PATCH**: Wording clarifications, typo fixes, non-semantic
  refinements.

**Compliance Review**:

- Every PR MUST include a self-check against the constitution.
- Quarterly reviews SHOULD audit the codebase for principle
  drift.

**Version**: 1.0.0 | **Ratified**: 2026-02-11 | **Last Amended**: 2026-02-11

# Tasks: 筋力トレーニング記録システム

**Input**: Design documents from `/specs/001-strength-training-system/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: テストタスクは明示的に要求されていないため含めない。テスト戦略は quickstart.md を参照。

**Organization**: タスクはユーザーストーリーごとにグループ化し、各ストーリーの独立した実装・テストを可能にする。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能（異なるファイル、依存関係なし）
- **[Story]**: 対応するユーザーストーリー（US1, US2, US3, US4）
- ファイルパスはリポジトリルート（`FitnessApp/` ワークスペース）からの相対パス

## Path Conventions

- **iOS target**: `FitnessApp/` 配下
- **watchOS target**: `FitnessAppWatch Watch App/` 配下
- **Shared models**: `FitnessApp/Models/` に配置し Target Membership で共有

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: プロジェクトディレクトリ構成の確立と基本設定

- [x] T001 Create project directory structure: `FitnessApp/Models/`, `FitnessApp/ViewModels/`, `FitnessApp/Views/`, `FitnessApp/Services/`, `FitnessAppWatch Watch App/ViewModels/`, `FitnessAppWatch Watch App/Views/`, `FitnessAppWatch Watch App/Services/`
- [x] T002 [P] Add HealthKit Privacy Descriptions to FitnessAppWatch-Watch-App-Info.plist: `NSHealthUpdateUsageDescription` = "This app records your strength training workouts to Apple Health." / `NSHealthShareUsageDescription` = "This app reads your heart rate during workouts to display real-time data." (FR-023)
- [x] T003 [P] Add `workout-processing` to `WKBackgroundModes` array in FitnessAppWatch-Watch-App-Info.plist (research.md §R5)
- [x] T004 Configure SwiftData modelContainer in FitnessApp/FitnessAppApp.swift (TrainingMenu, Exercise, WorkoutSession, ExerciseResult, SetResult) and FitnessAppWatch Watch App/FitnessAppWatchApp.swift (WorkoutSession, ExerciseResult, SetResult, HealthKitRetryItem) ※HealthKitRetryItem は T012 (Phase 2) で作成済み

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 全ユーザーストーリーが依存する SwiftData モデルと Transfer モデルの作成

**⚠️ CRITICAL**: このフェーズ完了まで、いかなるユーザーストーリーも実装開始不可

- [x] T005 [P] Create WorkoutStatus enum (active/paused/completed/cancelled, String rawValue, Codable) in FitnessApp/Models/WorkoutStatus.swift
- [x] T006 [P] Create WorkoutSession SwiftData model with sessionId @Attribute(.unique), status, startDate, endDate?, menuId?, menuName?, totalDuration, createdAt, and @Relationship(.cascade) to ExerciseResult in FitnessApp/Models/WorkoutSession.swift
- [x] T007 [P] Create ExerciseResult SwiftData model with exerciseId (UUID value copy), exerciseName, sortOrder, inverse relationship to WorkoutSession, and @Relationship(.cascade) to SetResult in FitnessApp/Models/ExerciseResult.swift
- [x] T008 [P] Create SetResult SwiftData model with setNumber, weight (Double, kg), reps, completedAt, and inverse relationship to ExerciseResult in FitnessApp/Models/SetResult.swift
- [x] T009 [P] Create TrainingMenu SwiftData model with menuId, name, createdAt, updatedAt, and @Relationship(.cascade) to Exercise in FitnessApp/Models/TrainingMenu.swift
- [x] T010 [P] Create Exercise SwiftData model with exerciseId, name, defaultSets, defaultWeight, defaultReps, sortOrder, and inverse relationship to TrainingMenu in FitnessApp/Models/Exercise.swift
- [x] T011 [P] Create Codable Transfer structs (MenuTransfer, ExerciseTransfer, WorkoutResultTransfer, ExerciseResultTransfer, SetResultTransfer) with ISO 8601 date encoding (NFR-007) in FitnessApp/Models/TransferModels.swift. ExerciseResultTransfer には sortOrder フィールドを含める（種目順序の Watch→iPhone 転送保証）
- [x] T012 [P] Create HealthKitRetryItem SwiftData model (sessionId, workoutData: Data, attemptCount, lastAttemptDate, status: RetryStatus enum) in FitnessApp/Models/HealthKitRetryItem.swift with watchOS Target Membership only (FR-015)
- [x] T013 Configure Xcode Target Membership: WorkoutStatus, WorkoutSession, ExerciseResult, SetResult, TransferModels → both iOS and watchOS targets; TrainingMenu, Exercise → iOS target only; HealthKitRetryItem → watchOS target only

**Checkpoint**: 基盤モデル完了 — ユーザーストーリー実装を開始可能

---

## Phase 3: User Story 1 - ワークアウト実行（Apple Watch） (Priority: P1) 🎯 MVP

**Goal**: Apple Watch 単体でワークアウトを開始し、セットを記録し、HealthKit に保存する。アプリの中核価値。

**Independent Test**: Apple Watch シミュレータでワークアウトを開始→セット進行（次セットボタンタップ）→完了し、HealthKit にデータが保存されることを確認。クラッシュリカバリ・キャンセル・一時停止も検証可能。

### Implementation for User Story 1

- [x] T014 [US1] Create WatchHealthKitManager with HKHealthStore authorization flow (isHealthDataAvailable check, requestAuthorization for .workoutType write), HKWorkoutSession + HKLiveWorkoutBuilder + HKLiveWorkoutDataSource lifecycle (start/pause/resume/end/cancel), HKWorkoutSessionDelegate and HKLiveWorkoutBuilderDelegate conformance in FitnessAppWatch Watch App/Services/WatchHealthKitManager.swift
- [x] T015 [US1] Implement HealthKit workout save flow in WatchHealthKitManager: addMetadata (com.fitnessapp.sessionId, com.fitnessapp.menuId, com.fitnessapp.menuName), finishWorkout for completed sessions, discardWorkout for cancelled sessions (FR-005, FR-006, FR-026)
- [x] T016 [US1] Implement HealthKit retry queue logic in WatchHealthKitManager: exponential backoff (0s→5s→30s→5min→app launch), max 10 retries, abandoned status with user notification, foreground trigger for pending retries (FR-015, contracts/healthkit.md)
- [x] T017 [US1] Create WorkoutViewModel as @Observable class with workout state management (active/paused/completed/cancelled), elapsed time tracking (MM:SS / H:MM:SS per FR-024), current exercise/set tracking, heart rate from HKLiveWorkoutBuilderDelegate, weight ±2.5kg and reps ±1 adjustment (FR-004), and SwiftData incremental save on each set completion (FR-007, FR-017) in FitnessAppWatch Watch App/ViewModels/WorkoutViewModel.swift
- [x] T018 [US1] Create MenuSelectionView with @Query menu list display, empty state UI with guidance message "iPhone アプリでメニューを作成してください" and free workout start option (FR-025), menu tap to start workout navigation in FitnessAppWatch Watch App/Views/MenuSelectionView.swift. フリーワークアウトモード: 種目名を都度手入力、セット数無制限で自由に記録
- [x] T019 [US1] Create ActiveWorkoutView with upper area showing current exercise name, set number, weight (adjustable ±2.5kg), reps (adjustable ±1), elapsed time (MM:SS/H:MM:SS), heart rate (bpm); lower area with full-width "次セット" button; pause/resume toggle; cancel button with confirmation dialog "ワークアウトをキャンセルしますか？" (FR-002, FR-003, FR-004, FR-020, FR-022, FR-024). フリーワークアウトモード時は種目名テキスト入力エリアを追加表示 in FitnessAppWatch Watch App/Views/ActiveWorkoutView.swift
- [x] T020 [US1] Create WorkoutSummaryView displaying total time, exercise count, total sets with "閉じる" button to return to menu list (FR-021) in FitnessAppWatch Watch App/Views/WorkoutSummaryView.swift
- [x] T021 [US1] Implement exercise auto-transition in WorkoutViewModel: advance to next exercise by sortOrder on last set completion, swipe navigation for skip/back, transition to workout completion on final exercise's final set (FR-019). フリーワークアウトモードでは手動で種目追加・完了操作を行う
- [x] T022 [US1] Implement crash recovery: check for active sessions on app launch, show "続行"/"破棄" dialog before menu list, resume or cancel session accordingly (FR-018) in FitnessAppWatch Watch App/FitnessAppWatchApp.swift
- [x] T023 [US1] Update FitnessAppWatch Watch App/FitnessAppWatchApp.swift with complete navigation flow: MenuSelectionView → ActiveWorkoutView → WorkoutSummaryView, WCSession.default.activate() on launch, modelContainer configuration

**Checkpoint**: US1 完了 — Apple Watch 単体でワークアウト実行・HealthKit 保存が機能。MVP として独立デプロイ可能

---

## Phase 4: User Story 4 - データ保存・連携 (Priority: P2)

**Goal**: ワークアウト完了データを WatchConnectivity 経由で Watch → iPhone に転送し、sessionId で HealthKit・ローカル DB を紐付ける。

**Independent Test**: Watch でワークアウトを完了後、iPhone アプリで WorkoutSession レコードが受信・保存されていることを確認。sessionId で HealthKit データと突合可能なことを検証。

### Implementation for User Story 4

- [x] T024 [US4] Implement workout result transfer via WCSession.transferUserInfo in FitnessAppWatch Watch App/WatchSessionManager.swift: convert WorkoutSession + ExerciseResults + SetResults to WorkoutResultTransfer, encode with JSONEncoder (.iso8601 date strategy), send only completed sessions (FR-014, FR-016)
- [x] T025 [P] [US4] Create WorkoutDataService with receive and persist logic: decode WorkoutResultTransfer from userInfo, create WorkoutSession + ExerciseResult + SetResult in SwiftData, sessionId-based deduplication check (FR-026) in FitnessApp/Services/WorkoutDataService.swift
- [x] T026 [US4] Update WatchConnectivityManager to handle incoming workout results in session(_:didReceiveUserInfo:): extract type=="workoutResult", delegate to WorkoutDataService for persistence in FitnessApp/WatchConnectivityManager.swift
- [x] T027 [US4] Verify end-to-end data integrity: ensure JSON round-trip (Codable conformance) works for all Transfer models, validate sessionId linkage between HealthKit metadata and SwiftData records (FR-014, FR-026)

**Checkpoint**: US4 完了 — Watch→iPhone データパイプラインが機能。sessionId で HealthKit とローカル DB を突合可能

---

## Phase 5: User Story 2 - 履歴管理（iPhone） (Priority: P2)

**Goal**: iPhone で過去のワークアウト履歴を一覧表示し、各ワークアウトの詳細を確認する。

**Independent Test**: iPhone アプリで過去のワークアウト履歴一覧が日付順に表示され（cancelled は非表示）、任意の記録をタップして詳細画面（種目、セット数、時間）に遷移できることを確認。

### Implementation for User Story 2

- [x] T028 [US2] Create HistoryViewModel as @Observable class with @Query for completed WorkoutSessions sorted by date descending, filtered to exclude cancelled status, basic statistics calculation (total duration) in FitnessApp/ViewModels/HistoryViewModel.swift
- [x] T029 [US2] Create HistoryListView with today's workouts section at top, past workouts in date-descending order, each row showing menu name, date, duration, navigation to detail view (FR-008, FR-010) in FitnessApp/Views/HistoryListView.swift
- [x] T030 [US2] Create WorkoutDetailView displaying workout session details: exercise list with set count, individual set details (weight, reps, completedAt), total time, menu name (FR-009) in FitnessApp/Views/WorkoutDetailView.swift
- [x] T031 [US2] Update FitnessApp/HomeView.swift with NavigationStack and navigation link to HistoryListView

**Checkpoint**: US1, US2, US4 が独立して機能。Watch で記録 → iPhone で履歴確認のフルフローが動作

---

## Phase 6: User Story 3 - メニュー管理（iPhone） (Priority: P3)

**Goal**: iPhone でトレーニングメニューを作成・編集し、WatchConnectivity 経由で Apple Watch に同期する。

**Independent Test**: iPhone でメニューを作成→種目を追加し、Watch 側の MenuSelectionView でそのメニューが表示・選択可能であることを確認。

### Implementation for User Story 3

- [ ] T032 [US3] Create MenuViewModel as @Observable class with @Query for TrainingMenus, CRUD operations (create/update/delete menu, add/remove/reorder exercises), trigger WatchConnectivity sync on any change in FitnessApp/ViewModels/MenuViewModel.swift
- [ ] T033 [US3] Create MenuManagementView with menu list, create/edit/delete menu UI, exercise add/remove/reorder within menu, exercise defaults (name, sets, weight, reps) input forms (FR-011, FR-012) in FitnessApp/Views/MenuManagementView.swift
- [ ] T034 [US3] Implement menu sync via updateApplicationContext in WatchConnectivityManager: convert [TrainingMenu] to [MenuTransfer] JSON Data, send with timestamp, handle isWatchAppInstalled check (FR-013) in FitnessApp/WatchConnectivityManager.swift
- [ ] T035 [US3] Update WatchSessionManager to receive menu data from applicationContext: decode [MenuTransfer] JSON, cache locally for MenuSelectionView display, handle decode errors gracefully in FitnessAppWatch Watch App/WatchSessionManager.swift
- [ ] T036 [US3] Update FitnessApp/HomeView.swift with navigation link to MenuManagementView

**Checkpoint**: 全ユーザーストーリー (US1-US4) が独立して機能。フルシステムが動作

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: 全ストーリーにまたがる改善と品質向上

- [ ] T037 [P] Code cleanup: remove unused existing code from WorkoutView.swift (replaced by ActiveWorkoutView), verify all FR/NFR traceability, ensure Codable conformance for all models
- [ ] T038 [P] Error handling hardening: HealthKit unavailable fallback (hide HK UI), HealthKit permission denied guidance message, WatchConnectivity decode error logging, SwiftData save error handling across all ViewModels
- [ ] T039 Run quickstart.md validation: execute build & run steps (iPhone scheme + Watch scheme), verify menu sync flow, verify workout recording flow, verify history display, verify SC-001 (メニュー選択画面からワークアウト完了まで 5 タップ以内)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 依存なし — 即時開始可能
- **Foundational (Phase 2)**: Setup 完了に依存 — **全ユーザーストーリーをブロック**
- **US1 (Phase 3)**: Foundational 完了に依存 — 他ストーリーへの依存なし
- **US4 (Phase 4)**: US1 のコア実装完了に依存（ワークアウト完了フローが必要）
- **US2 (Phase 5)**: Foundational 完了に依存 — US4 完了が望ましい（iPhone にデータが存在する必要あり）
- **US3 (Phase 6)**: Foundational 完了に依存 — US1 の MenuSelectionView と連携
- **Polish (Phase 7)**: 全ユーザーストーリー完了に依存

### User Story Dependencies

- **US1 (P1)**: Foundational 完了後に開始可能 — 他ストーリーへの依存なし。**MVP として単独リリース可能**
- **US4 (P2)**: US1 の WatchHealthKitManager + WorkoutViewModel 完了後に開始可能
- **US2 (P2)**: Foundational 完了後に開始可能。ただし US4 完了後に実データでの検証推奨
- **US3 (P3)**: Foundational 完了後に開始可能 — US1 の MenuSelectionView が受信側として存在する必要あり

### Within Each User Story

- サービス層 → ViewModel → Views の順序
- モデルはすべて Foundational フェーズで作成済み
- コア実装 → インタラクティブ機能 → ナビゲーション統合
- 各ストーリー完了後に独立検証を実施

### Parallel Opportunities

- Phase 2 の全モデルタスク (T005-T012) は並列実行可能（異なるファイル）
- US2 (Phase 5) と US3 (Phase 6) は US4 完了後に並列実行可能
- 各フェーズ内の [P] マークタスクは並列実行可能

---

## Parallel Example: User Story 1

```text
# Phase 2 完了後（HealthKitRetryItem モデルも T012 で作成済み）、US1 のサービスを作成:
Task T014: "WatchHealthKitManager 作成" (Service)

# T014 完了後、HealthKit save flow を追加:
Task T015: "HealthKit save flow 実装"
Task T016: "Retry queue 実装"

# T017 完了後（ViewModel 準備完了）、Views を順次作成:
Task T018: "MenuSelectionView"
Task T019: "ActiveWorkoutView"
Task T020: "WorkoutSummaryView"
```

## Parallel Example: US2 + US3 同時進行

```text
# US4 完了後、異なるターゲットのため並列可能:
Developer A (iOS): US2 — HistoryViewModel → HistoryListView → WorkoutDetailView
Developer B (iOS): US3 — MenuViewModel → MenuManagementView → WC sync
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup 完了
2. Phase 2: Foundational 完了（**CRITICAL** — 全ストーリーをブロック）
3. Phase 3: US1 完了（Watch ワークアウト実行 + HealthKit 保存）
4. **STOP and VALIDATE**: Watch 単体でワークアウト記録→HealthKit 保存を検証
5. MVP としてデプロイ/デモ可能

### Incremental Delivery

1. Setup + Foundational → 基盤準備完了
2. US1 完了 → Watch 単体テスト → **MVP リリース** 🎯
3. US4 追加 → Watch→iPhone データパイプライン確立
4. US2 追加 → iPhone 履歴表示 → デモ（記録→閲覧フロー）
5. US3 追加 → メニュー管理 → 完全版リリース
6. Polish → 品質向上・エッジケース対応

### Parallel Team Strategy

複数開発者がいる場合:

1. チーム全員で Setup + Foundational を完了
2. Foundational 完了後:
   - Developer A: US1 (Watch ワークアウト) → US4 (データ連携)
   - Developer B: US2 (iPhone 履歴) ※US4 完了待ちの間に UI 実装
   - Developer C: US3 (メニュー管理)
3. 各ストーリーは独立して完了・検証可能

---

## Notes

- [P] タスク = 異なるファイル、依存関係なし
- [Story] ラベルはユーザーストーリーへのトレーサビリティを確保
- 各ユーザーストーリーは独立して完了・検証可能
- 各タスクまたは論理的グループ完了後にコミット推奨
- チェックポイントでストーリーの独立検証を実施
- SwiftData モデルの Target Membership 設定は T013 で一括実施（Xcode プロジェクト設定が必要）
- 既存ファイル（HomeView.swift, WatchConnectivityManager.swift, WatchSessionManager.swift, FitnessAppWatchApp.swift, FitnessAppApp.swift）は各ストーリーで順次更新

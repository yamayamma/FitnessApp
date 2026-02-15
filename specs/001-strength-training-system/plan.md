# Implementation Plan: 筋力トレーニング記録システム

**Branch**: `001-strength-training-system` | **Date**: 2026-02-15 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-strength-training-system/spec.md`

## Summary

Apple Watch での筋力トレーニングワークアウトを最小タップで記録し、HealthKit と SwiftData への二重保存を sessionId（UUID）で紐付ける。iPhone では履歴管理とメニュー管理を提供し、WatchConnectivity（`updateApplicationContext`）でメニューを Watch に同期する。MVVM アーキテクチャで構成し、SwiftData `@Model` によるデータモデル、HKWorkoutSession による HealthKit 統合を実装する。

## Technical Context

**Language/Version**: Swift 5.9+  
**Primary Dependencies**: SwiftUI, HealthKit, WatchConnectivity, SwiftData  
**Storage**: HealthKit（HKWorkout）, SwiftData（ローカル DB、`@Model` マクロ）  
**Testing**: XCTest  
**Target Platform**: iOS 17+, watchOS 10+  
**Project Type**: mobile（iOS + watchOS 2ターゲット）  
**Architecture**: MVVM（Model-View-ViewModel）  
**Performance Goals**: Watch でワークアウト記録を 5 タップ以内、iPhone 履歴一覧表示 1 秒以内  
**Constraints**: オフライン完全動作必須、外部 API 依存なし、Apple 審査基準準拠  
**Scale/Scope**: 個人利用 MVP、5 エンティティ、Watch 3 画面 + iPhone 4 画面

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Gate Criteria | Status |
|---|-----------|--------------|--------|
| I | Privacy-First | すべてのデータフローがローカル完結か？外部 API 依存なしか？ | ✅ PASS — HealthKit + SwiftData ローカルのみ、外部通信なし |
| II | Minimal Friction Recording | Watch 操作 5 タップ以内か？オフライン動作可能か？ | ✅ PASS — ボタンタップ方式、ネットワーク不要 |
| III | Extensible Architecture | sessionId（UUID）で HealthKit-SwiftData 紐付けか？JSON 変換可能か？Phase 分離遵守か？ | ✅ PASS — sessionId 設計済み、Codable 準拠、MVP スコープ外機能除外 |
| IV | Platform-Native Design | SwiftUI + HealthKit + WatchConnectivity 使用か？HIG 準拠か？ | ✅ PASS — 標準 API のみ使用、HIG 準拠の UI 設計 |
| V | Incremental Delivery | MVP で独立リリース可能か？除外機能の混入なしか？ | ✅ PASS — wger/MCP/クラウド同期/AI 明示除外 |

**Gate Result: PASS** — 全原則に違反なし。Phase 0 研究に進む。

## Project Structure

### Documentation (this feature)

```text
specs/001-strength-training-system/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
FitnessApp/                          # iOS app target
├── FitnessAppApp.swift              # App entry (既存)
├── Info.plist                       # (既存、Privacy Description 追加必要)
├── FitnessApp.entitlements          # (既存、HealthKit 有効済み)
├── WatchConnectivityManager.swift   # (既存、拡張予定)
├── Models/                          # SwiftData モデル (共有)
│   ├── WorkoutSession.swift
│   ├── ExerciseResult.swift
│   ├── SetResult.swift
│   ├── TrainingMenu.swift
│   └── Exercise.swift
├── ViewModels/
│   ├── HistoryViewModel.swift
│   └── MenuViewModel.swift
├── Views/
│   ├── HomeView.swift               # (既存 → リファクタリング)
│   ├── HistoryListView.swift
│   ├── WorkoutDetailView.swift
│   └── MenuManagementView.swift
└── Services/
    ├── HealthKitManager.swift
    └── WorkoutDataService.swift

FitnessAppWatch Watch App/           # watchOS app target
├── FitnessAppWatchApp.swift         # App entry (既存)
├── WatchSessionManager.swift        # (既存、拡張予定)
├── ViewModels/
│   └── WorkoutViewModel.swift
├── Views/
│   ├── MenuSelectionView.swift
│   ├── ActiveWorkoutView.swift
│   └── WorkoutSummaryView.swift
└── Services/
    └── WatchHealthKitManager.swift

FitnessAppTests/                     # iOS unit tests
└── FitnessAppTests.swift            # (既存、テスト追加)

FitnessAppWatch Watch AppTests/      # watchOS unit tests
└── FitnessAppWatch_Watch_AppTests.swift  # (既存、テスト追加)
```

**Structure Decision**: Mobile（iOS + watchOS）2ターゲット構成。SwiftData モデルは iOS ターゲット `FitnessApp/Models/` に配置し、
watchOS ターゲットからも同じソースファイルを Target Membership で共有する
（別フレームワーク作成は MVP では過剰なため回避）。

## Complexity Tracking

> 原則違反なし。複雑性の正当化は不要。

---

## Phase 0: Research

**Status**: ✅ Complete

**Output**: [research.md](research.md)

| # | Topic | Decision |
|---|-------|----------|
| R1 | HKWorkoutSession パターン | HKWorkoutSession + HKLiveWorkoutBuilder + HKLiveWorkoutDataSource |
| R2 | SwiftData on watchOS | watchOS 10+ 対応、iOS/watchOS 独立ストア |
| R3 | WatchConnectivity 方式 | menus: updateApplicationContext / results: transferUserInfo |
| R4 | HealthKit metadata | reverse-domain keys (`com.fitnessapp.*`) |
| R5 | workout-processing 制約 | 単一セッション動作、バックグラウンド実行保証 |
| R6 | データフロー設計 | Watch ローカル保存 → 完了時に transferUserInfo → iPhone DB 保存 |

---

## Phase 1: Design & Contracts

**Status**: ✅ Complete

### Artifacts

| File | Description |
|------|-------------|
| [data-model.md](data-model.md) | SwiftData エンティティ定義（5 entities）、状態遷移図、JSON スキーマ、WatchConnectivity Transfer Models |
| [contracts/watch-connectivity.md](contracts/watch-connectivity.md) | WatchConnectivity プロトコル定義（Menu Sync / Workout Result） |
| [contracts/healthkit.md](contracts/healthkit.md) | HealthKit ワークアウトプロトコル定義（Authorization / Session Lifecycle / Auto-Retry） |
| [quickstart.md](quickstart.md) | セットアップ手順、プロジェクト構成、データフロー概要 |

### Constitution Check (Post-Design Re-evaluation)

| # | Principle | Gate Criteria | Status |
|---|-----------|--------------|--------|
| I | Privacy-First | 全データフローがローカル完結か？ | ✅ PASS — SwiftData + HealthKit + WatchConnectivity（デバイス間直接通信のみ） |
| II | Minimal Friction Recording | Watch 操作が最小タップか？ | ✅ PASS — セット完了ワンタップ、重量/レップはデフォルト値プリセット |
| III | Extensible Architecture | sessionId 紐付け・JSON 変換・Phase 分離？ | ✅ PASS — 全モデル Codable、TransferModels 分離設計、MCP/wger 除外 |
| IV | Platform-Native Design | 標準 API・HIG 準拠？ | ✅ PASS — HKWorkoutSession + HKLiveWorkoutBuilder + WCSession |
| V | Incremental Delivery | MVP 独立リリース可能？ | ✅ PASS — 7画面・5エンティティの完結したスコープ |

**Post-Design Gate Result: PASS** — 設計段階で原則違反なし。Phase 2（Tasks）に進行可能。

---

## Phase 2: Tasks

**Status**: ⏳ Pending — 次コマンド `/speckit.tasks` で生成

**Output**: [tasks.md](tasks.md) (未生成)

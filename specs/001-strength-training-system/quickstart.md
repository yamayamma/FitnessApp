# Quickstart: 筋力トレーニング記録システム

## 前提条件

- Xcode 15.0+
- iOS 17.0+ / watchOS 10.0+
- Apple Watch ペアリング済み（実機テスト時）
- Apple Developer Account（HealthKit Capability 必須）

## プロジェクト構成

```
FitnessApp/
├── Models/                          # SwiftData モデル（iOS + watchOS 共有）
│   ├── WorkoutSession.swift
│   ├── ExerciseResult.swift
│   ├── SetResult.swift
│   ├── TrainingMenu.swift
│   ├── Exercise.swift
│   └── TransferModels.swift         # WatchConnectivity 用 Codable structs
├── ViewModels/                      # iOS 側 ViewModel
│   ├── MenuManagementViewModel.swift
│   └── WorkoutHistoryViewModel.swift
├── Views/                           # iOS 側 View
│   ├── HomeView.swift
│   ├── MenuManagementView.swift
│   └── WorkoutHistoryView.swift
├── Services/                        # iOS 側サービス
│   ├── WatchConnectivityManager.swift
│   └── HealthKitRetryService.swift
├── FitnessAppApp.swift
└── Info.plist

FitnessAppWatch Watch App/
├── ViewModels/                      # watchOS 側 ViewModel
│   └── WorkoutViewModel.swift
├── Views/                           # watchOS 側 View
│   ├── MenuListView.swift
│   ├── WorkoutView.swift
│   └── SetInputView.swift
├── Services/                        # watchOS 側サービス
│   ├── WatchSessionManager.swift
│   ├── HealthKitWorkoutService.swift
│   └── WorkoutPersistenceService.swift
├── FitnessAppWatchApp.swift
└── FitnessAppWatch Watch App.entitlements
```

## セットアップ手順

### 1. Capabilities 確認

iOS ターゲット:
- HealthKit ✅（既に設定済み）

watchOS ターゲット:
- HealthKit ✅（既に設定済み）
- Background Modes > Workout Processing ✅（既に設定済み）

### 2. SwiftData Model Container 設定

```swift
// FitnessAppApp.swift
@main
struct FitnessAppApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [
            TrainingMenu.self,
            Exercise.self,
            WorkoutSession.self,
            ExerciseResult.self,
            SetResult.self
        ])
    }
}
```

```swift
// FitnessAppWatchApp.swift
@main
struct FitnessAppWatchApp: App {
    var body: some Scene {
        WindowGroup {
            MenuListView()
        }
        .modelContainer(for: [
            WorkoutSession.self,
            ExerciseResult.self,
            SetResult.self
        ])
    }
}
```

### 3. HealthKit Authorization (Watch)

```swift
// HealthKitWorkoutService.swift
func requestAuthorization() async throws {
    let typesToWrite: Set<HKSampleType> = [HKWorkoutType.workoutType()]
    let typesToRead: Set<HKObjectType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned)
    ]
    try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
}
```

### 4. WatchConnectivity Activation

両ターゲットで `WCSession.default.activate()` を App init 時に呼び出し。

## ビルド & 実行

1. `FitnessApp` scheme を選択 → iPhone シミュレータで実行
2. `FitnessAppWatch Watch App` scheme を選択 → Watch シミュレータで実行
3. メニュー同期テスト: iPhone でメニュー作成 → Watch に自動反映を確認
4. ワークアウトテスト: Watch でメニュー選択 → セット記録 → 完了 → iPhone 側の履歴で確認

## 主要なデータフロー

```
[iPhone]                                    [Watch]
   │                                           │
   │  1. メニュー作成/編集                       │
   │──── updateApplicationContext ─────────────▶│
   │                                           │
   │                                           │  2. メニュー選択 → ワークアウト開始
   │                                           │  3. HKWorkoutSession.startActivity()
   │                                           │  4. セット完了 → SwiftData に即時保存
   │                                           │  5. 全セット完了 → HKWorkout 保存
   │                                           │
   │◀──── transferUserInfo ────────────────────│  6. 結果送信
   │                                           │
   │  7. ローカル DB に保存                      │
   │  8. 履歴画面で表示                          │
```

## テスト戦略

| 層 | テスト内容 | フレームワーク |
|----|-----------|--------------|
| Model | SwiftData CRUD、バリデーション | XCTest |
| ViewModel | 状態遷移、ビジネスロジック | XCTest |
| Service | HealthKit mock、WC mock | XCTest + Protocol |
| Integration | E2E フロー | XCTest (UI なし) |

## トラブルシューティング

| 問題 | 解決策 |
|------|--------|
| Watch に メニューが表示されない | WCSession.activationState を確認、isWatchAppInstalled チェック |
| HealthKit 保存失敗 | authorizationStatus 確認、リトライキューのログ確認 |
| クラッシュ後にデータ消失 | SwiftData は自動永続化。WorkoutSession の status が active のまま残るため、次回起動時にリカバリダイアログ表示 |

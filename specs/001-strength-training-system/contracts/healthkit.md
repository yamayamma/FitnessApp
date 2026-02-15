# HealthKit Contract

**Version**: 1.0.0  
**Date**: 2026-02-15

## Overview

Apple Watch 上での HealthKit ワークアウト記録プロトコル定義。

## Authorization

### Required Permissions

| Permission | Type | Identifier | Purpose |
|------------|------|------------|---------|
| Write | HKWorkoutType | `.workoutType()` | ワークアウト記録の保存 |
| Read | HKQuantityType | `.heartRate` | ワークアウト中の心拍数表示（将来） |
| Read | HKQuantityType | `.activeEnergyBurned` | 消費カロリー表示（将来） |

### Authorization Flow

1. Watch App 初回起動時に `HKHealthStore.requestAuthorization()` を呼び出し
2. ユーザーが拒否した場合: ワークアウト記録はローカル DB のみに保存、HealthKit 連携なし
3. 権限状態は `HKHealthStore.authorizationStatus(for:)` で毎回確認

---

## Workout Session Protocol

### Activity Type

```swift
HKWorkoutActivityType.traditionalStrengthTraining
```

### Location Type

```swift
HKWorkoutSessionLocationType.indoor
```

### Session Configuration

```swift
let configuration = HKWorkoutConfiguration()
configuration.activityType = .traditionalStrengthTraining
configuration.locationType = .indoor
```

---

## Workout Lifecycle

### 1. Start Workout

```swift
// 1. Create session
let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)

// 2. Create builder
let builder = session.associatedWorkoutBuilder()

// 3. Set data source
builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

// 4. Start session & builder
session.startActivity(with: Date())
try await builder.beginCollection(at: Date())
```

### 2. Pause Workout

```swift
session.pause()
```

### 3. Resume Workout

```swift
session.resume()
```

### 4. End Workout

```swift
session.end()
try await builder.endCollection(at: Date())

// Add custom metadata before finishing
try await builder.addMetadata([
    "com.fitnessapp.sessionId": sessionId.uuidString,
    "com.fitnessapp.menuId": menuId?.uuidString ?? "",
    "com.fitnessapp.menuName": menuName ?? ""
])

try await builder.finishWorkout()
```

### 5. Cancel Workout (HealthKit に保存しない)

```swift
session.end()
try await builder.endCollection(at: Date())
builder.discardWorkout()
```

---

## Custom Metadata Keys

| Key | Type | Description |
|-----|------|-------------|
| `com.fitnessapp.sessionId` | String (UUID) | ローカル DB の WorkoutSession.sessionId との紐付け |
| `com.fitnessapp.menuId` | String (UUID) | 使用したメニューの ID（空文字 = メニューなし） |
| `com.fitnessapp.menuName` | String | メニュー名（表示用） |

---

## HealthKit Auto-Retry Queue (FR-015)

### Retry Strategy

| Attempt | Delay | Description |
|---------|-------|-------------|
| 1 | 0s | 即時（ワークアウト完了時） |
| 2 | 5s | 最初のリトライ |
| 3 | 30s | 2回目のリトライ |
| 4 | 300s (5min) | 3回目のリトライ |
| 5+ | App 次回起動時 | 未保存をスキャンして再試行 |

### Retry Queue Model

```swift
struct HealthKitRetryItem {
    let sessionId: UUID
    let workoutData: Data  // WorkoutResultTransfer の JSON
    var attemptCount: Int
    var lastAttemptDate: Date
    var status: RetryStatus  // pending, inProgress, succeeded, abandoned
}

enum RetryStatus: String {
    case pending
    case inProgress
    case succeeded
    case abandoned  // 最大リトライ超過
}
```

### 保存フロー

```
┌─────────────────┐
│ Workout Complete │
└────────┬────────┘
         │
         ▼
┌────────────────────┐    成功     ┌───────────┐
│ HealthKit に保存試行 │──────────▶│   完了     │
└────────┬───────────┘            └───────────┘
         │ 失敗
         ▼
┌────────────────────┐
│ ローカル DB に保存   │  ← 常に実行（先にローカル保存）
│ + RetryQueue に追加  │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│ バックグラウンドで    │
│ リトライ実行         │
└────────────────────┘
```

---

## Error Handling

| Error | Action |
|-------|--------|
| `HKError.errorAuthorizationDenied` | HealthKit 保存をスキップ、ローカル DB のみ |
| `HKError.errorAuthorizationNotDetermined` | 権限リクエストダイアログを表示 |
| `HKError.errorDatabaseInaccessible` | リトライキューに追加 |
| Network/iCloud Error | リトライキューに追加 |
| Session already ended | ログ出力、無視 |

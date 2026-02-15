# HealthKit Contract

**Version**: 1.0.0  
**Date**: 2026-02-15

## Overview

Apple Watch 上での HealthKit ワークアウト記録プロトコル定義。

## Authorization

### Required Permissions

| Permission | Type | Identifier | Purpose | MVP Scope |
|------------|------|------------|---------|----------|
| Write | HKWorkoutType | `.workoutType()` | ワークアウト記録の保存 | ✅ MVP |
| Read | HKQuantityType | `.heartRate` | ワークアウト履歴からの心拍数参照 | ❌ 将来（履歴用） |
| Read | HKQuantityType | `.activeEnergyBurned` | 消費カロリー表示 | ❌ 将来 |

> **MVP の心拍数表示 (FR-003)**: `HKLiveWorkoutDataSource` によりワークアウト中のライブ心拏数データは明示的な Read 権限なしで自動収集される。上記の `.heartRate` Read 権限は将来の履歴データクエリ用に予約。

### Authorization Flow

1. Watch App 初回起動時に `HKHealthStore.requestAuthorization()` を呼び出し
2. ユーザーが拒否した場合:
   - ワークアウト記録はローカル DB のみに保存、HealthKit 連携なし
   - 「HealthKit 連携が無効です。設定アプリから有効化できます」の案内を表示
3. 権限状態はワークアウト開始前に `HKHealthStore.authorizationStatus(for:)` で確認
4. `HKHealthStore.isHealthDataAvailable() == false` の場合: ローカル DB のみで動作、HealthKit 関連 UI を非表示
5. ユーザーが設定アプリで権限を変更した場合: 次回の authorizationStatus チェックで新しい状態が反映される

### Privacy Description (Info.plist)

| Key | Text |
|-----|------|
| `NSHealthUpdateUsageDescription` | This app records your strength training workouts to Apple Health. |
| `NSHealthShareUsageDescription` | This app reads your heart rate during workouts to display real-time data. |

> **注意**: Privacy Description は App Store 審査で必須。テキストは英語のみ（Localizable 対応は将来）。

---

## Workout Session Protocol

### Activity Type

```swift
HKWorkoutActivityType.traditionalStrengthTraining
```

> **選択根拠**: フリーウェイトなどの機能的トレーニング（`.functionalStrengthTraining`）と区別し、マシン・バーベル・ダンベル等の従来型筋トレ種目を対象とするため `traditionalStrengthTraining` を採用。

### Location Type

```swift
HKWorkoutSessionLocationType.indoor
```

> **注意**: MVP では `.indoor` 固定。屋外トレーニング対応は将来検討事項。

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
```

> **`menuId` の空文字列**: HKWorkout metadata は `NSString` 型のみ受付のため、`nil` ではなく空文字列 `""` を使用して「メニューなし」を表現する。

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

HealthKit metadata キーは reverse-domain 形式 `com.fitnessapp.*` で統一する。

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
| 5-10 | App 次回起動時 | 未保存をスキャンして再試行 |

**最大リトライ回数**: 10 回。超過時は `abandoned` ステータスに遷移し、次回アプリ起動時にユーザーへバナー通知を表示する。

### Retry Queue Model

```swift
struct HealthKitRetryItem: Codable {
    let sessionId: UUID
    let workoutData: Data  // WorkoutResultTransfer の JSON
    var attemptCount: Int
    var lastAttemptDate: Date
    var status: RetryStatus  // pending, inProgress, succeeded, abandoned
}

enum RetryStatus: String, Codable {
    case pending
    case inProgress
    case succeeded
    case abandoned  // 最大リトライ超過（>= 10 回）
}
```

**永続化方式**: SwiftData `@Model` として Watch ローカル DB に保存する。UserDefaults はサイズ制約のため不採用。

**バックグラウンドリトライトリガー**: App foreground 復帰時に未保存キューをスキャンして再試行する。BGTaskScheduler は MVP では使用しない（watchOS での制約が大きいため）。

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
| `HKError.errorAuthorizationDenied` | HealthKit 保存をスキップ、ローカル DB のみ。ユーザーに案内表示 |
| `HKError.errorAuthorizationNotDetermined` | 権限リクエストダイアログを表示 |
| `HKError.errorDatabaseInaccessible` | リトライキューに追加 |
| Network/iCloud Error | リトライキューに追加 |
| Session already ended | ログ出力、無視 |
| その他の HKError | ログ出力、リトライキューに追加（デフォルト動作） |

> **データ活用制約**: Apple Guidelines に従い、HealthKit データを広告・データマイニングに使用しない。本アプリでは全データがローカル保存のみ（Constitution §I）。HealthKit データは iCloud バックアップの対象外である点に注意。

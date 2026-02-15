# Data Model: 筋力トレーニング記録システム

**Date**: 2026-02-15  
**Storage**: SwiftData (`@Model` マクロ)  
**Shared**: iOS / watchOS で同じモデルソースファイルを Target Membership で共有

## Entity Relationship Diagram

```
TrainingMenu (1) ──── (*) Exercise
      │
      │ menuId
      ▼
WorkoutSession (1) ──── (*) ExerciseResult (1) ──── (*) SetResult
```

## Entities

### WorkoutSession

ワークアウトセッションの全体を表す。HealthKit の `HKWorkout` と `sessionId` で紐付ける。

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | ✅ | SwiftData 主キー（自動生成） |
| sessionId | UUID | ✅ | HealthKit metadata との紐付けキー |
| startDate | Date | ✅ | ワークアウト開始時刻 |
| endDate | Date? | ❌ | ワークアウト終了時刻（active/paused 中は nil） |
| menuId | UUID? | ❌ | 使用したメニューの ID（メニューなし開始も許可） |
| menuName | String? | ❌ | メニュー名（表示用、非正規化） |
| totalDuration | TimeInterval | ✅ | 合計ワークアウト時間（秒） |
| status | WorkoutStatus | ✅ | セッション状態 |
| exerciseResults | [ExerciseResult] | ✅ | 種目結果の配列（@Relationship） |
| createdAt | Date | ✅ | レコード作成時刻 |

**WorkoutStatus** (enum: String, Codable):
- `active` — 進行中
- `paused` — 一時停止中
- `completed` — 完了（HealthKit 保存済み）
- `cancelled` — キャンセル（HealthKit 未保存、ローカル DB に保持）

**Validation rules**:
- `sessionId` はレコード全体で一意
- `status` が `completed` の場合、`endDate` は必須
- `totalDuration` >= 0

### ExerciseResult

セッション内の各種目の実行結果。

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | ✅ | SwiftData 主キー |
| exerciseId | UUID | ✅ | 種目定義への参照 |
| exerciseName | String | ✅ | 種目名（表示用、非正規化） |
| setResults | [SetResult] | ✅ | セット結果の配列（@Relationship） |
| session | WorkoutSession | ✅ | 親セッション（inverse） |
| sortOrder | Int | ✅ | セッション内の種目順序 |

### SetResult

各セットの個別結果。

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | ✅ | SwiftData 主キー |
| setNumber | Int | ✅ | セット番号（1始まり） |
| weight | Double | ✅ | 重量（kg） |
| reps | Int | ✅ | レップ数 |
| completedAt | Date | ✅ | セット完了時刻のタイムスタンプ |
| exerciseResult | ExerciseResult | ✅ | 親種目結果（inverse） |

**Validation rules**:
- `weight` >= 0
- `reps` >= 0
- `setNumber` >= 1

### TrainingMenu

iPhone で定義するトレーニングメニューのプリセット。

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | ✅ | SwiftData 主キー |
| menuId | UUID | ✅ | メニュー識別子（WatchConnectivity 同期用） |
| name | String | ✅ | メニュー名 |
| exercises | [Exercise] | ✅ | 種目の配列（@Relationship） |
| createdAt | Date | ✅ | 作成日時 |
| updatedAt | Date | ✅ | 最終更新日時 |

### Exercise

種目の定義。メニューに所属。

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | ✅ | SwiftData 主キー |
| exerciseId | UUID | ✅ | 種目識別子 |
| name | String | ✅ | 種目名 |
| defaultSets | Int | ✅ | デフォルトセット数 |
| defaultWeight | Double | ✅ | デフォルト重量（kg） |
| defaultReps | Int | ✅ | デフォルトレップ数 |
| menu | TrainingMenu | ✅ | 親メニュー（inverse） |
| sortOrder | Int | ✅ | メニュー内の種目順序 |

**Validation rules**:
- `defaultSets` >= 1
- `defaultWeight` >= 0
- `defaultReps` >= 1

## State Transitions

```
                    ┌──────────┐
                    │  (new)   │
                    └────┬─────┘
                         │ startWorkout()
                         ▼
                    ┌──────────┐
              ┌────▶│  active  │◀────┐
              │     └────┬─┬───┘     │
              │          │ │         │
              │  resume()│ │pause()  │
              │          │ │         │
              │     ┌────▼─▼───┐     │
              └─────│  paused  │─────┘
                    └────┬─┬───┘
                         │ │
          completeWorkout│ │cancelWorkout()
                         │ │
                    ┌────▼─▼───┐
                    │completed │  cancelWorkout()
                    │    or    │◀─── from active
                    │cancelled │
                    └──────────┘
```

## JSON Schema (Codable)

すべてのエンティティは `Codable` に準拠し、JSON 変換可能。
将来の MCP / wger 連携で使用するエクスポート形式:

```json
{
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "startDate": "2026-02-15T10:00:00Z",
  "endDate": "2026-02-15T10:45:00Z",
  "status": "completed",
  "menuName": "Push Day",
  "totalDuration": 2700,
  "exercises": [
    {
      "exerciseId": "...",
      "exerciseName": "ベンチプレス",
      "sets": [
        {
          "setNumber": 1,
          "weight": 60.0,
          "reps": 10,
          "completedAt": "2026-02-15T10:05:30Z"
        }
      ]
    }
  ]
}
```

## WatchConnectivity Transfer Models

### メニュー同期 (iPhone → Watch): `updateApplicationContext`

```json
{
  "menus": "<Data: JSONEncoder output of [MenuTransfer]>"
}
```

**MenuTransfer** (Codable struct, not @Model):
```swift
struct MenuTransfer: Codable {
    let menuId: UUID
    let name: String
    let exercises: [ExerciseTransfer]
}

struct ExerciseTransfer: Codable {
    let exerciseId: UUID
    let name: String
    let defaultSets: Int
    let defaultWeight: Double
    let defaultReps: Int
    let sortOrder: Int
}
```

### ワークアウト結果 (Watch → iPhone): `transferUserInfo`

```json
{
  "type": "workoutResult",
  "sessionId": "<UUID string>",
  "data": "<Data: JSONEncoder output of WorkoutResultTransfer>"
}
```

**WorkoutResultTransfer** (Codable struct):
```swift
struct WorkoutResultTransfer: Codable {
    let sessionId: UUID
    let startDate: Date
    let endDate: Date
    let menuId: UUID?
    let menuName: String?
    let totalDuration: TimeInterval
    let status: String
    let exercises: [ExerciseResultTransfer]
}

struct ExerciseResultTransfer: Codable {
    let exerciseId: UUID
    let exerciseName: String
    let sets: [SetResultTransfer]
}

struct SetResultTransfer: Codable {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let completedAt: Date
}
```

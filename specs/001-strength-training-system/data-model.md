# Data Model: 筋力トレーニング記録システム

**Date**: 2026-02-15  
**Storage**: SwiftData (`@Model` マクロ)  
**Shared**: iOS / watchOS で同一のモデルソースファイルを Target Membership で共有  
**Store**: 各デバイス（iOS / watchOS）が独立した SwiftData ストアを保持。データは WatchConnectivity 経由でのみ同期される（cf. research.md §R2）  
**Date Format**: ISO 8601（`yyyy-MM-dd'T'HH:mm:ssZ`）。`JSONEncoder.dateEncodingStrategy = .iso8601` を標準設定とする（NFR-007）  
**Weight Unit**: kg 固定（NFR-006）

## Entity Relationship Diagram

```
TrainingMenu (1) ──── (*) Exercise
      │
      │ menuId
      ▼
WorkoutSession (1) ──── (*) ExerciseResult (1) ──── (*) SetResult
```

**Cascade Delete Rules**:
- WorkoutSession 削除 → ExerciseResult `.cascade`（配下の種目結果も削除）
- ExerciseResult 削除 → SetResult `.cascade`（配下のセット結果も削除）
- TrainingMenu 削除 → Exercise `.cascade`（メニュー削除時に種目定義も削除）
- WorkoutSession → TrainingMenu: `menuId` UUID 値による間接参照（`@Relationship` なし。メニュー削除時もセッションは保持）

## Entities

### WorkoutSession

ワークアウトセッションの全体を表す。HealthKit の `HKWorkout` と `sessionId` で紐付ける。

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | ✅ | SwiftData 主キー（自動生成。SwiftData フレームワークが内部管理する PK） |
| sessionId | UUID | ✅ | HealthKit metadata ・ WatchConnectivity transfer との紐付けキー。クロスシステム識別子として、ローカル DB とは別に必要（`id` は SwiftData 内部用で外部連携には使用しない） |
| startDate | Date | ✅ | ワークアウト開始時刻 |
| endDate | Date? | ❌ | ワークアウト終了時刻（active/paused 中は nil） |
| menuId | UUID? | ❌ | 使用したメニューの ID（メニューなし開始も許可） |
| menuName | String? | ❌ | メニュー名（表示用、非正規化） |
| totalDuration | TimeInterval | ✅ | 合計ワークアウト時間（秒） |
| status | WorkoutStatus | ✅ | セッション状態 |
| exerciseResults | [ExerciseResult] | ✅ | 種目結果の配列（@Relationship） |
| createdAt | Date | ✅ | レコード作成時刻（セッションの作成日管理用。spec.md の Key Entities には必須属性のみ記載し、補助的な管理属性は data-model.md で定義） |

**WorkoutStatus** (enum: String, Codable):
- `active` — 進行中
- `paused` — 一時停止中
- `completed` — 完了（HealthKit 保存済み）
- `cancelled` — キャンセル（HealthKit 未保存、ローカル DB に保持）

**Validation rules**:
- `sessionId` はレコード全体で一意（SwiftData `@Attribute(.unique)` で制約）
- `sessionId` はワークアウト開始時（`HKWorkoutSession` 生成と同時）に `UUID()` で生成する（FR-026）
- `status` が `completed` の場合、`endDate` は必須
- `totalDuration` >= 0

### ExerciseResult

セッション内の各種目の実行結果。

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | ✅ | SwiftData 主キー |
| exerciseId | UUID | ✅ | 種目定義への UUID 値参照（`@Relationship` ではなく値コピー。watchOS 側に TrainingMenu/Exercise エンティティが存在しないため、直接リレーションシップを避ける） |
| exerciseName | String | ✅ | 種目名（表示用、非正規化。同上の理由で Exercise から直接参照できないため） |
| setResults | [SetResult] | ✅ | セット結果の配列（@Relationship） |
| session | WorkoutSession | ✅ | 親セッション（inverse） |
| sortOrder | Int | ✅ | セッション内の種目順序（FR-019 の種目自動遷移順序を実現） |

### SetResult

各セットの個別結果。

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | ✅ | SwiftData 主キー |
| setNumber | Int | ✅ | セット番号（1始まり） |
| weight | Double | ✅ | 重量（kg。NFR-006 により MVP では kg 固定） |
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
| createdAt | Date | ✅ | 作成日時（レコード管理用） |
| updatedAt | Date | ✅ | 最終更新日時（レコード管理用） |

### Exercise

種目の定義。メニューに所属。

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | ✅ | SwiftData 主キー |
| exerciseId | UUID | ✅ | 種目識別子 |
| name | String | ✅ | 種目名 |
| defaultSets | Int | ✅ | デフォルトセット数 |
| defaultWeight | Double | ✅ | デフォルト重量（kg）。ワークアウト開始時のセット入力画面初期値として使用（FR-004 のワンタップ記録を実現） |
| defaultReps | Int | ✅ | デフォルトレップ数。同上 |
| menu | TrainingMenu | ✅ | 親メニュー（inverse） |
| sortOrder | Int | ✅ | メニュー内の種目順序（FR-019 の自動遷移順序を決定） |

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
日付フォーマットは ISO 8601（`yyyy-MM-dd'T'HH:mm:ssZ`）を使用する（NFR-007）。
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

> **設計意図**: SwiftData `@Model` は `Codable` に自動準拠しないため、WatchConnectivity での JSON シリアライズには別途 `Codable` な Transfer struct が必要。また `@Relationship` プロパティは JSON シリアライズで循環参照を引き起こすため、フラットな Transfer モデルに変換して送信する。

### マッピング対応表

| @Model Entity | Transfer Struct | 変換方向 |
|---------------|----------------|----------|
| TrainingMenu | MenuTransfer | iPhone → Watch |
| Exercise | ExerciseTransfer | iPhone → Watch |
| WorkoutSession + ExerciseResult + SetResult | WorkoutResultTransfer | Watch → iPhone |

> 変換ロジックは ViewModel または Service 層で実装する。

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

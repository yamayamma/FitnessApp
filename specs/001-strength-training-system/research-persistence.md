# Research: SwiftData vs Core Data vs JSON Files for Fitness App Persistence

**Date**: 2026-02-11  
**Target**: iOS 17+ / watchOS 10+, Swift 5.9+  
**Context**: Multi-device strength training app with wger REST API, WatchConnectivity, HealthKit  

---

## Executive Summary & Recommendation

### ✅ 推奨: **Codable structs + JSON files (FileManager)** をプライマリストレージとし、SwiftData は使わない

**根拠**: このアプリのデータ特性を考えると、フル ORM は過剰。以下の 3 つの要因から、Codable structs + JSON files が最適。

| 要因 | 詳細 |
|------|------|
| **データの出所と信頼元** | Workout plans は wger が source of truth、健康データは HealthKit が source of truth。ローカルに永続化が必要なのは **workout session results のみ**（アプリ固有データ） |
| **WCSession 転送** | iPhone ↔ Watch 間のデータ転送は `[String: Any]` 辞書 or `Data`（JSON）。Codable structs ならそのまま `JSONEncoder` → `Data` → `WCSession.sendMessageData()` で送れる |
| **スキーマの単純さ** | 4-5 エンティティ、リレーションは 1:N が 2-3 本。SQLite/ORM の JOIN やインデックスが必要なほどの複雑さではない |

---

## 1. 選択肢の詳細比較

### 1.1 SwiftData (iOS 17.0+ / watchOS 10.0+)

**プラットフォームサポート**:
- `@Model`, `ModelContainer`, `ModelContext`, `ModelActor`, `@Query` — すべて watchOS 10.0+ で利用可能（Apple公式ドキュメントで確認済み）
- SwiftUI との統合は `.modelContainer(for:)` ビューモディファイヤで完結

**Codable 統合の実態**:
- `@Model` クラスは **自動では Codable に準拠しない**
- 手動で `CodingKeys`, `init(from:)`, `encode(to:)` を実装する必要がある（Hacking with Swift で確認）
- リレーションを含むモデルの場合、関連先も手動で Codable 実装が必要
- Apple 公式サンプル「Maintaining a local copy of server data」の推奨パターン:
  - **ネットワーク用**: 別の `Decodable` struct（GeoFeatureCollection）
  - **永続化用**: `@Model` class（Quake）
  - **変換**: convenience init で struct → @Model に変換

```swift
// Apple 推奨パターン: 2層構造
struct ServerResponse: Decodable { ... }  // ネットワーク用
@Model class LocalEntity { ... }          // 永続化用
// convenience init(from serverResponse:) で変換
```

**watchOS 10 での安定性**:
- SwiftData は WWDC 2023（iOS 17 / watchOS 10）で初登場。2026年2月時点で約2.5年
- watchOS 上の SwiftData は iOS より開発者の報告が少なく、エッジケースでのバグレポートが散見される
- watchOS ではメモリ制約が厳しく（Series 9 で 1GB RAM）、ModelContainer のオーバーヘッドが懸念
- `@Query` macro による自動フェッチは便利だが、watchOS の限られた画面では恩恵が薄い

**マイグレーション**:
- `SchemaMigrationPlan` で段階的マイグレーションをサポート
- 軽量マイグレーション（プロパティ追加・削除）は自動
- ただし iPhone と Watch で独立した DB なので、スキーマ変更時は両方のアプリを同時にアップデートする必要がある

**この用途での欠点**:
1. モデル定義の二重管理: REST API 用 Codable struct + @Model class
2. WCSession で送る際に @Model → JSON 変換が必要（手動 Codable 実装）
3. Watch で受信した JSON → @Model への変換も必要
4. 結局 JSON ↔ @Model の変換コードがボイラープレートになる
5. watchOS でのメモリ使用量が JSON files より大きい

### 1.2 Core Data (iOS 3.0+ / watchOS 2.0+)

**プラットフォームサポート**:
- watchOS 2.0+ から利用可能で、最も成熟したプラットフォームサポート
- NSPersistentContainer, NSManagedObjectContext 等すべての API が利用可能

**Codable 統合の実態**:
- NSManagedObject は Codable に **準拠しない**
- 手動での JSON ↔ NSManagedObject 変換が必要（SwiftData より面倒）
- NSManagedObject は特定の NSManagedObjectContext に紐づくため、スレッドセーフティの考慮が必要

**安定性**:
- 10年以上の実績、枯れた技術
- watchOS でも安定して動作する

**マイグレーション**:
- Lightweight Migration（自動）+ Staged Migration（手動）+ Manual Migration の3段階
- 最も柔軟で実績のあるマイグレーション機構

**この用途での欠点**:
1. `.xcdatamodeld` ファイルでのスキーマ定義が必要（Swift コードと二重管理）
2. NSManagedObject のサブクラス生成やボイラープレートが多い
3. Codable との相性が SwiftData より更に悪い
4. Swift Concurrency (`async/await`, `@Sendable`) との統合が不自然
5. **このアプリの規模に対して明らかに過剰**

### 1.3 Codable Structs + JSON Files (FileManager) ✅ 推奨

**アーキテクチャ**:

```
┌─────────────────────────────────────────────────┐
│                    Models Layer                   │
│  (Pure Swift structs, Codable + Identifiable)    │
│                                                   │
│  WorkoutPlan   Exercise   WorkoutSessionResult   │
│  ExerciseSet   SyncMetadata                      │
└───────────────┬───────────────────────────────────┘
                │ 同じモデルをすべてのレイヤーで共有
        ┌───────┴───────┐
        ▼               ▼
┌───────────────┐ ┌──────────────────┐
│  JSON API     │ │  WCSession       │
│  (wger REST)  │ │  (iPhone↔Watch)  │
│               │ │                  │
│ JSONDecoder   │ │ JSONEncoder →    │
│ → struct      │ │ sendMessageData  │
└───────┬───────┘ └────────┬─────────┘
        │                  │
        ▼                  ▼
┌──────────────────────────────────────┐
│        LocalStore (FileManager)       │
│                                       │
│  Documents/                           │
│  ├── plans/                           │
│  │   ├── plan_123.json                │
│  │   └── plan_456.json                │
│  ├── sessions/                        │
│  │   ├── session_abc.json             │
│  │   └── session_def.json             │
│  └── sync_metadata.json              │
└──────────────────────────────────────┘
```

**利点**:

| 観点 | 説明 |
|------|------|
| **モデル統一** | REST API、WCSession、ローカルストレージすべてで同じ Codable struct を使用。変換レイヤーが不要 |
| **WCSession 直接対応** | `JSONEncoder().encode(plan)` → `Data` → `session.sendMessageData(_:replyHandler:errorHandler:)` |
| **watchOS フレンドリー** | メモリオーバーヘッド最小。DB エンジン不要 |
| **テスト容易性** | Pure Swift structs は XCTest で直接テスト可能。Core Data/SwiftData のようなコンテナ設定不要 |
| **デバッグ容易性** | JSON ファイルは直接読める。DB ファイルはツールが必要 |
| **マイグレーション** | JSONDecoder のデフォルト値 + CodingKeys で十分対応可能 |
| **依存ゼロ** | Foundation のみ。サードパーティも Apple フレームワーク追加も不要 |

**クエリ対応**:

```swift
// 日付範囲クエリ
func sessions(from start: Date, to end: Date) -> [WorkoutSessionResult] {
    allSessions.filter { $0.completedAt >= start && $0.completedAt <= end }
}

// planId クエリ
func sessions(forPlanId planId: String) -> [WorkoutSessionResult] {
    allSessions.filter { $0.planId == planId }
}

// sessionId クエリ
func session(byId id: UUID) -> WorkoutSessionResult? {
    // 1ファイル = 1セッション なので直接ファイルアクセス
    load(from: "sessions/session_\(id.uuidString).json")
}
```

**スケール判断**: 
- ユーザーは 1 日 1-2 セッション × 365 日 = ~700 セッション/年
- 1 セッション JSON ≈ 2-5 KB
- 年間データ量 ≈ 1.5-3.5 MB
- インメモリ全件ロードしても余裕（watchOS でも）
- 仮に 10 年分でも 35 MB — FileManager で十分

**欠点と対策**:

| 欠点 | 対策 |
|------|------|
| インデックスなし | データ量が少ない（年数百件）のでフルスキャンでも高速 |
| ACID トランザクションなし | 一時ファイル書き込み → rename のアトミック操作で対応 |
| 同時アクセス制御なし | Actor で直列化（Swift Concurrency と相性良好） |
| リレーション管理なし | ID 参照 + 必要時にフラット構造で埋め込み |

---

## 2. 具体的なモデル設計案（JSON Files 方式）

```swift
// MARK: - すべてのレイヤーで共有する Codable モデル

struct WorkoutPlan: Codable, Identifiable {
    let id: String              // wger routine ID
    let name: String
    let exercises: [PlannedExercise]
    let lastSyncedAt: Date
}

struct PlannedExercise: Codable, Identifiable {
    let id: String              // wger exercise ID
    let name: String
    let targetSets: Int
    let targetReps: Int
    let targetWeight: Double?   // kg
    let restInterval: TimeInterval  // seconds
    let order: Int
}

struct WorkoutSessionResult: Codable, Identifiable {
    let id: UUID                // sessionId (HKWorkout metadata にも保存)
    let planId: String          // wger plan ID
    let planName: String
    let startedAt: Date
    let completedAt: Date
    let exercises: [ExerciseResult]
    let durationSeconds: TimeInterval
    let averageHeartRate: Double?
    let totalCalories: Double?
    let healthKitSynced: Bool   // HKWorkout 保存成功フラグ
}

struct ExerciseResult: Codable, Identifiable {
    let id: String              // exercise ID
    let name: String
    let sets: [SetResult]
}

struct SetResult: Codable, Identifiable {
    let id: UUID
    let setNumber: Int
    let targetReps: Int
    let actualReps: Int
    let targetWeight: Double?
    let actualWeight: Double?
    let completedAt: Date
}
```

**WCSession 転送時**:
```swift
// iPhone → Watch: プラン送信
let data = try JSONEncoder().encode(plan)
WCSession.default.sendMessageData(data, replyHandler: nil, errorHandler: nil)

// Watch → iPhone: セッション結果送信
let data = try JSONEncoder().encode(sessionResult)
WCSession.default.transferUserInfo(["sessionResult": data])
```

---

## 3. Key Questions への回答

### Q1: SwiftData は watchOS 10 で信頼できるか？

**回答: 動作するが、「枯れている」とは言えない**

- 公式ドキュメント上は watchOS 10.0+ で全 API が利用可能
- ただし SwiftData は 2023 年リリースの v1 世代。iOS 上でも初期はバグレポートが多かった
- watchOS は iOS より開発者数が少なく、バグの発見と修正が遅れる傾向
- watchOS のメモリ制約（1GB）下での ModelContainer のパフォーマンスは、大量データでなければ問題ないが、不要なオーバーヘッドではある
- **判定: 使えるが、このアプリの要件に対してリスクに見合うメリットが薄い**

### Q2: SwiftData モデルは Codable に簡単に準拠できるか？

**回答: 「簡単」ではない。手動実装が必要**

- `@Model` マクロは `Observable` + `PersistentModel` への準拠を自動生成するが、`Codable` は含まれない
- 各モデルに `CodingKeys`, `init(from:)`, `encode(to:)` を手動で書く必要がある
- リレーション（`@Relationship`）を含むモデルでは、関連先も再帰的に Codable 対応が必要
- Apple 公式の推奨パターン（「Maintaining a local copy of server data」）は、ネットワーク用 Decodable struct と永続化用 @Model class を **分離** するアプローチ
- **判定: WCSession 転送の要件を考えると、この「二重モデル管理」は労力に見合わない**

### Q3: データが wger と HealthKit にもあるなら、もっとシンプルな代替案はないか？

**回答: ある。JSON files が最適解**

データの所在を整理:

| データ | Source of Truth | ローカル保存の目的 |
|--------|----------------|-------------------|
| Workout Plans | wger REST API | オフラインキャッシュ + Watch 転送 |
| Health Metrics (HR, calories) | HealthKit (HKWorkout) | 保存不要（HealthKit にクエリ） |
| Session Results (sets/reps/weights) | **ローカルのみ** | 唯一の永続化先 |
| Session ↔ HKWorkout リンク | sessionId (UUID) | メタデータとして HKWorkout に埋め込み |

本当にローカルDB として管理が必要なのは:
1. **Plans のキャッシュ** — wger から取得した JSON をそのまま保存
2. **Session Results** — ワークアウト完了時に生成される JSON

どちらも「JSON をそのまま保存」がデータフローに最も自然。

---

## 4. 将来の拡張性

| シナリオ | JSON Files での対応 |
|----------|-------------------|
| wger への結果アップロード | Codable struct → JSONEncoder → REST POST（そのまま） |
| iCloud 同期 | NSUbiquitousKeyValueStore or iCloud Documents（JSON ファイルをそのまま同期） |
| データ量が 10,000 件超に | その時点で SwiftData への移行を検討（Codable struct → @Model の convenience init は低コスト） |
| 複雑なクエリ（集計・統計） | ファイル読み込み + Swift の Collection API で対応。不足ならローカルの SQLite (直接 or GRDB) に移行 |
| watchOS 11+ で SwiftData が安定したら | モデルが Pure Codable struct なので、@Model ラッパーを追加するだけ |

---

## 5. 実装ガイドライン

### LocalStore Actor パターン

```swift
actor LocalStore {
    private let fileManager = FileManager.default
    private let baseURL: URL
    
    init() {
        baseURL = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Atomic Write (crash-safe)
    private func atomicWrite<T: Encodable>(_ value: T, to path: String) throws {
        let data = try JSONEncoder().encode(value)
        let url = baseURL.appendingPathComponent(path)
        let dir = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        // Write to temp file, then rename (atomic on APFS)
        let tempURL = dir.appendingPathComponent(UUID().uuidString + ".tmp")
        try data.write(to: tempURL)
        _ = try fileManager.replaceItemAt(url, withItemAt: tempURL)
    }
    
    // MARK: - Read
    private func read<T: Decodable>(_ type: T.Type, from path: String) throws -> T? {
        let url = baseURL.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

### スキーマバージョニング（JSON 方式）

```swift
struct WorkoutSessionResult: Codable {
    let schemaVersion: Int  // デフォルト値で後方互換
    // ... fields ...
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        // v1 fields...
        // v2 で追加されたフィールドは decodeIfPresent + デフォルト値
    }
}
```

---

## 6. 最終判定マトリックス

| 評価軸 | SwiftData | Core Data | JSON Files ✅ |
|--------|-----------|-----------|--------------|
| watchOS 10 安定性 | ⚠️ 新しい (v1世代) | ✅ 枯れている | ✅ Foundation のみ |
| Codable 統合 | ⚠️ 手動実装必要 | ❌ 非対応 | ✅ ネイティブ |
| WCSession 転送 | ⚠️ 変換必要 | ⚠️ 変換必要 | ✅ 直接 encode/decode |
| REST API 連携 | ⚠️ 2層モデル | ⚠️ 2層モデル | ✅ 同一モデル |
| クエリ性能 (数百件) | ✅ インデックス | ✅ インデックス | ✅ フルスキャン十分 |
| クエリ性能 (数万件) | ✅ | ✅ | ⚠️ 移行検討 |
| メモリ使用量 | ⚠️ Container オーバーヘッド | ⚠️ Stack オーバーヘッド | ✅ 最小 |
| テスト容易性 | ⚠️ Container setup 必要 | ⚠️ Stack setup 必要 | ✅ Pure struct |
| マイグレーション | ✅ SchemaMigrationPlan | ✅ 3段階サポート | ✅ Codable default values |
| 学習コスト | 中 | 高 | 低 |
| 将来の SwiftData 移行 | — | 中 | **低**（struct → @Model wrapper） |
| **総合** | **次善** | **過剰** | **最適** |

---

## 7. 結論

**JSON Files + Codable structs を採用する。**

理由の要約:
1. データの信頼元が外部（wger + HealthKit）にあり、ローカルは session results のキャッシュ/保存のみ
2. WCSession 転送で JSON Data をそのまま使えるため、変換レイヤーが不要
3. データ量が年間数百件レベルで、DB インデックスの恩恵が薄い
4. watchOS のメモリ制約下で最軽量
5. Pure Codable struct により、テスト・デバッグ・将来の移行すべてが容易
6. 将来 SwiftData が十分に成熟した時点で、低コストで移行可能（struct に @Model を追加するだけ）

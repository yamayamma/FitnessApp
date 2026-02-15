# Data Model Checklist: 筋力トレーニング記録システム

**Purpose**: データモデルに関する要件の完全性・明確性・一貫性を検証する
**Created**: 2026-02-15
**Evaluated**: 2026-02-15 (Re-evaluated)
**Feature**: [spec.md](../spec.md) | [data-model.md](../data-model.md) | [contracts/watch-connectivity.md](../contracts/watch-connectivity.md)
**Result**: 23/25 PASS (92.0%) ← 前回 5/25 (20%)

## Requirement Completeness — Entity Attributes

- [x] CHK001 — 全 5 エンティティの属性が spec.md と data-model.md で一致しているか？ [Consistency, Spec §Key Entities vs data-model.md]
  > ✅ spec.md Key Entities が全 5 エンティティの属性を詳細化（id, sessionId, menuName, createdAt, sortOrder, defaultWeight/Reps 等を追加）し、data-model.md と一致。
- [x] CHK002 — spec.md の Key Entities に記載されていない属性が data-model.md で追加されているが、その根拠は要件として記載されているか？ [Traceability, data-model.md]
  > ✅ data-model.md に FR 番号による導出根拠を追記（sortOrder → FR-019、defaultWeight → FR-004 等）、spec.md Key Entities にも補助属性の目的を記載。
- [x] CHK003 — Exercise エンティティの `defaultWeight` と `defaultReps` の要件根拠は明記されているか？ [Traceability, Gap]
  > ✅ spec.md Key Entities に「defaultWeight/defaultReps は FR-004 のワンタップ記録を実現するため」と要件根拠を明記。
- [x] CHK004 — WorkoutSession の `id` と `sessionId` の 2 つの UUID を持つ設計の理由と使い分けが要件として明確か？ [Clarity, data-model.md §WorkoutSession]
  > ✅ data-model.md + spec.md Key Entities の両方に「id は SwiftData 内部用、sessionId はクロスシステム識別子（HealthKit/WC 連携用）」と dual UUID の設計理由を明文化。

## Requirement Clarity — Relationships

- [x] CHK005 — WorkoutSession → ExerciseResult → SetResult の親子関係の cascade delete 要件は定義されているか？ [Gap, data-model.md]
  > ✅ data-model.md に Cascade Delete Rules セクション追加。WorkoutSession → ExerciseResult `.cascade`、ExerciseResult → SetResult `.cascade` と定義。
- [x] CHK006 — TrainingMenu → Exercise の cascade delete 要件は定義されているか？ [Gap, data-model.md]
  > ✅ data-model.md に「TrainingMenu 削除 → Exercise .cascade（メニュー削除時に種目定義も削除）」と定義。
- [x] CHK007 — WorkoutSession と TrainingMenu の関係が `menuId` による間接参照なのか `@Relationship` による直接参照なのかが明確か？ [Clarity, data-model.md §ER Diagram]
  > ✅ ER 図で `menuId` 値参照を示し、Cascade Delete Rules に「menuId UUID 値による間接参照（@Relationship なし）」と明記。
- [x] CHK008 — ExerciseResult と Exercise の関係が間接参照のみである設計意図は記載されているか？ [Clarity, data-model.md]
  > ✅ data-model.md + spec.md Key Entities に「watchOS 側に TrainingMenu/Exercise エンティティが存在しないため、@Relationship ではなく値コピーで参照」と設計意図を明記。

## Requirement Consistency — sessionId Design

- [x] CHK009 — `sessionId` の一意性制約が SwiftData レベルで課されることが要件に明記されているか？ [Clarity, data-model.md §Validation rules]
  > ✅ Validation rules に「sessionId はレコード全体で一意（SwiftData @Attribute(.unique) で制約）」と実装方式まで明記。
- [x] CHK010 — `sessionId` が HealthKit metadata、ローカル DB、WatchConnectivity transfer の全箇所で一貫して使用されることが明確か？ [Consistency]
  > ✅ Spec FR-006/FR-026、Contract healthkit.md、Contract watch-connectivity.md、data-model.md — 全箇所で一貫した使用が確認可能。
- [x] CHK011 — `sessionId` の生成タイミングの要件は定義されているか？ [Gap]
  > ✅ spec.md FR-026 + data-model.md Validation rules に「ワークアウト開始時（HKWorkoutSession 生成と同時）に UUID() で生成」と明記。

## Requirement Completeness — JSON / Codable

- [x] CHK012 — JSON エクスポート形式のスキーマが FR-014 の受け入れ基準として十分か？ [Measurability, Spec §FR-014]
  > ✅ data-model.md §JSON Schema に具体的な JSON 出力例が定義されており、FR-014 の受け入れ基準として機能。
- [x] CHK013 — TransferModels を分離している設計意図が要件として文書化されているか？ [Clarity, Assumption]
  > ✅ data-model.md に「設計意図: @Model は Codable に自動準拠しないため Transfer struct が必要。@Relationship は循環参照を引き起こすためフラット化」と明文化。
- [x] CHK014 — JSON の日付フォーマット要件は定義されているか？ [Clarity, data-model.md §JSON Schema]
  > ✅ data-model.md ヘッダー + JSON Schema セクション + spec.md NFR-007 に「ISO 8601、JSONEncoder.dateEncodingStrategy = .iso8601」を明記。
- [x] CHK015 — TransferModels と `@Model` エンティティ間のマッピング要件は定義されているか？ [Gap]
  > ✅ data-model.md にマッピング対応表（@Model Entity ↔ Transfer Struct、変換方向）を追加、「変換ロジックは ViewModel/Service 層で実装」と記載。

## Scenario Coverage — Data Lifecycle

- [x] CHK016 — `cancelled` セッションのデータ保持期間・クリーンアップ方針の要件は定義されているか？ [Clarity, Spec §FR-016]
  > ✅ spec.md FR-016 に「無期限に保持（自動クリーンアップなし）。iPhone へは送信せず Watch ローカルのみ」と明確化。
- [x] CHK017 — SwiftData マイグレーションの要件は定義されているか？ [Gap]
  > ✅ Out of Scope に「SwiftData VersionedSchema によるマイグレーション管理」として明示的に除外。MVP での意識的判断。
- [x] CHK018 — iOS と watchOS で独立した SwiftData ストアを持つことが要件として明記されているか？ [Gap, Consistency]
  > ✅ data-model.md ヘッダーに「各デバイスが独立した SwiftData ストアを保持」を追加、spec.md NFR-008 にも同等の記載。
- [ ] CHK019 — watchOS 側の SwiftData ストレージ容量制限に関する要件は定義されているか？ [Gap, Edge Case]
  > ❌ 全ドキュメントに記載なし。

## Requirement Completeness — Future Extensibility

- [ ] CHK020 — 将来の MCP/wger 連携への拡張性が JSON スキーマレベルで考慮されているか？ [Coverage, Constitution §III]
  > ❌ 外部 ID マッピングフィールド（例: externalExerciseId）や拡張ポイントが JSON スキーマに未定義。wger/MCP 自体は Out of Scope だが拡張性設計は未反映。
- [x] CHK021 — JSON スキーマにバージョン番号フィールドが含まれていないが、後方互換性の要件は定義されているか？ [Gap]
  > ✅ Out of Scope に「JSON スキーマバージョニング」として明示的に除外。MVP での意識的判断。
- [x] CHK022 — 重量の単位系要件は定義されているか？ [Gap, Clarity]
  > ✅ spec.md NFR-006 に「kg 固定（MVP）」、Out of Scope に「lb/lbs 重量単位サポート」を追加。data-model.md ヘッダーにも「kg 固定（NFR-006）」を追加。

## Requirement Consistency — Cross-Document Alignment

- [x] CHK023 — data-model.md の WatchConnectivity Transfer Models と contracts/watch-connectivity.md の JSON Schema が完全に一致しているか？ [Consistency]
  > ✅ 両文書のフィールド定義が完全一致。
- [x] CHK024 — spec.md の WorkoutStatus 4 状態と data-model.md の enum 定義が一致しているか？ [Consistency]
  > ✅ Spec FR-001 と data-model.md WorkoutStatus enum の 4 状態が完全一致。
- [x] CHK025 — contracts/watch-connectivity.md の completed のみ送信制約が spec の要件と整合しているか？ [Consistency]
  > ✅ spec.md FR-016 に「cancelled は iPhone へ送信せず Watch ローカルのみ保持」、watch-connectivity.md に「cancelled データの可視性ポリシー」を追加し制約根拠が明示。

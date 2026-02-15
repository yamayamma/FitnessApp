# Data Model Checklist: 筋力トレーニング記録システム

**Purpose**: データモデルに関する要件の完全性・明確性・一貫性を検証する
**Created**: 2026-02-15
**Feature**: [spec.md](../spec.md) | [data-model.md](../data-model.md) | [contracts/watch-connectivity.md](../contracts/watch-connectivity.md)

## Requirement Completeness — Entity Attributes

- [ ] CHK001 — 全 5 エンティティ（WorkoutSession, ExerciseResult, SetResult, TrainingMenu, Exercise）の属性が spec.md と data-model.md で一致しているか？ [Consistency, Spec §Key Entities vs data-model.md]
- [ ] CHK002 — spec.md の Key Entities に記載されていない属性（`createdAt`, `updatedAt`, `sortOrder` 等）が data-model.md で追加されているが、その根拠は要件として記載されているか？ [Traceability, data-model.md]
- [ ] CHK003 — Exercise エンティティの `defaultWeight` と `defaultReps` が spec.md では言及されていないが data-model.md に追加されている。この追加の要件根拠は明記されているか？ [Traceability, Gap]
- [ ] CHK004 — WorkoutSession の `id`（SwiftData 主キー）と `sessionId`（HealthKit 紐付けキー）の 2 つの UUID を持つ設計の理由と使い分けが要件として明確か？ [Clarity, data-model.md §WorkoutSession]

## Requirement Clarity — Relationships

- [ ] CHK005 — WorkoutSession → ExerciseResult → SetResult の親子関係の cascade delete 要件は定義されているか？（セッション削除時に配下のデータも削除されるか） [Gap, data-model.md]
- [ ] CHK006 — TrainingMenu → Exercise の cascade delete 要件は定義されているか？（メニュー削除時の種目データの扱い） [Gap, data-model.md]
- [ ] CHK007 — WorkoutSession と TrainingMenu の関係が `menuId`（UUID 値）による間接参照なのか、SwiftData `@Relationship` による直接参照なのかが明確か？ [Clarity, data-model.md §ER Diagram]
- [ ] CHK008 — ExerciseResult と Exercise（種目定義）の関係が `exerciseId` による間接参照のみで、直接のリレーションシップが存在しないことの設計意図は要件として記載されているか？ [Clarity, data-model.md]

## Requirement Consistency — sessionId Design

- [ ] CHK009 — `sessionId` の一意性制約が SwiftData レベル（`@Attribute(.unique)`）で課されることが要件に明記されているか？ [Clarity, data-model.md §Validation rules]
- [ ] CHK010 — `sessionId` が HealthKit metadata、ローカル DB、WatchConnectivity transfer の 3 箇所で一貫して使用されることが要件として明確か？ [Consistency, Spec §FR-006, Contract §Custom Metadata Keys, Contract §WC §Workout Result]
- [ ] CHK011 — `sessionId` の生成タイミングの要件は定義されているか？（ワークアウト開始時？SwiftData モデル作成時？） [Gap]

## Requirement Completeness — JSON / Codable

- [ ] CHK012 — JSON エクスポート形式のスキーマが data-model.md で定義されているが、そのスキーマが spec.md の FR-014（「JSON 変換可能な構造」）の受け入れ基準として十分か？ [Measurability, Spec §FR-014]
- [ ] CHK013 — SwiftData `@Model` が Codable に自動準拠しないため TransferModels（`MenuTransfer`, `WorkoutResultTransfer` 等）を分離している設計意図が要件として文書化されているか？ [Clarity, Assumption, data-model.md §WatchConnectivity Transfer Models]
- [ ] CHK014 — JSON の日付フォーマット要件は定義されているか？（ISO 8601 と推測されるが明示されていない） [Clarity, data-model.md §JSON Schema]
- [ ] CHK015 — TransferModels（`MenuTransfer`, `WorkoutResultTransfer` 等）と `@Model` エンティティ間のマッピング要件は定義されているか？ [Gap, data-model.md §WatchConnectivity Transfer Models]

## Scenario Coverage — Data Lifecycle

- [ ] CHK016 — `cancelled` セッションのデータ保持期間・クリーンアップ方針の要件は定義されているか？（FR-016 は「保持する」のみで、無期限保持かどうかが不明） [Clarity, Spec §FR-016]
- [ ] CHK017 — SwiftData マイグレーション（スキーマバージョニング）の要件は定義されているか？（将来のフィールド追加時のデータ移行） [Gap]
- [ ] CHK018 — iOS と watchOS で独立した SwiftData ストアを持つことが要件として明記されているか？（research.md §R2 で調査済みだが、data-model.md のヘッダーは「コード共有」のみ記載、「データストア独立」が未記載） [Gap, Consistency, research.md §R2 vs data-model.md]
- [ ] CHK019 — watchOS 側の SwiftData ストレージ容量制限に関する要件は定義されているか？ [Gap, Edge Case]

## Requirement Completeness — Future Extensibility

- [ ] CHK020 — 将来の MCP サーバー入出力フォーマットと wger API 連携への拡張性が JSON スキーマレベルで考慮されているか？（exercise ID の外部マッピング用フィールド等） [Coverage, Constitution §III]
- [ ] CHK021 — data-model.md の JSON スキーマにバージョン番号フィールドが含まれていないが、将来の後方互換性の要件は定義されているか？ [Gap]
- [ ] CHK022 — 重量の単位系要件は定義されているか？（data-model.md は `kg` 固定だが、spec.md に単位記載なし。lb サポートやロケール切替は将来スコープか） [Gap, Clarity]

## Requirement Consistency — Cross-Document Alignment

- [ ] CHK023 — data-model.md の WatchConnectivity Transfer Models と contracts/watch-connectivity.md の JSON Schema が完全に一致しているか？ [Consistency, data-model.md vs contracts/watch-connectivity.md]
- [ ] CHK024 — spec.md の WorkoutStatus 4 状態（active/paused/completed/cancelled）と data-model.md の enum 定義が一致しているか？ [Consistency, Spec §FR-001 vs data-model.md §WorkoutStatus]
- [ ] CHK025 — contracts/watch-connectivity.md で `status` が `"completed"` のみ許可（transferUserInfo 送信時）だが、この制約が spec の要件と整合しているか？ [Consistency, Contract §WC §WorkoutResultTransfer vs Spec §FR-016]

## Notes

- Check items off as completed: `[x]`
- Add comments or findings inline
- Link to relevant resources or documentation
- Items are numbered sequentially for easy reference

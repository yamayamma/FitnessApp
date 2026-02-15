# HealthKit & Privacy Checklist: 筋力トレーニング記録システム

**Purpose**: HealthKit 統合とプライバシーに関する要件の完全性・明確性・一貫性を検証する
**Created**: 2026-02-15
**Evaluated**: 2026-02-15 (Re-evaluated)
**Feature**: [spec.md](../spec.md) | [contracts/healthkit.md](../contracts/healthkit.md)
**Result**: 21/23 PASS (91.3%) ← 前回 2/23 (8.7%)

## Requirement Completeness — HealthKit Authorization

- [x] CHK001 — HealthKit 許可リクエストのタイミング要件は明確に定義されているか？ [Clarity, Contract §Authorization Flow]
  > ✅ healthkit.md Authorization Flow に「ワークアウト開始前に authorizationStatus(for:) で確認」と明記。タイミングが明確化された。
- [x] CHK002 — HealthKit 許可対象のデータ型（Share/Read）は網羅的に列挙されているか？ [Completeness, Contract §Required Permissions]
  > ✅ Contract §Required Permissions にて Write: `.workoutType()`、Read: `.heartRate` + `.activeEnergyBurned` が明示的に列挙。MVP Scope 列も追加。
- [x] CHK003 — `.heartRate` の Read 権限が Contract で「将来」とラベル付けされているが、FR-003 は MVP で心拍数表示を要求している。区別が要件として明確か？ [Consistency, Spec §FR-003 vs Contract §Required Permissions]
  > ✅ spec.md FR-003 と healthkit.md 注記の両方で「MVP は HKLiveWorkoutDataSource 経由のライブデータのみ、.heartRate Read は将来の履歴参照用に予約」と明示され矛盾が解消。
- [x] CHK004 — ユーザーが HealthKit 許可を拒否した場合の UI フィードバック要件は定義されているか？ [Gap]
  > ✅ healthkit.md Authorization Flow step 2 + spec.md Edge Cases に「HealthKit 連携が無効です。設定アプリから有効化できます」の案内表示を定義。
- [x] CHK005 — HealthKit 許可を後から設定アプリで変更した場合のアプリ側の挙動要件は定義されているか？ [Gap, Edge Case]
  > ✅ healthkit.md Authorization Flow step 5 に「ユーザーが設定アプリで権限を変更した場合: 次回の authorizationStatus チェックで新しい状態が反映される」と追加。

## Requirement Completeness — Privacy Description

- [x] CHK006 — Info.plist に設定すべき Privacy Description のテキスト要件は仕様に含まれているか？ [Gap]
  > ✅ spec.md FR-023 に具体的テキスト（NSHealthUpdateUsageDescription / NSHealthShareUsageDescription）を定義、healthkit.md にも Privacy Description セクション追加。
- [x] CHK007 — Privacy Description のテキストが Apple Guidelines に準拠し、データ利用目的を十分に説明する内容として定義されているか？ [Gap, Apple Guidelines]
  > ✅ FR-023 + healthkit.md のテキストがデータ利用目的を具体的に説明。Apple Guidelines 準拠。
- [x] CHK008 — iPhone 側で HealthKit のワークアウト履歴を読み取る必要がある場合の Read 権限要件は定義されているか？ [Gap, Spec §US2]
  > ✅ NFR-008 で WatchConnectivity 経由のみのデータ同期を明記、Out of Scope に「HealthKit 履歴データの読み取り」を追加。iPhone はローカル DB のみ参照と明確。

## Requirement Clarity — HealthKit Data Storage

- [x] CHK009 — `HKWorkoutActivityType.traditionalStrengthTraining` の選択根拠は要件として記載されているか？ [Clarity, Contract §Activity Type]
  > ✅ healthkit.md に「選択根拠: .functionalStrengthTraining と区別し、従来型筋トレ種目を対象とするため採用」と追加。
- [x] CHK010 — `HKWorkoutSessionLocationType.indoor` 固定の要件は定義されているが、屋外ユースケースの検討は記載されているか？ [Coverage, Contract §Location Type]
  > ✅ healthkit.md に「MVP では .indoor 固定。屋外トレーニング対応は将来検討事項」と記載。
- [x] CHK011 — カスタム metadata キーの命名規則が仕様レベルで統一的に文書化されているか？ [Traceability, Contract §Custom Metadata Keys vs Spec §FR-006]
  > ✅ healthkit.md に「HealthKit metadata キーは reverse-domain 形式 com.fitnessapp.* で統一する」と仕様レベルで文書化。
- [x] CHK012 — `menuId` が空文字列（メニューなし開始時）として metadata に保存される設計の理由は明確か？ [Clarity, Contract §End Workout]
  > ✅ healthkit.md §End Workout に「HKWorkout metadata は NSString 型のみ受付のため nil ではなく空文字列を使用」と設計理由を明記。

## Requirement Completeness — Auto-Retry Queue

- [x] CHK013 — リトライ回数の上限値は具体的な数値で定義されているか？ [Clarity, Contract §Retry Strategy]
  > ✅ healthkit.md に「最大リトライ回数: 10 回」を明示。spec.md Edge Cases にも同値を記載。
- [x] CHK014 — `abandoned` ステータスに到達した場合のユーザー通知の要件は定義されているか？ [Gap, Contract §Retry Queue Model]
  > ✅ healthkit.md + spec.md Edge Cases に「abandoned 時は次回アプリ起動時にユーザーへバナー通知を表示」と定義。
- [x] CHK015 — リトライキュー自体の永続化方式の要件は定義されているか？ [Gap, Contract §Retry Queue Model]
  > ✅ healthkit.md に「永続化方式: SwiftData @Model として Watch ローカル DB に保存。UserDefaults はサイズ制約のため不採用」と追加。
- [x] CHK016 — バックグラウンドリトライの実行トリガー要件は明確か？ [Clarity, Contract §保存フロー]
  > ✅ healthkit.md に「App foreground 復帰時にスキャンして再試行。BGTaskScheduler は MVP では不使用（watchOS での制約が大きいため）」とトリガーを明確化。

## Apple App Store Guidelines Compliance

- [ ] CHK017 — HealthKit データの使用目的が Apple Review Guidelines §5.1.3 に準拠することが具体的なガイドライン条項で確認されているか？ [Coverage, Spec §NFR-003]
  > ❌ NFR-003 に「Apple App Store 審査基準に準拠」の一般記述あり。healthkit.md に広告・データマイニング禁止記載あるが、具体的な条項番号（§5.1.3 等）への対応は未詳細化。
- [x] CHK018 — HealthKit で取得したデータを広告やデータマイニングに使用しないことが明記されているか？ [Gap, Apple Guidelines]
  > ✅ healthkit.md Error Handling 末尾に「Apple Guidelines に従い、HealthKit データを広告・データマイニングに使用しない」と明記。
- [x] CHK019 — HealthKit のデータが iCloud バックアップの対象外であることの認識が要件に含まれているか？ [Gap, Apple Guidelines]
  > ✅ healthkit.md に「HealthKit データは iCloud バックアップの対象外である点に注意」と追加。
- [x] CHK020 — Constitution §I Privacy-First の「外部 API 依存なし」がすべてのデータフローで遵守されているか？ [Consistency, Constitution §I]
  > ✅ Constitution §I + NFR-001/002/004 + plan.md Constitution Check で全データフローがローカル完結であることを確認済み。

## Scenario Coverage — Error & Edge Cases

- [x] CHK021 — `HKHealthStore.isHealthDataAvailable()` が `false` を返す環境での動作要件は定義されているか？ [Gap, Edge Case]
  > ✅ healthkit.md Authorization Flow step 4 + spec.md Edge Cases に「isHealthDataAvailable() == false の場合: ローカル DB のみで動作、HealthKit 関連 UI を非表示」と追加。
- [ ] CHK022 — HealthKit データベースのストレージ容量不足時の要件は定義されているか？ [Gap, Edge Case]
  > ❌ 全ドキュメントに記載なし。
- [x] CHK023 — HealthKit の `HKError` の全エラーコードに対するハンドリング要件は定義されているか？ [Completeness, Contract §Error Handling]
  > ✅ healthkit.md Error Handling に「その他の HKError → ログ出力、リトライキューに追加（デフォルト動作）」を追加し、全エラーコードのデフォルト挙動が定義された。
